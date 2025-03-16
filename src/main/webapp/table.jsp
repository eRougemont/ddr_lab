<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="inc/options.jsp" %>

<%
final String q = tools.getString(Q, null);
final int limit = tools.getInt("limit", new int[]{0, 1000}, 100);
final int left = tools.getInt("left", new int[]{0, 100}, 5);
final int right = tools.getInt("right", new int[]{0, 100}, 5);


OptionCat cat =  (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP);

final String book = null;

final Order order = FormEnum.Order.FREQ;
// Where to search in
String fname = TEXT_CLOUD;
/*
if (q != null) {
    fname = TEXT_ORTH;
}
*/
final FieldText ftext = alix.fieldText(fname);
BitSet docFilter = null;
TagFilter tagFilter = cat.tags(); // .set(Tag.ADJ).set(Tag.UNKNOWN).setGroup(Tag.NAME).set(Tag.NULL).set(Tag.NOSTOP);

FormEnum formEnum = null;
if (q != null) {
    do {
        if ( (left + right) == 0) break;
        //context width where to capture co-occurency
        // let’s try to find pivots words for coocs
        String[] forms = alix.tokenize(q.replace("\"", ""), fname);
        if (forms == null || forms.length < 1) {
            out.println(String.format("<p>Aucun mot dans la requête : “%s”</p>", q));
            break;
        }
        int[] pivots = ftext.formIds(forms, docFilter);
        if (pivots == null) {
            if (forms.length == 1) {
                out.println(String.format("<p>Mot absent du corpus : “%s”</p>", q));
            } else {
                out.println(String.format("<p>Mots absents du corpus : “%s”</p>", q));
            }
            break;
        }
        int pivotLen = pivots.length;
        final FieldRail frail = alix.fieldRail(fname);
    
        formEnum = frail.coocs(
                pivots,
                left, 
                right, 
                docFilter
            )
            .filter(tagFilter)
            // .score(MI.G, pivots) // Jaccard or Dice are also quite good
            .score(MI.G, pivots)
            .sort(FormIterator.Order.FREQ, limit)
        ;
    } while (false);
    
}
// list all words
else {
    formEnum = ftext.formEnum(docFilter, tagFilter, Distrib.BM25);
    formEnum.sort(order, limit);
}

%>
<!DOCTYPE html>
<html>
<head>
    <%@ include file="local/head.jsp"%>
    <title>Table, liste de fréquence</title>
</head>
<body>
    <header id="header">
        <jsp:include page="local/tabs.jsp" flush="true" />
    </header>
    <div class="row">
        <aside id="aside" class="form" style="width: 25rem;">
        
        </aside>
        <main>
            <form class="search" action="#">
                <!--  
        <a  class="icon" href="csv.jsp?<%= tools.queryString(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi"}) %>"><img src="static/icon_csv.svg" alt="Export intégral des données au format "></a>
        <a class="icon" href="tableur.jsp?<%= tools.queryString(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi", "limit"}) %>"><img src="static/icon_excel.svg" alt="Export des données visibles pour Excel"></a>
        Select book ?
        -->

                <br /> 
                <!-- Field ?
        <select name="f" onchange="this.form.submit()">
          <option/>
        </select>
        -->
                <label for="cat"
                    title="Filtrer les mots par catégories grammaticales">Filtre</label>
                <select name="cat" onchange="this.form.submit()">
                    <option />
                    <%=cat.options()%>
                </select> <a class="help button" href="#cat">?</a>
                <label for="limit">nombre</label>
                <input onchange="this.form.submit()" name="limit" value="<%=limit%>" type="range" min="50" max="1000" step="50"/>
                <br/>
                <%
                /*
                <label for="distrib" title="Algorithme d’ordre des mots sélectionné">Score</label>
                <select name="distrib" onchange="this.form.submit()">
                <option/>
                </select>

                  if (book == null && q == null) out.println (ranking.options("occs bm25 tfidf"));
                       // else out.println (ranking.options("occs bm25 tfidf g chi2"));
                       else out.println (ranking.options());
                       <label for="mi" title="Algorithme de score pour les liens">Dépendance</label>
                       <select name="mi" onchange="this.form.submit()">
 <option/>
                         mi.options()
                       </select>

                       */
                %>
                <label for="q" title="Mots fréquents autour d’un ou plusieurs mots">Co-occurrents</label>
                <input onchange="this.form.submit()" title="Nombre de co-occurents à gauche" name="left" value="<%=left%>" type="number" min="0" max="100" step="1"/>
                <label for="left" title="Nombre de mots à capturer à gauche">à gauche</label>
                <input onchange="this.form.submit()" title="Nombre de co-occurents à droite" name="right" value="<%=right%>" type="number" min="0" max="100" step="1"/>
                <label for="right" title="Nombre de mots à capturer à droite">à droite</label>
                <div class="searchfield">
                    <button type="submit" class="icon magnify"><svg><use href="static/icons.svg#magnify" /></svg></button>
                    <input type="text" value="<%=tools.escape(q)%>" class="q" name="q" id="sugg" src="data/suggest?field=text_cloud&amp;q="/>
                    <a href="?" class="icon cross"><svg><use href="static/icons.svg#cross" /></svg></a>
                </div>
                
                
            </form>
                <table class="sortable">
                    <caption>
                        <%
                    /*       
                        Lecture :
                    if (formEnum.limit() < 1) {
                      if (q != null && title != null) out.println("<b>"+q+"</b> — introuvable dans <em>"+title+"</em>");
                      else if (q != null) out.println("<b>"+q+"</b> — introuvable dans le copus");
                      else out.println("Cas non prévu par le développeur. Bug ?");
                    }
                    else {
                      int rank = 1;
                      out.println("au rang "+(rank + 1)+" la graphie <strong>"+formEnum.formByRank(rank)+"</strong> ");
                      // if (book != null && !book.trim().equals("")) out.println("<br/>— dans <em>" +title+"</em>");
                      if (q != null) out.println("<br/>— au voisinage de <em>" + q + "</em> ("+left+ " mots à gauche, " + right + " mots à droite)");
                      out.println("<br/>— " + formatScore(formEnum.freqByRank(rank)) + " occurrences");
                      if (q != null || book != null) out.println(" (sur " + formatScore(formEnum.occsByRank(rank)) + " dans la totalité du corpus)");
                      out.println("<br/>— " + formatScore(formEnum.hitsByRank(rank)) +" textes trouvés");
                      if (q != null || book != null) out.println(" (sur les " + formatScore(formEnum.docsByRank(rank)) +" du corpus qui contiennent ce mot)");
                    }
                    */
                    %>
                    </caption>
                    <thead>
                        <tr>
                            <th />
                            <th title="Forme graphique indexée"
                                class="form">Graphie</th>
                            <th title="Catégorie grammaticale">Catégorie</th>
                            <th title="Nombre d’occurrences trouvées"
                                class="num"> Occurrences</th>
                            <%
                            if (book != null || q != null)
                                out.println("<th title=\"Sur total des occurences de cette graphie\" class=\"all\">/mots</td>");
                            %>
                            <th
                                title="Nombre de chapitres-articles contenant la grahie"
                                class="num"> Textes</th>
                            <%
                            if (book != null || q != null)
                                out.println("<th title=\"Nombre total de textes contenant le mot\" class=\"all\">/textes</th>");
                            %>
                            <th
                                title="Score de pertinence selon l’algorithme"
                                class="num"> Score</th>
                        </tr>
                    </thead>
                    <tbody>
<%
// todo, book selector
String urlForm = "?" + tools.queryString(new String[]{"book"}) + "&amp;q=";
if (formEnum != null) {
    // String urlOccs = "kwic.jsp?" + tools.url(new String[]{"left", "right", "ranking"}) + "&amp;q=";
    int no = 0;
    formEnum.reset();
    while (formEnum.hasNext()) {
        formEnum.next();
        if (formEnum.freq() == 0) continue;
        no++;
        final int formId = formEnum.formId();
        String term = formEnum.form();
        final int flag = ftext.tag(formId);
        String css = "word";
        if (flag == Tag.SUB.no())
            css = "SUB";
        else if (flag == Tag.ADJ.no())
            css = "ADJ";
        else if (flag == Tag.VERB.no())
            css = "VERB";
        else if (Tag.NAME.sameParent(flag))
            css = "NAME";
        // .replace('_', ' ') ?
        out.println("  <tr>");
        out.println("    <td class=\"no left\">" + no + "</td>");
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
    
        if (book != null || q != null) {
            out.print("    <td class=\"num\">");
            out.print(formatScore(formEnum.freq()) + "/ ");
            out.println("</td>");
        }
    
        out.print("    <td class=\"all\">");
        out.print(formatScore(formEnum.occs()));
        out.println("</td>");
    
        if (book != null || q != null) {
            out.print("    <td class=\"num\">");
            if (formEnum.hits() > 0)
        out.print(formatScore(formEnum.hits()));
            out.println("</td>");
        }
    
        out.print("<td class=\"all\">");
        out.print(formatScore(formEnum.docs()));
        out.println("</td>");
        out.print("    <td class=\"num\">");
        out.print(formatScore(formEnum.score()));
        out.println("</td>");
    
    }
}
%>
                    </tbody>
                </table>
                <article class="text">
                    <section id="cat">
<h1>Catégories grammaticales</h1>
<p>
    Les mots indexés sont catégorisés selon une
    <b>nature</b> (pas selon une <strike>fonction</strike>
    dans la phrase), c’est-à-dire ce que le mot
    peut <em>être</em> dans un dictionnaire,
    indépendamment de ses contextes d’emploi.
    Ainsi par exemple, un mot comme <em>aimé</em>
    peut être employé comme verbe « <em>cette
        personne, je l’ai trop aimée</em> », comme
    adjectif « <em>la personne aimée</em> », ou
    comme substantif « <em>mon aimée</em> » ; le
    logiciel ne fera pas la différence et
    indiquera seulement <em>participe passé</em>.
    L’histoire du participe passé en français
    montre en effet une grande fluidité entre
    les catégories, notamment par l’effet du
    passif « <em>cette mode a été aimée,
        puis oubliée</em> ». Un jeu de catégories
    résulte nécessairement d’une théorie
    linguistique, consciente ou inconsciente,
    mais la pondération a ici surtout été
    conduite par l’ordre des fréquences, et la
    commodité dans un moteur de recherche. Il
    s’agit de donner des poignées sémantiques
    utiles sur les textes, par exemple pour
    comparer ceux qui comporteraient plus ou
    moins de négation, ou d’interrogation. Les
    étiquettes connues des dictionnaires seront
    présentées selon le format suivant
</p>
<dt>
    Numéro. <strong>Intitulé</strong> <small>(code)</small>
</dt>
<dd>
    <em>Glose</em>
</dd>
<%
StringBuilder html = new StringBuilder();
html.append("<dl>\n");
for (int i = 0; i < 256; i++) {
    Tag tag = Tag.tag(i);
    if (tag == null)
        continue;
    String indent = "  ";
    if ((i % 16) != 0)
        indent = "    ";
    if ((i % 16) == 0 && i != 0)
        html.append("  </dl></dd>\n");
    html.append(indent + "<dt>" + String.format("%02X", tag.no()) + ". <strong>" + tag.label() + "</strong> <small>("
    + tag.name() + ")</small></dt>\n");
    html.append(indent + "<dd><em>" + tag.desc() + "</em></dd>\n");
    if ((i % 16) == 0)
        html.append("  <dd><dl>\n");
}
html.append("  </dl></dd>\n");
html.append("</dl>\n");
out.println(html);
%>
                    </section>

                </article>
                <p> </p>
            </main>
        </div>
        <%@include file="local/footer.jsp" %>
        <script>
suggest(document.getElementById("sugg"));
        </script>
        <script src="https://oeuvres.github.io/teinte_theme/teinte.sortable.js">//</script>
    </body>
</html>
