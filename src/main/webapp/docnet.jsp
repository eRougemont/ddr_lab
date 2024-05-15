<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="alix.lucene.search.Doc"%>
<%@ page import="org.apache.lucene.search.similarities.*"%>
<%@ page import="alix.util.Top"%>
<%@include file="jsp/prelude.jsp"%>
<!DOCTYPE html>
<html class="document">
  <head>
    <%@ include file="local/head.jsp"%>
    <title>Réseau des chapitres</title>
    <style type="text/css">
dt {
    font-weight: bold;
    padding-top: 1rem;
    font-size: 85%;
}

iframe {
    border: none;
    height: calc(100vh - 40px);
    position: fixed;
    width: 33%;
}

.text {
    width: 33% !important;
}
    </style>
  </head>
<body class="document">
    <header>
        <%@ include file="local/tabs.jsp"%>
    </header>
    <main>
        <div class="row">
            <iframe style="left: 0" name="left" src="text.jsp">
            </iframe>
            <div class="text">
                <%
                // loop on al chapter
                                        final HashSet<String> DOC_SHORT = new HashSet<String>(
                                            Arrays.asList(
                                                new String[] { 
                                                    Names.ALIX_ID, 
                                                    Names.ALIX_BOOKID, 
                                                    "analytic", 
                                                    "bibl"
                                                }
                                            )
                                        );
                                        Query query = new TermQuery(new Term(Names.ALIX_TYPE, Names.CHAPTER));
                                        IndexSearcher searcher = alix.searcher();
                                        ScoreDoc[] biblio = OptionSort.id.top(searcher, query).scoreDocs;
                                        final String field = "text";
                                        int no = 1;
                                        float score = 20;
                                        int n = 20;
                                        out.println("<dl>");
                                        for (ScoreDoc src : biblio) {
                                            final int docId = src.doc;
                                            Doc doc = new Doc(alix, docId);
                                            // Show bibl
                                            Document srcDoc = doc.doc();
                                            // out.println(document.get(Alix.BOOKID) + " " + ML.detag(document.get("analytic")).trim());
                                            no++;
                                            BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
                                            FormEnum forms = doc.forms(field, OptionDistrib.G, OptionCat.ALL.tags());
                                            final int keysLimit = 30;
                                            forms.sort(FormEnum.Order.SCORE, keysLimit, false);
                                            forms.reset();
                                            while (forms.hasNext()) {
                                                forms.next();
                                                String form = forms.form();
                                                if (form.trim().isEmpty()) {
                                                    continue;
                                                }
                                                Query tq = new TermQuery(new Term(field, form));
                                                qBuilder.add(tq, BooleanClause.Occur.SHOULD);
                                            }
                                            Query mltQ = qBuilder.build();
                                            ScoreDoc[] mltDocs = searcher.search(mltQ, 10).scoreDocs;
                                            boolean first = true;
                                            for (ScoreDoc tgt : mltDocs) {
                                                if (tgt.doc == docId) {
                                                    continue;
                                                }
                                                if (tgt.score < score) {
                                                    break;
                                                }
                                                if (first) {
                                                    out.println("  <dt>" + " <a target=\"left\" href=\"text.jsp?id=" + srcDoc.get(Names.ALIX_ID) + "\"> "
                                                    + ML.detag(srcDoc.get("bibl")).trim() + "</a>" + "</dt>");
                                                    first = false;
                                                }
                                                Document tgtDoc = reader.document(tgt.doc, DOC_SHORT);
                                                out.println("    <dd>" + tgt.score + " <a target=\"right\" href=\"text.jsp?id=" + tgtDoc.get(Names.ALIX_ID) + "\">"
                                                + ML.detag(tgtDoc.get("bibl")).trim() + "</a></dd>");
                                            }
                                            if (first) {
                                                continue;
                                            }
                                        }
                                        out.println("</dl>");
                %>
            </div>
            <iframe style="right: 0" name="right" src="text.jsp">
            </iframe>

        </div>
    </main>
</body>
</html>

