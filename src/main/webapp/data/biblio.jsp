<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>

<%@ page import="com.github.oeuvres.alix.lucene.search.Marker"%>



<%!

static final HashSet<String> STORED_REC = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, BIBL })
);
static final Sort sortByDocId = new Sort(new SortField(null, SortField.Type.DOC));
%>
<%
// list titles without paging in id order
final String q = tools.getString(Q, null);
final String[] tags = tools.getStringSet(TAG);
final FieldInt fint = alix.fieldInt(YEAR);
final int[] dates = tools.getIntRange(YEAR, new int[]{fint.min(), fint.max()});

BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
queryBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.FILTER);
if (dates == null || dates.length == 0);
else if (dates.length == 1) {
    queryBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.FILTER);
}
else if (dates.length == 2) {
    queryBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.FILTER);
}
if (tags == null || tags.length == 0);
else if (tags.length == 1) {
    queryBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.FILTER);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
}
// word query ?
final Query query = queryBuild.build();

final int lotsOfDocs = 2000;
TopDocs results = searcher.search(query, lotsOfDocs, sortByDocId, false);
ScoreDoc[] hits = results.scoreDocs;

// found texts, exact is needed, hope for cache from lucene
final int numTotalHits = hits.length;

StoredFields storedFields = searcher.storedFields();
for (int i = 0, max = hits.length; i < max; i++) {
    final int docId = hits[i].doc;
    Document doc = storedFields.document(docId, STORED_REC);
    String title = doc.get("bibl");
    out.print ("<a class=\"rec\" href=\"" + doc.get(ALIX_ID) + "\">");
    out.print("<small>" + (i+1) + ".</small> ");
    out.print(title);
    out.println ("</a>");
}

%>
