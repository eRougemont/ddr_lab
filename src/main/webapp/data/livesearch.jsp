<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>


<%@ page import="com.github.oeuvres.alix.lucene.analysis.AnalyzerMeta"%>



<%!
static final Analyzer ANAMET = new AnalyzerMeta();
static final HashSet<String> STORED_REC = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, BIBL })
);
static final Set<String> MARK = new HashSet<>(
    Arrays.asList(new String[] {"mark"})
);

%>
<%
final int hpp = 10;
Query query;
Query queryText = null;
Query queryTitle;
String q = tools.getString("q", null);
int p = tools.getInt("page", 1);
StringBuilder wildq = new StringBuilder();
// filters, dates or tags
if (q == null) {
    query = new TermQuery(new Term(ALIX_TYPE, TEXT));
}
else {
    // to lower
    q = Char.toASCII(q).toLowerCase();
    // split terms
    String[] terms = alix.tokenize(q, "search");
            
    BooleanQuery.Builder bqText = new BooleanQuery.Builder().add(new TermQuery(new Term(ALIX_TYPE, BOOK)), BooleanClause.Occur.MUST_NOT);
    BooleanQuery.Builder bqTitle = new BooleanQuery.Builder().add(new TermQuery(new Term(ALIX_TYPE, BOOK)), BooleanClause.Occur.MUST_NOT);
    for (String t: terms) {
        if (t.length() < 1) continue;
        BooleanQuery.Builder bqTerm = new BooleanQuery.Builder();
        wildq.append(" " + t + "*");
        bqTitle.add(new WildcardQuery(new Term(BIBL, t + '*')), BooleanClause.Occur.SHOULD);
        bqText.add(new WildcardQuery(new Term(TEXT, t + '*')), BooleanClause.Occur.MUST);
        // if enough letters, search in middle of words
        if (t.length() >= 3) {
            wildq.append(" *" + t + "*");
            bqTitle.add(new BoostQuery(new WildcardQuery(new Term(BIBL, '*' + t + '*')), 0.5f), BooleanClause.Occur.SHOULD);
            bqText.add(new BoostQuery(new WildcardQuery(new Term(TEXT, '*' + t + '*')), 0.5f), BooleanClause.Occur.SHOULD);
        }
    }
    queryText = bqText.build();
    queryTitle = bqTitle.build();
    query = new BooleanQuery.Builder()
        .add(new BoostQuery(queryTitle, 5f), BooleanClause.Occur.SHOULD)
        .add(queryText, BooleanClause.Occur.SHOULD)
        .build();
}
// out.println(query);
final String afterKey = q+"#"+p;
int startHit = 0;
int numHits = hpp * 3; // seen elsewhere, get some results more
if (p < 1) {
    p = 1;
}
// session seems dangerous, believe in lucene cache
if (p > 1) {
    // no cursor for searchAfter, try 
    startHit = hpp * (p-1);
    numHits = hpp * (p+ 2);
}

TopDocs results = searcher.search(query, numHits);
ScoreDoc[] hits = results.scoreDocs;
// total count of texts in corpus
int docs = reader.getDocCount(TEXT);
// found texts, exact is needed, hope for cache from lucene
final int numTotalHits = hits.length;

int endHit = Math.min(numTotalHits, startHit + hpp);
if (endHit < 1) {
    response.setStatus(404);
    return;
}
// out.println(numTotalHits + "/" + docs + " textes");


StoredFields storedFields = searcher.storedFields();
// tools for hiliting
FastVectorHighlighter fvh = new FastVectorHighlighter();
FragListBuilder fragListBuilder = new WeightedFragListBuilder();
FragmentsBuilder fragmentsBuilder = new ScoreOrderFragmentsBuilder();
Encoder encoder = new DefaultEncoder();

Marker marker = null; // hiliter for title
FieldQuery fieldQuery = null; // for best fragments in texts
Set<String> fields4vectors = null;
if (q != null) {
    try {
        marker = new Marker(ANAMET, wildq.toString());
    }
    catch (Exception e) {
        // too complex automat
    }
    fieldQuery = new FieldQuery(queryText, reader, true, true);
    // Fields of the query to get vectors from
    fields4vectors = new HashSet<>(Arrays.asList(TEXT));
}
//match all
else {
    fields4vectors = new HashSet<>(Arrays.asList(TEXT_CLOUD));
}
for (int i = startHit; i < endHit; i++) {
    final int docId = hits[i].doc;
    Document doc = storedFields.document(docId, STORED_REC);
    String title = doc.get("bibl");
    out.println ("<a class=\"rec\" href=\"" + doc.get(ALIX_ID) + "?qtype=wild&amp;q=" + q + "\">");
    out.print("<h4>");
    // hilite title with query
    if (marker != null) {
        out.print(marker.mark(title));
    }
    else {
        out.print(title);
    }
    out.println("</h4>");
    // nothing requested, try to get most significant snips from doc to get fragments
    if (q == null) {
        BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
        FormEnum forms = Doc.formEnum(alix, docId, TEXT_CLOUD, Distrib.G, TagFilter.NOSTOP);
        // 10 most significant words from this text
        forms.sort(FormEnum.Order.SCORE, 10, false);
        forms.reset();
        while (forms.hasNext()) {
            forms.next();
            String form = forms.form();
            if (form.trim().isEmpty()) continue;
            Query tq = new TermQuery(new Term(TEXT_CLOUD, forms.form()));
            qBuilder.add(tq, BooleanClause.Occur.SHOULD);
        }
        fieldQuery = new FieldQuery(qBuilder.build(), reader, true, true);
    }
    // get best fragments from text
    String[] fragments = fvh.getBestFragments(
        fieldQuery,
        reader,
        docId,
        TEXT, // the store field to find text in
        fields4vectors, // search field
        100,
        5,
        fragListBuilder,
        fragmentsBuilder,
        new String[]{"<mark>"},
        new String[]{"</mark>"}, 
        encoder
    );
    // no fragment found ?
    if (fragments == null) continue;
    out.println("<p class=\"frag\">");
    boolean first = true;
    for (String frag: fragments) {
        if (frag == null) continue;
        if (first) first = false;
        else out.print(" […] ");
        // replace is an inefficent hack, detag should allow include or exclude
        out.print(ML.detag(frag, MARK));
    }
    out.println("</p>");
    out.println ("</a>");
}

%>
