<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.FieldPhraseList"%>
<%@ page import="com.github.oeuvres.alix.util.Chain"%>
<%@ page import="com.github.oeuvres.alix.util.IntList"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.AnalyzerCloud"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.TokenizerML"%>
<%!
static final HashSet<String> STORED_REC = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, "cert", BIBL, TEXT, YEAR })
);

static final DecimalFormat frdec2 = new DecimalFormat("###,###,###,##0.00", frsyms);

public String color(final double ratio) {
    if (ratio <= 0) return "#fff";
    if (ratio > 1) return "#000";
    /* color gradient not efficient here
    final double step1 = 1.0/4;
    // white to yellow
    if (ratio < step1) {
        int percent = 100 - (int) (50 * ratio/step1);
        return "hsl(48, 100%, " + percent + "%)";
    }
    final double step2 = 3.0/4;
    if (ratio < step2) {
        // [48 0][359 240]
        final double width = 48 + (360 -240);
        final double ratio2 = (ratio - step1) / (step2 - step1);
        int hue = (int)( (48 - (ratio2 * width)) % 360);
        if (hue < 0) hue = 360 + hue;
        return "hsl(" + hue + ", 100%, 50%)";
    }
    // darker
    int percent = 50 - (int) (50 * (ratio - step2) / (1 - step2));
    return "hsl(240, 100%, " + percent + "%)";
    */
    /*
    int percent = 95 - (int) (80 * ratio);
    return "hsl(356, 100%, " + percent + "%)";
    */
    String opacity = String.format(Locale.US, "%.2f", 0.1 + 0.9 * ratio);
    return "hsla(356, 79%, 35%, " + opacity +")";
    
}

static Map<Integer, Integer> year4docs;

%>
<%

response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", "", Set.of("", ".txt"));
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}


// search parameters
final String q = tools.getString("q", null);
final String qField = tools.getString("qfield", TEXT_CLOUD, Set.of(TEXT_CLOUD, TEXT));
final FieldText fieldText = alix.fieldText(qField);
final String[] tags = tools.getStringSet(TAG);
FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();
//get the docs count for text only (not book covers)
if (year4docs == null) {
    BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
    BitSet docFilter = searcher.search(new TermQuery(new Term(ALIX_TYPE, TEXT)), qbits);
    year4docs = fint.docs(docFilter);
}


final int[] yearCount = new int[yearMax + 1 - yearMin];
final int[] yearHits = new int[yearMax + 1 - yearMin];
final String[] yearId = new String[yearMax + 1 - yearMin];

final int[] dates = tools.getIntRange(YEAR, new int[]{yearMin, yearMax});


//build query
BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
int clauses = 0;

Query qText = qText(alix.analyzer(), qField, q);
if (qText != null) {
    queryBuild.add(qText, BooleanClause.Occur.MUST);
}

if (dates == null) {
    
}
else if (dates.length == 1) {
    clauses++;
    queryBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.FILTER);
}
else if (dates.length == 2) {
    clauses++;
    queryBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.FILTER);
}
if (tags.length == 1) {
    clauses++;
    queryBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.FILTER);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    clauses++;
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
}

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
int docsAll = reader.getDocCount(TEXT);
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
        yearHits[(int)year - yearMin]++;
        if (yearId[(int)year - yearMin] == null) yearId[(int)year - yearMin] = id;
    } while (false);
    String href = id;
    if (q != null && !"".equals(q.trim())) href += "?qtype=cloud&amp;q=" + JspTools.escape(q);
    String cert = document.get("cert");
    cert = (cert == null)?"":" cert-" + cert;
    final String text = document.get(TEXT);
    String conc = (q== null)?"":" conc";
    out.println ("<article id=\"kwic_" + id + "\" class=\"kwic" + cert + conc + "\">");
    out.println ("<div class=\"bibl\">");
    if (q== null) out.print("<small class=\"num\">" + (i+1) + ".</small> ");
    out.print("<a  href=\""+ href + "\" class=\"id\">[" + id + "]</a> ");
    out.print(title);
    out.println ("</div>");
    if (qText == null) {
        if (year != null) {
            yearCount[(int)year - yearMin] += fieldText.occsByDoc(docId);
        }
        out.println ("</article>");
        continue;
    }
    // conc
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
        out.print("<div class=\"line\">");
        out.print("<small>" + (occsAll) + ".</small> ");
        line.reset();
        ML.prependChars(text, start-1, line, 50);
        // id ?
        line.append("<a class=\"mark\" href=\""+ href + "#" + idPos + "\" id=\"" + id + "\"" + ">");
        
        line.append(ML.detag(form));
        line.append("</a>");
        ML.appendChars(text, end, line, 50);
        out.print(line);
        out.println("</div>");
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
        Integer docs = year4docs.get(year);
        if (docs == null) docs = 0;
        title += ", " + yearHits[index] + "/" + docs + " textes, ";
        title += String.format(Locale.FRANCE, "%,d", count);
        if (q == null) {
            title += " mots";
        }
        else {
            title += " occurrences";
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


%>