<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");


long time = System.nanoTime();
IndexReader reader = alix.reader();

// get default parameters from request
Pars pars = pars(pageContext);
Corpus corpus = null;
BitSet filter = null; // if a corpus is selected, filter results with a bitset
if (pars.book != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{pars.book});

FieldText fieldText = alix.fieldText(pars.fieldName);

boolean reverse = false;
if (pars.order == Order.last) reverse = true;

FormEnum results = null;
if (pars.q != null) {
  FieldRail rail = alix.fieldRail(pars.fieldName); // get the tool for cooccurrences
  // parameters and population of dic.freqs and dic.hits with the rail co-occurrents
  results = new FormEnum(fieldText); // build a wrapper to have results
  results.search = alix.forms(pars.q); // parse query as terms
  int pivotsOccs = 0;
  for (String form: results.search) {
    pivotsOccs += fieldText.occs(form);
  }
  results.left = pars.left; // left context
  results.right = pars.right; // right context
  results.filter = filter; // limit to some documents
  results.tags = pars.cat.tags(); // limit word list by tags
  long found = rail.coocs(results);
  if (found > 0) {
    // parameters for sorting
    results.limit = pars.limit;
    results.specif = pars.ranking.specif();
    results.reverse = reverse;
    rail.score(results, pivotsOccs);
  }
  else {
    // if nothing found, what should be done ?
  }
}
else {
  // final int limit, Specif specif, final BitSet filter, final TagFilter tags, final boolean reverse
  // dic = fieldText.iterator(pars.limit, pars.ranking.specif(), filter, pars.cat.tags(), reverse);
  results = fieldText.iterator(pars.limit, pars.ranking.specif(), filter, pars.cat.tags(), reverse);
}
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
      <input type="hidden" name="f" value="<%=JspTools.escape(pars.fieldName)%>"/>
      <input type="hidden" name="order" value="<%=pars.order%>"/>
      <label title="Filtrer les mots par catégories grammaticales" for="cat">Catégories</label>
      <select name="cat" onchange="this.form.submit()">
        <option/>
        <%=pars.cat.options()%>
      </select>
      <label title="Algorithme d’ordre des mots sélectionné" for="ranking">Score</label>
      <select name="ranking" onchange="this.form.submit()">
           <option/>
           <%
             if (pars.book == null && pars.q == null) out.println (pars.ranking.options("occs bm25 tfidf"));
                  // else out.println (pars.ranking.options("occs bm25 tfidf g chi2"));
                  else out.println (pars.ranking.options());
           %>
      </select>
      <label for="book" title="Limiter la sélection à un seul livre">Livre</label>
      <%= selectBook(alix, pars) %>
       <br/>
       <label for="q" title="Cooccurrents fréquents autour d’un ou plusieurs mots">Chercher</label>
       <input name="q" onclick="this.select()" type="text" value="<%=tools.escape(pars.q)%>" size="40" />
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
                String urlForm = "kwic.jsp?" + tools.url(new String[]{"ranking", "book"}) + "&amp;q=";
                // String urlOccs = "kwic.jsp?" + tools.url(new String[]{"left", "right", "ranking"}) + "&amp;q=";
                int no = 0;
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
                  // out.print("      <a href=\"" + urlOccs + JspTools.escUrl(term) + "\">");
                  out.print(results.freq()) ;
                  // out.println("</a>");
                  out.println("    </td>");
                  out.print("    <td class=\"num\">");
                  out.print(results.hits()) ;
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
