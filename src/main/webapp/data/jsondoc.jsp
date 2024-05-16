<%@ page language="java" contentType="text/javascript; charset=utf-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.text.DecimalFormatSymbols"%>
<%@ page import="java.util.Arrays"%>
<%@ page import="java.util.HashSet"%>
<%@ page import="java.util.Locale"%>
<%@ page import="java.util.regex.Pattern"%>
<%@ page import="java.util.regex.Matcher"%>
<%@ page import="java.util.Set"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.BooleanQuery"%>
<%@ page import="org.apache.lucene.search.Query"%>
<%@ page import="org.apache.lucene.search.BooleanClause"%>
<%@ page import="org.apache.lucene.search.IndexSearcher"%>
<%@ page import="org.apache.lucene.search.ScoreDoc"%>
<%@ page import="org.apache.lucene.search.TermQuery"%>
<%@ page import="org.apache.lucene.search.TopDocs"%>
<%@ page import="org.apache.lucene.util.BitSet"%>
<%@ page import="org.apache.lucene.util.SparseFixedBitSet"%>
<%@ page import="com.github.oeuvres.alix.Names" %>
<%@ page import="com.github.oeuvres.alix.fr.Tag" %>
<%@ page import="com.github.oeuvres.alix.lucene.Alix" %>
<%@ page import="com.github.oeuvres.alix.lucene.search.Doc" %>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldRail" %>
<%@ page import="com.github.oeuvres.alix.lucene.search.FieldText" %>
<%@ page import="com.github.oeuvres.alix.lucene.search.FormEnum" %>
<%@ page import="com.github.oeuvres.alix.util.Edge" %>
<%@ page import="com.github.oeuvres.alix.util.EdgeSquare" %>
<%@ page import="com.github.oeuvres.alix.web.JspTools" %>
<%@ page import="com.github.oeuvres.alix.web.OptionCat" %>
<%@ page import="com.github.oeuvres.alix.web.OptionDistrib" %>
<%@ page import="com.github.oeuvres.alix.web.Webinf" %>
<%!
/** Load bases from WEB-INF/, one time */
static {
    if (!Webinf.bases) {
        Webinf.bases();
    }
}

static final DecimalFormat scoref = new DecimalFormat("0.000", DecimalFormatSymbols.getInstance(Locale.ENGLISH));

%>
<%
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
// parameters
JspTools tools = new JspTools(pageContext);
final int edgeLen = tools.getInt("edges", 60);
int nodeLen = tools.getInt("nodes", 30);
int context = 20;
String callback = tools.getString("callback", null);

if (callback != null) {
    if (!callback.matches("^\\w+$")) {
        out.println("{");
        out.println("  \"errors\": [");
        out.println("    {");
        out.println("      \"status\": \"401\",");
        out.println("      \"title\": \"Attempt of XSS, no.\"");
        out.println("    }");
        out.println("  ]");
        out.println("}");
        response.setStatus(401);
        return;
    }
    out.print(JspTools.escape(callback) +"(");
}
out.println("{");
long time = System.nanoTime();
//test if Alix available with at least on base
if (Alix.pool.size() < 1) {
    out.println("  \"errors\": [");
    out.println("    {");
    out.println("      \"status\": \"500\",");
    out.println("      \"title\": \"" + Alix.pool.size() + " Alix base available, installation problem\"");
    out.println("    }");
    out.println("  ]");
    out.println("}");
    response.setStatus(500);
    return;
}
Alix alix = (Alix) tools.getMap("base", Alix.pool, null, "alix.base");
String baseName = request.getParameter("base");
if (alix == null && baseName != null) {
    out.println("  \"errors\": [");
    out.println("    {");
    out.println("      \"status\": \"404\",");
    out.println("      \"title\": \"base “" + baseName + "” not available\"");
    out.println("    }");
    out.println("  ]");
    out.println("}");
    response.setStatus(404);
    return;
}
baseName = (String) Alix.pool.keySet().toArray()[0];
alix = Alix.pool.get(baseName);
// send error if base not available instead of default ? 

// get document
String id = tools.getString("id", null);
if (id == null) {
    out.println("  \"errors\": [");
    out.println("    {");
    out.println("      \"status\": \"400\",");
    out.println("      \"title\": \"No document requested\"");
    out.println("    }");
    out.println("  ]");
    out.println("}");
    response.setStatus(400);
    return;
}
int docId = alix.getDocId(id);
if (docId < 0) {
    out.println("  \"errors\": [");
    out.println("    {");
    out.println("      \"status\": \"404\",");
    out.println("      \"title\": \"Document “" + id + "” not found\"");
    out.println("    }");
    out.println("  ]");
    out.println("}");
    response.setStatus(404);
    return;
}

Doc doc = new Doc(alix, docId);
// get words
String field = "text";
FormEnum nodes = doc.forms(field, OptionDistrib.G, OptionCat.NOSTOP.tags()); // 
if (nodes.occsFreq() < 1) {
    out.println("  \"errors\": [");
    out.println("    {");
    out.println("      \"status\": \"418\",");
    out.println("      \"title\": \"Document “" + id + "” seems empty\"");
    out.println("    }");
    out.println("  ]");
    out.println("}");
    response.setStatus(404);
    return;
}
nodes.sort(FormEnum.Order.SCORE, nodeLen);
nodeLen = nodes.limit(); // if less than requested

BitSet filter = new SparseFixedBitSet(docId +2);
filter.set(docId);


out.println("  \"data\": [");


final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);
boolean first;
// Collect the formIds
int[] formIds = new int[nodeLen];

nodes.reset();
BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
out.println("    {");
out.println("      \"nodes\": [");
first = true;
int i = 0;
while(nodes.hasNext()) {
    nodes.next();
    final int formId = nodes.formId();
    formIds[i] = formId;
    i++;
    if (first) {
    	first = false;
    }
    else {
    	out.println(", ");
    }
    int tag = ftext.tag(formId);
    String color = "rgba(255, 255, 255, 1)";
    if (Tag.SUB.sameParent(tag)) color = "rgba(255, 255, 255, 0.8)";
    else if (Tag.ADJ.sameParent(tag)) color = "rgba(240, 255, 240, 0.7)";
    // if (node.type() == STAR) color = "rgba(255, 0, 0, 0.9)";
    else if (Tag.NAME.sameParent(tag)) color = "rgba(255, 192, 0, 1)";
    // else if (Tag.isVerb(tag)) color = "rgba(0, 0, 0, 1)";
    // else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
    else color = "rgba(159, 183, 159, 1)";
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    double size = nodes.freq();
    out.print("        {");
    out.print("\"id\":\"n" + formId + "\"");
    out.print(", \"label\":\"" + ftext.form(formId).replace("\"", "\\\"") + "\"");
    out.print(", \"size\":" + size); // node.count
    out.print(", \"score\":" + scoref.format(nodes.score()) ); // node.count
    out.print(", \"x\":" + ((int)(Math.random() * 100)));
    out.print(", \"y\":" + ((int)(Math.random() * 100)) );
    out.print(", \"color\":\"" + color + "\"");
    out.print("}");
    if (i <= 30) {
        Query tq = new TermQuery(new Term(field, nodes.form()));
        qBuilder.add(tq, BooleanClause.Occur.SHOULD);
    }
}
out.println("\n      ],");

 // build edges

EdgeSquare edges = frail.edges(formIds, context, filter);
 
out.println("      \"edges\": [");
first = true;
int edgeCount = 0;
for (Edge edge: edges) {
    if (edge.source == edge.target) {
        continue;
    }
    final double score = edge.score();
    if (first) first = false;
    else out.println(", ");
    out.print("        {\"id\":\"e" + (edgeCount) + "\", \"source\":\"n" + edge.source + "\", \"target\":\"n" + edge.target + "\", \"size\":" + (score<=0?0.1:score * 100) 
    + ", \"color\":\"rgba(192, 192, 192, 0.2)\""
    // for debug
    // + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
    if (++edgeCount >= edgeLen) {
        break;
    }
}
out.println("\n      ],");

// seealso links
out.println("      \"seealso\": [");
first = true;
Query mlt = qBuilder.build(); // is build on loop on nodes
IndexSearcher searcher = alix.searcher();
// test has been done, default BM25 seems the best
TopDocs topDocs;
topDocs = searcher.search(mlt, 20);
ScoreDoc[] hits = topDocs.scoreDocs;
final String href = "?id=";
final Set<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Names.ALIX_ID, Names.ALIX_BOOKID, Names.ALIX_FILENAME, "bibl", "type"}));
Pattern journalRe = Pattern.compile("ddr\\d+([a-z]+)");
for (ScoreDoc hit: hits) {
    if (hit.doc == docId) continue;
    if (first) first = false;
    else out.println(", ");
    Document aDoc = alix.reader().document(hit.doc, DOC_SHORT);
    String aId = aDoc.get(Names.ALIX_ID);
    String aType = aDoc.get("type");
    out.println("        {");
    out.println("          \"id\": \"" + aId +"\",");
    out.println("          \"type\": \"" + aType +"\",");
    String url = "https://www.unige.ch/rougemont/";
    if ("chapter".equals(aType)) {
        url += "livres/";
        url += aId.substring(0, aId.indexOf('_')) + "/";
        url += Integer.parseInt(aId.substring(aId.indexOf('_')+1));
        out.println("          \"url\": \"" + url +"\",");
    }
    else if ("article".equals(aDoc.get("type"))) {
        url += "articles/";
        Matcher m = journalRe.matcher(aId);
        // url += journalRe.matcher(aId); // .group(1) + "/";
        if (!m.find()) { // strange ?
            out.println("          \"ERROR\": \"" + aId +"\",");
        }
        else {
            url += aDoc.get(Names.ALIX_FILENAME).substring(4) + "/"; // strip 'ddr-'
            url += aId;
            out.println("          \"url\": \"" + url +"\",");
        }
    }
    else {
        // ???
    }
    out.println("          \"bibl\": \"" + aDoc.get("bibl").replace("\"", "\\\"").replaceAll("[ \\n\\t]+", " ").trim() +"\"");
    out.print("        }");
}
out.println("\n      ]");



out.println("\n    }");
out.println("  ],");
out.println("  \"meta\": {");
out.println("    \"time\": \"" + ( (System.nanoTime() - time) / 1000000) + "ms\"");
out.println("\n  }");

out.print("}");
if (callback != null) {
    out.print(");");
}
out.println();
%>



