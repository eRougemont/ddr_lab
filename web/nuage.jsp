<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
final int lim = 200;
final int max = 500;
pars.limit = tools.getInt("limit", lim);
if (pars.limit < 1) pars.limit = lim;
if (pars.limit > max) pars.limit = max;
FormEnum results = freqList(alix, pars);
results.sort(pars.order.sorter(), pars.limit);

%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="local/head.jsp" flush="true"/>
    <title>Nuage <%= alix.props.get("label") %> [Alix]</title>
  </head>
  <body>
    <header>
      <jsp:include page="local/tabs.jsp"/>
      <form  class="search">
        <%= selectCorpus(alix.name) %>,
        <label for="book" title="Limiter la sélection à un seul livre">Livre</label>
        <%= selectBook(alix, pars.book) %>
        <button type="submit">▶</button>

        <br/>
      
        <input name="limit" type="text" value="<%= pars.limit %>" class="num3" size="2"/>
        <select name="f" onchange="this.form.submit()">
          <option/>
          <%=pars.field.options()%>
        </select>
        <label for="cat" title="Filtrer les mots par catégories grammaticales">Catégories</label>
        <select name="cat" onchange="this.form.submit()">
          <option/>
          <%=pars.cat.options()%>
        </select>
        <label for="order" title="Sélectionner et ordonner le tableau selon une colonne">Trié par</label>
        <select name="order" onchange="this.form.submit()">
          <option/>
          <% out.println(pars.order.options("score freq hits")); %>
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
      <div class="wcframe">
        <div id="wordcloud2"></div>
      </div>
      <script>
var words = [
<%
// {"word" : "beau", "weight" : 176, "attributes" : {"class" : "ADJ"}},
boolean first = true;
results.reset();
while (results.hasNext()) {
  results.next();
  if (first) first = false;
  else out.print(",\n");
  double score = results.score();
  if (pars.distrib.equals(Distrib.g)) score = Math.sqrt(score);
  // else if (distrib.equals(Distrib.tfidf)) score = Math.sqrt(score) ;
  else if (pars.distrib.equals(Distrib.bm25)  || pars.distrib.equals(Distrib.tfidf) ) score = score * score;
  out.print("  {'word': '" + results.form().replace("'", "\\'") + "', 'weight': "+score+", 'attributes': {'class': '" + Tag.parent(results.tag()).toString() +"'}}");
}
%>
];
      </script>
    </main>
    <script src="<%= hrefHome %>vendor/wordcloud2.js">//</script>
    <script src="<%= hrefHome %>static/cloud.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
