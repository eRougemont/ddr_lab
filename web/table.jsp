<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
pars.limit = tools.getInt("limit", 100);
if (pars.limit < 0) pars.limit = 1;
if (pars.limit > 1000) pars.limit = 1000;
FormEnum results = freqList(alix, pars);
results.sort(pars.order.sorter(), pars.limit);
%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="local/head.jsp" flush="true"/>
    <title><%=alix.props.get("label")%> [Alix]</title>
  </head>
  <body>
    <header id="top">
      <jsp:include page="local/tabs.jsp" flush="true"/>
      <form class="search" action="#">
        <a  class="icon" href="csv.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi"}) %>"><img src="static/icon_csv.svg" alt="Export intégral des données au format "></a>
        <a class="icon" href="tableur.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi", "limit"}) %>"><img src="static/icon_excel.svg" alt="Export des données visibles pour Excel"></a>
        <%= selectCorpus(alix.name) %>,
        <%= selectBook(alix, pars.book) %>
        <button type="submit">▶</button>
        
        <br/>

        <input name="limit" type="text" value="<%= pars.limit %>" class="num4" size="2"/>
        <select name="f" onchange="this.form.submit()">
          <option/>
          <%=pars.field.options()%>
        </select>
        <label for="cat" title="Filtrer les mots par catégories grammaticales">filtre</label>
        <select name="cat" onchange="this.form.submit()">
          <option/>
          <%=pars.cat.options()%>
        </select>
        <a class="help button" href="#cat">?</a>
             <%
             /*
        <label for="distrib" title="Algorithme d’ordre des mots sélectionné">Score</label>
        <select name="distrib" onchange="this.form.submit()">
          <option/>
          pars.distrib.options()
        </select>
             
               if (pars.book == null && pars.q == null) out.println (pars.ranking.options("occs bm25 tfidf"));
                    // else out.println (pars.ranking.options("occs bm25 tfidf g chi2"));
                    else out.println (pars.ranking.options());
                    <label for="mi" title="Algorithme de score pour les liens">Dépendance</label>
                    <select name="mi" onchange="this.form.submit()">
                      <option/>
                      pars.mi.options()
                    </select>

                    */
             %>
        <label for="order" title="Sélectionner et ordonner le tableau selon une colonne">rangés par</label>
        <select name="order" onchange="this.form.submit()">
          <option/>
          <%
          if (pars.book != null || pars.q != null) out.println(pars.order.options("score freq hits occs docs"));
          else out.println(pars.order.options("score freq hits"));
          %>
        </select>
        <br/>
        <label for="q" title="Mots fréquents autour d’un ou plusieurs mots">Co-occurrents de</label>
        <input name="q" class="q" onclick="this.select()" type="text" value="<%=tools.escape(pars.q)%>" size="40" />
        <input name="left" value="<%=pars.left%>" size="1" class="num3"/>
        <label for="left" title="Nombre de mots à capturer à gauche">à gauche</label>
        <input name="right" value="<%=pars.right%>" size="1" class="num3"/>
        <label for="right" title="Nombre de mots à capturer à droite">à droite</label>
      </form>
    </header>
    <main>
      <table class="sortable" width="100%">
        <caption>
        Lecture :
        <%
        String title = null;
        if (pars.book != null && !pars.book.trim().equals("")) {
          int docId = alix.getDocId(pars.book);
          Document doc = reader.document(docId, BOOK_FIELDS);
          title = doc.get("title");
        }
        boolean multiw = false;
        if (pars.q != null && pars.q.trim().contains(" ")) multiw=true;

        
        if (results.limit() < 1) {
          if (pars.q != null && title != null) out.println("<b>"+pars.q+"</b> — introuvable dans <em>"+title+"</em>");
          else if (pars.q != null) out.println("<b>"+pars.q+"</b> — introuvable dans le copus");
          else out.println("Cas non prévu par le développeur. Bug ?");
        }
        else {
          int rank = 1;
          out.println("au rang "+(rank + 1)+" la graphie <strong>"+results.formByRank(rank)+"</strong> ");
          if (pars.book != null && !pars.book.trim().equals("")) out.println("<br/>— dans <em>" +title+"</em>");
          if (pars.q != null) out.println("<br/>— au voisinage de <em>" + pars.q + "</em> ("+pars.left+ " mots à gauche, " + pars.right + " mots à droite)");
          out.println("<br/>— " + frdec.format(results.freqByRank(rank)) + " occurrences");
          if (pars.q != null || pars.book != null) out.println(" (sur " + frdec.format(results.occsByRank(rank)) + " dans la totalité du corpus)");
          out.println("<br/>— " + frdec.format(results.hitsByRank(rank)) +" textes trouvés");
          if (pars.q != null || pars.book != null) out.println(" (sur les " + frdec.format(results.docsByRank(rank)) +" du corpus qui contiennent ce mot)");
        }
        %>
        </caption>
        <thead>
          <tr>
            <th/>
            <th title="Forme graphique indexée" class="form">Graphie</th>
            <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre d’occurrences trouvées" class="num"> Occurrences</th>
            <% if (pars.book != null || pars.q != null) out.println("<th title=\"Sur total des occurences de cette graphie\" class=\"all\">/mots</td>"); %>
            <th title="Nombre de chapitres-articles contenant la grahie" class="num"> Résultats</th>
            <% if (pars.book != null || pars.q != null) out.println("<th title=\"Nombre total de textes contenant le mot\" class=\"all\">/textes</th>"); %>
            <th title="Score de pertinence selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <th/>
          </tr>
        </thead>
        <tbody>
          <%
            // todo, book selector
          String urlForm = "conc.jsp?" + tools.url(new String[]{"book"}) + "&amp;q=";
          // String urlOccs = "kwic.jsp?" + tools.url(new String[]{"left", "right", "ranking"}) + "&amp;q=";
          int no = 0;
          results.reset();
          while (results.hasNext()) {
            results.next();
            no++;
            String term = results.form();
            int flag = results.tag();
            String css = "word";
            if (flag == Tag.SUB.flag) css = "SUB";
            else if (flag == Tag.ADJ.flag) css = "ADJ";
            else if (flag == Tag.VERB.flag) css = "VERB";
            else if (Tag.NAME.sameParent(flag)) css = "NAME";
            // .replace('_', ' ') ?
            out.println("  <tr>");
            out.println("    <td class=\"no left\">"  + no + "</td>");
            out.println("    <td class=\"form\">");
            out.print("      <a");
            out.print(" class=\"" + css + "\"");
            out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
            out.print(">");
            out.print(term);
            out.print("</a>");
            out.println("    </td>");
            
            out.print("    <td class=\"cat lo\">");
            out.print(Tag.label(flag));
            out.println("</td>");
            
            out.print("    <td class=\"num\">");
            out.print(frdec.format(results.freq()));
            out.println("</td>");

            if (pars.book != null || pars.q != null) {
              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(results.occs()));
              out.println("</td>");
            }

            out.print("    <td class=\"num\">");
            if (results.hits() > 0) out.print(frdec.format(results.hits()));
            out.println("</td>");
            
            if (pars.book != null || pars.q != null) {
              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(results.docs()));
              out.println("</td>");
            }
            out.print("    <td class=\"num\">");
            out.print(formatScore(results.score()));
            out.println("</td>");
            
            out.println("    <td></td>");
            out.println("    <td class=\"no right\">" + no + "</td>");
            out.println("  </tr>");
          }
          %>
        </tbody>
      </table>
      <article class="text">
        <section id="cat">
          <h1>Catégories grammaticales</h1>
          <p>Les mots indexés sont catégorisés selon une <b>nature</b> (pas selon une <strike>fonction</strike> dans la phrase),
          c’est-à-dire ce que le mot peut <em>être</em> dans un dictionnaire,
           indépendamment de ses contextes d’emploi.
          Ainsi par exemple, un mot comme <em>aimé</em> peut être employé comme verbe « <em>cette personne, je l’ai trop aimée</em> », comme adjectif « <em>la personne aimée</em> »,
          ou comme substantif « <em>mon aimée</em> » ; le logiciel ne fera pas la différence et indiquera seulement <em>participe passé</em>.
          L’histoire du participe passé en français montre en effet une grande fluidité entre les catégories, notamment par l’effet du passif
          « <em>cette mode a été aimée, puis oubiée</em> ».
          Un jeu de catégories résulte nécessairement d’une théorie linguistique, consciente ou inconsciente, 
          mais la pondération a ici surtout été conduite par l’ordre des fréquences, et la commodité dans un moteur de recherche.
          Il s’agit de donner des poignées sémantiques utiles sur les textes, par exemple pour comparer ceux qui 
          comporteraient plus ou moins de négation, ou d’interrogation.
          Les étiquettes connues des dictionnaires seront présentées selon le format suivant
        </p>
        <dt>Numéro. <strong>Intitulé</strong> <small>(code)</small></dt>
        <dd><em>Glose</em></dd>
        <%
        StringBuilder html = new StringBuilder();
        html.append("<dl>\n");
        for (int i = 0; i < 256; i++) {
          Tag tag = Tag.tag(i);
          if (tag == null) continue;
          String indent = "  ";
          if ((i % 16) != 0) indent = "    ";
          if ((i % 16) == 0 && i != 0) html.append("  </dl></dd>\n");
          html.append(indent+"<dt>"+String.format("%02X", tag.flag())+". <strong>"+tag.label()+"</strong> <small>("+tag.name()+")</small></dt>\n");
          html.append(indent+"<dd><em>"+tag.desc()+"</em></dd>\n");
          if ((i % 16) == 0) html.append("  <dd><dl>\n");
        }
        html.append("  </dl></dd>\n");
        html.append("</dl>\n");
        out.println(html);
        %>
        </section>
      
      </article>
      <p> </p>
    </main>
    <a id="totop" href="#top">△</a>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
