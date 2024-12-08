<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.FieldPhraseList"%>
<%@ page import="com.github.oeuvres.alix.util.Chain"%>
<%@ page import="com.github.oeuvres.alix.util.IntList"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.AnalyzerCloud"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.TokenizerML"%>
<%!
/**
 * This concordancer is designed for multi words queries,
 * contexts are sorted in query order
 */

static final HashSet<String> STORED_REC = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, "cert", BIBL, TEXT, YEAR })
);

%>
<%

response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", "", Set.of("", ".txt"));
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}

final String textName = TEXT_CLOUD;

// Prepare the filter query
FieldInt yearField = alix.fieldInt(YEAR);
final int yearMin = yearField.min();
final int yearMax = yearField.max();
final int[] years = tools.getIntRange(YEAR, new int[]{yearMin, yearMax});


//build query
BooleanQuery.Builder filterBuild = new BooleanQuery.Builder();
int clauses = 0;
if (years == null) {
    
}
else if (years.length == 1) {
    clauses++;
    filterBuild.add(IntField.newExactQuery(YEAR, years[0]), BooleanClause.Occur.MUST);
}
else if (years.length > 1) {
    clauses++;
    filterBuild.add(IntField.newRangeQuery(YEAR, years[0], years[1]), BooleanClause.Occur.MUST);
}
final String[] tags = tools.getStringSet(TAG);
if (tags.length == 1) {
    clauses++;
    filterBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.MUST);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    clauses++;
    filterBuild.add(tagBuild.build(), BooleanClause.Occur.MUST);
}
filterBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.MUST);
BooleanQuery filterQuery = filterBuild.build();

// loop on each queries and send occurrencies
do {
    if (request.getParameter(Q) == null) break;
    int l = 0;
    for (final String q: request.getParameterValues(Q)) {
        l++;
        out.println("<div class=\"q" + l + "\">");
        if (q == null || q.isBlank()) {
            out.println("<h1><i>[pas de requête]</i></h1>");
            out.println("</div>");
            continue;
        }
        Query textQuery = qText(alix.analyzer(), textName, q);
        Query query = new BooleanQuery.Builder()
           .add(filterQuery, BooleanClause.Occur.FILTER)
           .add(textQuery, BooleanClause.Occur.SHOULD)
       .build();
        
    }
} while (false);

/*

Query query = null;
// should be OK
if (qText != null) {
    query = queryBuild.build();
}
//for tags and search dates, secure search by a filter on docs with text
else if (clauses > 0) {
    queryBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.FILTER);
    query = queryBuild.build();
}
// if no clauses, ensure to count texts
else {
    query = new TermQuery(new Term(ALIX_TYPE, TEXT));
}


final Sort sort = new Sort(new SortField(ALIX_ID, SortField.Type.STRING));
TopDocs results = searcher.search(query, 5000, sort, false);
ScoreDoc[] hits = results.scoreDocs;
// total count of texts in corpus
int docs = reader.getDocCount(TEXT);
// found texts, exact is needed, hope for cache from lucene
final int hitsLength = hits.length;


FieldQuery fieldQuery = null;
if (qText != null) {
    fieldQuery = new FieldQuery(query, reader, true, true);
}
StoredFields storedFields = searcher.storedFields();
int occsAll = 0;
// no div container for onprogress insertion
// out.println ("<div id=\"kwic_top\" class=\"kwic_results\">");
for (int i = 0; i < hitsLength; i++) {
    final int docId = hits[i].doc;
    final Document document = storedFields.document(docId, STORED_REC);
    final String title = document.get("bibl");
    final String id = document.get(ALIX_ID);
    Number year = null;
    do {
        if (document.getField(YEAR) == null) break;
        year = document.getField(YEAR).numericValue();
        if (year == null) break;
        yearDocs[(int)year - yearMin]++;
        if (yearId[(int)year - yearMin] == null) yearId[(int)year - yearMin] = id;
    } while (false);
    String href = id;
    if (q != null && !"".equals(q.trim())) href += "?qtype=cloud&amp;q=" + JspTools.escape(q);
    String cert = document.get("cert");
    cert = (cert == null)?"":" cert-" + cert;
    out.println ("<article id=\"kwic_" + id + "\" class=\"kwic" + cert + "\">");
    out.println ("<a class=\"bibl\" href=\""+ href + "\">");
    out.print("<small class=\"num\">" + (i+1) + ".</small> ");
    out.print("<small class=\"id\">[" + id + "]</small> ");
    out.print(title);
    out.println ("</a>");
    if (qText == null) {
        if (year != null) {
            yearCount[(int)year - yearMin] += fieldText.occsByDoc(docId);
        }
        out.println ("</article>");
        continue;
    }
    // conc
    final String text = document.get(TEXT);
    if (text == null) {
        // ??
        out.println ("</article>");
        continue;
    }
    // get occurencies
    FieldTermStack fieldTermStack = new FieldTermStack(alix.reader(), docId, TEXT_CLOUD, fieldQuery);
    // merge them as phrases
    FieldPhraseList phrases = new FieldPhraseList(fieldTermStack, fieldQuery, 100);
    int pointer = 0;
    final int length = text.length();
    Chain line = new Chain();
    int occIndex = 0;
    
    for (FieldPhraseList.WeightedPhraseInfo phrase: phrases.getPhraseList()) {
        final int start = phrase.getStartOffset();
        final int end = phrase.getEndOffset();
        final FieldTermStack.TermInfo tinfo = phrase.getTermsInfos().get(0);
        final int position = tinfo.getPosition();
        final String form = text.substring(start, end);
        final String idPos = "pos" + position;
        
        occsAll++;
        occIndex++;
        out.print("<a class=\"line\" href=\""+ href + "#" + idPos + "\">");
        out.print("<small>" + (occIndex) + ".</small>  ");
        line.reset();
        ML.prependChars(text, start-1, line, 50);
        line.append("<mark id=\"" + id + "\">" + ML.detag(form) + "</mark>");
        ML.appendChars(text, end, line, 50);
        out.print(line);
        out.println("</a>");
        pointer = end;
    }
    out.println ("</article>");
    if (year != null) {
        yearCount[(int)year - yearMin] += occIndex;
    }
}
// navigation bar
out.println("<nav id=\"kwic_nav\" class=\"kwic\">");
out.println("  <style>");
out.println("    #kwic_nav .year {");
String percent = String.format(Locale.US, "%.2f", 100.0 / (yearMax + 1 - yearMin));
out.println("          height: " + percent + "%;");
out.println("    }");
out.println("  </style>");



int decLast = 10 * (yearMin/10);


double countMax = 0;
for (int i = 0; i < yearCount.length; i++) {
    countMax = Math.max(countMax, yearCount[i]);
}
String id ="top";
for (int year = yearMin; year <= yearMax; year++) {
    final int yearDec = 10 * (year/10);
    if (yearDec != decLast) {
        out.println("<b class=\"kwic decade\">" + yearDec + "</b>");
        decLast = yearDec;
    }
    final int index = year - yearMin;
    final int count = yearCount[index];
    final double ratio = (countMax == 0)?0:(count/countMax);
    for (int i = index; i < yearId.length; i++) {
        if (yearId[i] != null) {
            id = yearId[i];
            break;
        }
    }
    String title = "" + year;
    String cls = "year";
    if (count > 0) {
        title += ", " + yearDocs[index] + " documents, " + count;
        if (q == null) {
            title += " mots.";
        }
        else {
            title += " occurrences.";
        }
    }
    else {
        cls += " empty";
    }
    final String href = " href=\"#kwic_" + yearId[index] + "\"";
    out.println (
          "<a"
        + " class=\"" + cls + "\""
        + " title=\"" + title + "\""
        + " href=\"#kwic_" + id + "\""
        + " style=\"background: " + color(ratio) + "\""
        + "> </a>"
    );
}
out.println ("</nav>");

*/

%>