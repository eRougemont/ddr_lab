<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.SuggestForm"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.SuggestForm.Suggestion"%>

<%!
public String json(final String form, final long freq, final int hits, final String marked)
{
    String json = "";
    json += "{";
    json += "\"form\":\"" + form.replace("\"", "\\\"") + "\"";
    json += ", \"freq\":" + freq;
    json += ", \"hits\":" + hits;
    json += ", \"marked\":\"" + marked.replace("\"", "\\\"") + "\"";
    json += "}";
    return json;
}
%>

<%
// params
final String fieldName = TEXT_CLOUD;
//words to suggest
final int limit = 20;
//list titles without paging in id order
final String q = tools.getString(Q, null);
final String[] tags = tools.getStringSet(TAG);
final FieldInt fint = alix.fieldInt(YEAR);
final int[] dates = tools.getIntRange(YEAR, new int[]{fint.min(), fint.max()});
//a kind of doc filter
final String bookId = tools.getString("book", null);

// set response header according to extension requested
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", ".json", Set.of(".json", ".js", ".txt"), null);
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}



//what kind of word to filter ?
final TagFilter wordFilter = TagFilter.NOSTOP;

// Where to search in
SuggestForm suggester = alix.suggestForm(fieldName);

boolean first;

// filter documents on query
BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
int clauses = 0;

if (bookId != null) {
    clauses++;
    queryBuild.add(new TermQuery(new Term(ALIX_BOOKID, bookId)), BooleanClause.Occur.FILTER);
}

if (dates == null || bookId != null) {
}
else if (dates.length == 1) {
    clauses++;
    queryBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.FILTER);
}
else if (dates.length == 2) {
    clauses++;
    queryBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.FILTER);
}

if (tags == null || tags.length == 0) {
    // if book, no tags
}
else if (tags.length == 1) {
    clauses++;
    queryBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.FILTER);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
    clauses++;
}
BitSet docFilter = null;
if (clauses > 0) {
    Query query = queryBuild.build();
    BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
    docFilter = searcher.search(query, qbits);
}



if (q == null || q.isBlank()) {
    //   {"form":"machine", "freq":84, "hits":29, "marked":"mac<b>hin</b>e"},
    // because of docFilter or tagFilter, freq and hits are available;
    FormEnum formEnum = alix.fieldText(fieldName).formEnum(docFilter, TagFilter.NOSTOP, Distrib.FREQ);
    formEnum.sort(Order.FREQ, limit);
    out.println("[");
    first = true;
    while (formEnum.hasNext()) {
        if (first) first = false;
        else out.println(",");
        formEnum.next();
        out.print("  " + json(formEnum.form(), formEnum.freq(), formEnum.hits(), formEnum.form()));
    }
    out.println("\n]");
    return;
}



// try as prefix
Suggestion[] options = suggester.search("_" + q, limit, wordFilter, docFilter);
if (options.length < limit) {
    options = suggester.search(q, limit, wordFilter, docFilter);
}

first = true;
out.println("[");
for (final Suggestion option: options) {
    if (first) first = false;
    else out.println(",");
    out.print("  " + json(option.form(), option.freq(), option.hits(), option.marked()));
}
out.println("\n]");
%>



