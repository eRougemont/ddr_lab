<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.store.FSDirectory"%>
<%
//set response header according to extension requested
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", ".txt", Set.of(".json", ".js"), null);
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}

final String q = tools.getString(Q, null);

final String[] tags = tools.getStringSet(TAG);

BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
if (tags.length == 1) {
    queryBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.FILTER);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
}
BitSet docFilter = null;
BooleanQuery query = queryBuild.build();
if (query.clauses().size() > 0) {
    queryBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.FILTER);
    BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
    docFilter = searcher.search(query, qbits);
}


FieldText ftext = alix.fieldText(TEXT_CLOUD);
FieldRail frail = alix.fieldRail(TEXT_CLOUD);

FormEnum formEnum = null;
if (q != null) {
    String[] pivots = alix.tokenize(q, TEXT_CLOUD);
    int[] pivotIds = ftext.formIds(pivots);
    formEnum = frail.coocs(
        ftext.bytesSorted(pivots),
        10, 
        10,
        docFilter
    ).filter(TagFilter.NOSTOP).score(MI.CHI2, pivotIds).sort(FormIterator.Order.SCORE);
}
else {
    formEnum = ftext.formEnum(docFilter, TagFilter.NOSTOP, Distrib.BM25).sort(FormIterator.Order.SCORE);
}
out.println(formEnum);


/*




FormEnum terms = ftext.formEnum(docFilter, TagFilter.NOSTOP, Distrib.G);
terms.sort(FormIterator.Order.SCORE, 100, false);
int n = 1;
while(terms.hasNext()) {
    terms.next();
    out.println("" + (n++)+ ". " + terms.form() + " (" + terms.freq() + "/" + terms.occs() + ")" + " " + terms.score());
}

*/

%>
