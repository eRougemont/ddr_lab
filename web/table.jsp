<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");


long time = System.nanoTime();
boolean first;
IndexReader reader = alix.reader();

// get default parameters from request
Pars pars = pars(pageContext);
FormEnum results = freqList(alix, pars);
%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="ddr_head.jsp" flush="true"/>
    <title><%=alix.props.get("label")%> [Alix]</title>
  </head>
  <body>
    <header>
      <jsp:include page="tabs.jsp"/>
    </header>
    <form  class="search">
      <a  class="icon" href="csv.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi"}) %>"><img src="static/icon_csv.svg" alt="Export intégral des données au format "></a>
      <a class="icon" href="tableur.jsp?<%= tools.url(new String[]{"q", "cat", "book", "left", "right", "distrib", "mi", "limit"}) %>"><img src="static/icon_excel.svg" alt="Export des données visibles pour Excel"></a>
      <input type="hidden" name="f" value="<%=JspTools.escape(pars.fieldName)%>"/>
      <input type="hidden" name="order" value="<%=pars.order%>"/>
      <label for="limit">Mots</label>
      <input name="limit" type="text" value="<%= pars.limit %>" class="num3" size="2"/>
      <label for="cat" title="Filtrer les mots par catégories grammaticales">Catégories</label>
      <select name="cat" onchange="this.form.submit()">
        <option/>
        <%=pars.cat.options()%>
      </select>
      <label for="distrib" title="Algorithme d’ordre des mots sélectionné">Score</label>
      <select name="distrib" onchange="this.form.submit()">
        <option/>
        <%= pars.distrib.options() %>
      </select>
           <%
           /*
           
             if (pars.book == null && pars.q == null) out.println (pars.ranking.options("occs bm25 tfidf"));
                  // else out.println (pars.ranking.options("occs bm25 tfidf g chi2"));
                  else out.println (pars.ranking.options());
            */
           %>
      <label for="book" title="Limiter la sélection à un seul livre">Livre</label>
      <%= selectBook(alix, pars.book) %>
      <br/>
      <label for="q" title="Cooccurrents fréquents autour d’un ou plusieurs mots">Chercher</label>
      <input name="q" onclick="this.select()" type="text" value="<%=tools.escape(pars.q)%>" size="40" />
      <label for="mi" title="Algorithme de score pour les liens">Dépendance</label>
      <select name="mi" onchange="this.form.submit()">
        <option/>
        <%= pars.mi.options() %>
      </select>
       <label for="left" title="Nombre de mots à capturer à gauche">Gauche</label>
      <input name="left" value="<%=pars.left%>" size="1" class="num3"/>
      Contextes
      <input name="right" value="<%=pars.right%>" size="1" class="num3"/>
      <label for="right" title="Nombre de mots à capturer à droite">Droit</label>
      <button type="submit">▶</button>
    </form>
    <main>
      <table class="sortable" width="100%">
        <thead>
          <tr>
            <td/>
            <th title="Forme graphique indexée">Graphie</th>
            <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre d’occurrences" class="num"> Occurrences</th>
            <th title="Nombre de chapitres" class="num"> Chapitres</th>
            <th title="Score selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <td/>
          <tr>
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
                  // .replace('_', ' ') ?
                  out.println("  <tr>");
                  out.println("    <td class=\"no left\">"  + no + "</td>");
                  out.println("    <td class=\"form\">");
                  out.print("      <a");
                  out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
                  out.print(">");
                  out.print(term);
                  out.print("</a>");
                  out.println("    </td>");
                  
                  out.print("    <td>");
                  out.print(Tag.label(results.tag()));
                  out.println("</td>");
                  
                  out.print("    <td class=\"num\">");
                  out.print(results.freq()) ;
                  if (results.filter != null || pars.q != null) out.print("<small> / " + results.occs() + "<small>");
                  // out.println("</a>");
                  out.println("    </td>");
                  out.print("    <td class=\"num\">");
                  out.print(results.hits()) ;
                  if (results.filter != null || pars.q != null) out.print("<small> / " + results.docs() + "<small>");
                  out.println("</td>");
                  // fréquence
                  // out.println(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
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
      <p> </p>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
