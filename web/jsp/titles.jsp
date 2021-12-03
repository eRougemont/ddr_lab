<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.lucene.analysis.MetaAnalyzer" %>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="alix.lucene.search.Marker" %>
<%@include file="prelude.jsp"%>
<%!
final static Analyzer ANAMET = new MetaAnalyzer();
final static HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Alix.ID, Alix.BOOKID, "bibl"}));

%>
<%
String q = tools.getString("q", null);
int limit = tools.getInt("limit", 100);


SortField sf1 = new SortField("year", SortField.Type.INT);
SortField sf2 = new SortField(Alix.ID, SortField.Type.STRING);
Sort sort = new Sort(sf1, sf2);

Query query = null;
if (query == null) query = QUERY_CHAPTER;
if (q != null) {
  String lowbibl = q.toLowerCase();
  query = Alix.query("bibl", lowbibl, ANAMET, Occur.MUST);
  query = new BooleanQuery.Builder()
     .add(QUERY_CHAPTER, Occur.FILTER)
     .add(query, Occur.MUST)
   .build();
}


Marker marker = null;
if (q != null) marker = new Marker(ANAMET, q);

IndexSearcher searcher = alix.searcher();
// searcher.setSimilarity(sim.similarity());
TopDocs topDocs = searcher.search(query, limit, sort);
ScoreDoc[] hits = topDocs.scoreDocs;
int no = 1;
for (ScoreDoc hit: hits) {
  // System.out.println(doc.score +" — " + alix.reader().document(doc.doc));
  final int docId = hit.doc;
  double score = hit.score;
  Document doc = searcher.doc(docId, DOC_SHORT);
  String text = doc.get("bibl");
  // fast hack because of links in links
  text = text.replaceAll("<(/?)a([ >])", "<$1span$2");
  out.print("<div class=\"bibl\" id=\"" + doc.get(Alix.ID) + "\">");
  if (marker != null) {
    // sb.append("<a class=\"bibl\" href=\"compdoc.jsp?id="+doc.get(Alix.ID)+paging+back+"\">");
    out.println(marker.mark(text));
    // sb.append("</a>\n");
  }
  else {
    // sb.append("<a class=\"bibl\" href=\"compdoc.jsp?id="+doc.get(Alix.ID)+paging+back+"\">");
    out.print(text);
     // sb.append("</a>\n");
  }
  out.print("</div>");

}

%>