<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="alix.util.Top" %>
<%@include file="jsp/prelude.jsp" %>
<!DOCTYPE html>
<html class="document">
  <head>
    <%@ include file="local/head.jsp" %>
    <title>Réseau des chapitres</title>
    <style type="text/css">
dt {
    font-weight: bold;
    padding-top: 1rem;
    font-size: 85%;
}
    </style>
  </head>
  <body class="document">
    <header>
      <%@ include file="local/tabs.jsp" %>
    </header>
    <main>
      <div class="row">
        <div class="text">
<%

// loop on al chapter
final HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Alix.ID, Alix.BOOKID, "analytic", "bibl"}));
Query query = new TermQuery(new Term(Alix.TYPE, DocType.chapter.name()));
IndexSearcher searcher = alix.searcher();
ScoreDoc[] biblio = OptionSort.id.top(searcher, query).scoreDocs;
final String field = "text";
int no = 1;
out.println("<dl>");
for (ScoreDoc src: biblio) {
    final int docId = src.doc;
    Doc doc = new Doc(alix, docId);
    // Show bibl
    Document srcDoc = doc.doc();
    // out.println(document.get(Alix.BOOKID) + " " + ML.detag(document.get("analytic")).trim());
    no++;
    BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
    FormEnum forms = doc.results(field, OptionDistrib.g.scorer(), OptionCat.ALL.tags());
    final int keysLimit = 30;
    forms.sort(FormEnum.Order.score, keysLimit, false);
    forms.reset();
    while (forms.hasNext()) {
        forms.next();
        String form = forms.form();
        if (form.trim().isEmpty()) continue;
        Query tq = new TermQuery(new Term(field, form));
        qBuilder.add(tq, BooleanClause.Occur.SHOULD);
    }
    Query mltQ = qBuilder.build();
    ScoreDoc[] mltDocs = searcher.search(mltQ, 10).scoreDocs;
    boolean first = true;
    for (ScoreDoc tgt: mltDocs) {
        if (tgt.doc == docId) continue;
        if (tgt.score < 25) break;
        if (first) {
            out.println("  <dt>"+ " <a href=\"doc.jsp?id=" + srcDoc.get(Alix.ID) + "\"> " + ML.detag(srcDoc.get("bibl")).trim() + "</a>" + "</dt>");
            first = false;
        }
        Document tgtDoc = reader.document(tgt.doc, DOC_SHORT);
        out.println("    <dd>" + tgt.score + " <a href=\"doc.jsp?id=" + tgtDoc.get(Alix.ID) + "\">" + ML.detag(tgtDoc.get("bibl")).trim() + "</a></dd>");
      }
    
    /*

    // searcher.setSimilarity(oldSim);
    ScoreDoc[] hits = topDocs.scoreDocs;
    final String href = "?id=";
    final HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Alix.ID, Alix.BOOKID, "bibl"}));
    */

}
out.println("</dl>");
%>
        </div>
      </div>
    </main>
  </body>
</html>
    
