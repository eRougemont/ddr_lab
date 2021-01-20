<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.uhighlight.UnifiedHighlighter" %>
<%@ page import="org.apache.lucene.search.uhighlight.DefaultPassageFormatter" %>
<%@ page import="alix.lucene.search.FieldText.DocStats" %>
<%@include file="jsp/prelude.jsp"%>
<%!

%>
<%
long time = System.nanoTime(); 
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
IndexReader reader = alix.reader();

// Params for the page
final String fieldName = TEXT;
FieldText fstats = alix.fieldText(fieldName);
String q = tools.getString("q", null);
Sim sim = (Sim)tools.getEnum("sim", Sim.g);
DocSort sort = (DocSort)tools.getEnum("sort", DocSort.year);

%>
<!DOCTYPE html>
<html>
  <head>
   <jsp:include page="ddr_head.jsp" flush="true" />    
    <title>Chapitres de Rougemont</title>
  </head>
  <body>
    <header>
       <jsp:include page="tabs.jsp" flush="true" />
    </header>
  
    <main>
      <div>
        <table class="sortable" width="100%">
          <caption>
            <form id="qform"  class="search">
              <input type="submit" style="position: absolute; left: -9999px; width: 1px; height: 1px;"  tabindex="-1" />
              <label>Trouver un chapitre (selon un ou plusieurs mots)
              <br/><input id="q" name="q" value="<%=JspTools.escape(q)%>" width="100" autocomplete="off"/>
              </label>
              <br/><label>Algorithme d’ordre
              <br/><select name="sort" onchange="this.form.submit()">
                  <option/>
          <%= sort.options("score year year_inv") %>
                         </select>
              </label>
              <button type="submit">▶</button>
            </form>
          </caption>
          <thead>
            <tr>
              <td/>
              <th>Score</th>
              <th>Année</th>
              <th style="width: 15ex;">Livre</th>
              <th>Texte</th>
              <th>page</th>
              <th/>
              <th/>
             </tr>
           </thead>
           <tbody>
        
    
<%

final int len = 2000;
Query query = alix.query(fieldName, q);
if (query == null) {
  query = QUERY_CHAPTER;
}
IndexSearcher searcher = alix.searcher();
// searcher.setSimilarity(sim.similarity()); // test has been done, BM25 is the best
TopDocs topDocs;
if (sort != null && sort.sort() != null) topDocs = searcher.search(query, len, sort.sort());
else topDocs = searcher.search(query, len);
ScoreDoc[] hits = topDocs.scoreDocs;

// get stats by doc
DocStats docStats = null;
double scoreMax = 1;
double scoreMin = 0;
if (q != null) {
  String[] forms = alix.forms(q);
  docStats = fstats.docStats(forms, null, null);
  if (docStats != null) {
    scoreMax = docStats.scoreMax();
    scoreMin = docStats.scoreMin();
  }
}

final String href = "doc.jsp?q=" + q + "&amp;id="; // href link
boolean zero = false;
int no = 1;
for (ScoreDoc hit: hits) {
  final int docId = hit.doc;
  Document doc = reader.document(docId, CHAPTER_FIELDS);
  out.println("<tr class=\"snip\">");
  // hits[i].doc
  out.println("<td class=\"no left\">" + no + "</td>");
  if (docStats != null) {
    out.println("<td class=\"stats\">");
    out.println("<span class=\"bar\" style=\"width:" + dfdec1.format(100 * (docStats.score(docId) - scoreMin) / (scoreMax - scoreMin)) + "%\"> </span>");
    out.println(docStats.occs(docId));
    // out.println(" (" + docStats.score(docId) + ")");
    
    out.println("</td>");
  }
  else {
    out.println("<td/>");
  }
  
  out.print("<td class=\"num\">");
  String year = doc.get("year");
  if (year != null) out.print(year);
  out.println("</td> ");
  out.print("<td class=\"title\" title=\"" + doc.get("title") + "\">");
  out.print("<em class=\"title\">");
  out.print(doc.get("title"));
  out.println("</em>");
  out.println("</td>");

  out.print("<td class=\"scope\">");
  out.print("<a href=\"" + href + doc.get(Alix.ID) +"\">");
  out.print(doc.get("analytic"));
  out.print("</a>");
  out.println("</td>");
  out.print("<td>");
  String pages = doc.get("pages");
  if (pages != null) out.print(pages);
  out.println("</td>");
  out.println("<td/>");
  out.println("<td/><td class=\"no right\">" + no + "</td>");
  out.println("</tr>");
  no++;
}
%>
          </tbody>
        </table>
        <p> </p>
        <p> </p>
      </div>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
  </body>
</html>
