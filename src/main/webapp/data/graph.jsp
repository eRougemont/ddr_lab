<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.util.SparseFixedBitSet"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.FormCollector.FormStats"%>
<%@ page import="com.github.oeuvres.alix.util.Edge"%>
<%@ page import="com.github.oeuvres.alix.util.EdgeMatrix"%>
<%@ page import="com.github.oeuvres.alix.util.IntList"%>

<%
// set response header according to extension requested
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", ".json", Set.of(".json", ".js", ".txt"));
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}

//word to query
// list titles without paging in id order
final String q = tools.getString(Q, null);
final String[] tags = tools.getStringSet(TAG);
final FieldInt fint = alix.fieldInt(YEAR);
final int[] dates = tools.getIntRange(YEAR, new int[]{fint.min(), fint.max()});
// parameters
// count of nodes to collect
final int nodeLimit = tools.getInt("nodes", new int[]{10, 200}, 70);
// count of edges
double edgeCoef = 2;
//context width where to capture co-occurency
final int winsize =  tools.getInt("win", new int[]{1, 100}, 20);
final int left = (int)(winsize / 2);
final int right = (int)(winsize / 2);


if (q == null) {
    edgeCoef = 2.5;
}
//what kind of word to filter ?
TagFilter wordFilter = TagFilter.ALL;
// get words by score
final Order order = FormEnum.Order.SCORE;
// a kind of doc filter
final String bookId = tools.getString("book", null);


// Where to search in
final String fname = TEXT_CLOUD;
final FieldText ftext = alix.fieldText(fname);
final FieldRail frail = alix.fieldRail(fname);
boolean first;

// filter documents on query
BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
int clauses = 0;

if (bookId != null) {
    clauses++;
    queryBuild.add(new TermQuery(new Term(ALIX_BOOKID, bookId)), BooleanClause.Occur.FILTER);
}

if (bookId != null || dates == null || dates.length == 0) {
    // if book, no dates
}
else if (dates.length == 1) {
    clauses++;
    queryBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.FILTER);
}
else if (dates.length == 2) {
    clauses++;
    queryBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.FILTER);
}

if (bookId != null || tags == null || tags.length == 0) {
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
    clauses++;
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
}

BitSet docFilter = null;
if (clauses > 0) {
    queryBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.FILTER);
    BooleanQuery query = queryBuild.build();
    BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
    docFilter = searcher.search(query, qbits);
}


FormIterator nodeEnum = null;
int[] nodeIds = null;
Set<Integer> pivotLookup = new HashSet<>();
EdgeMatrix matrix = null;
if (q != null) {
    //context width where to capture co-occurency
    // let’s try to find pivots words for coocs
    String[] forms = alix.tokenize(q, fname);
    if (forms == null || forms.length < 1) {
        out.println("{\"error\": \"Aucun mot dans la requête (" + q + ").\"}");
        return;
    }
    // 
    
    
    int[] pivots = ftext.formIds(forms, docFilter);
    if (pivots == null) {
        if (forms.length == 1) {
            out.println("{\"error\": \"Mot absent du corpus (" + q + ").\"}");
        } else {
            out.println("{\"error\": \"Mots absents du corpus (" + q + ").\"}");
        }
        return;
    }
    int pivotLen = pivots.length;

    // if 2+ pivots, coocs should be colected separately, because freqs may be very different,
    // so that scoring may show coocs from one pivot only.
    FormEnum[] pivotCoocs = new FormEnum[pivotLen];
    
    TagFilter tagFilter = TagFilter.NOSTOP;
    if (pivotLen > 1 || Tag.parent(ftext.tag(pivots[0])) == Tag.NAME ) {
        tagFilter = new TagFilter().setGroup(Tag.NAME).set(Tag.SUB).set(Tag.ADJ);
        edgeCoef = 1.7;
    }
    
    for (int i = 0; i < pivotLen; i++) {
        FormEnum formEnum = frail.coocs(
            pivots,
            left, 
            right, 
            docFilter
        )
        .filter(tagFilter)
        .score(MI.JACCARD, pivots) // Jaccard or Dice are also quite good
        .sort(FormIterator.Order.SCORE);
        pivotCoocs[i] = formEnum;
        
    }
    // Nodes of the graph are pivots and most significant coocs of each 
    FormCollector nodes = new FormCollector();
    // insert pivots, to be sure to have them
    for (int i = 0; i < pivotLen; i++) {
        final int formId = pivots[i];
        pivotLookup.add(formId);
        final FormEnum coocEnum = pivotCoocs[i];
        nodes.put(formId, coocEnum.freq(formId), coocEnum.score(formId));
    }
    // merge the lists of node candidates
    boolean more = true;
    while (more) {
        int pivotRemain = pivotLen;
        // loop on each list and take one
        for (int i = 0; i < pivotLen; i++) {
            // enum nullified
            if (pivotCoocs[i] == null) continue;
            more = false;
            if (!pivotCoocs[i].hasNext()) continue;
            more = true;
            final int formId = pivotCoocs[i].next();
            if (pivotCoocs[i].freq() == 0) {
                // no more word in this Enum, nullify it
                pivotCoocs[i] = null;
                pivotRemain--;
                continue;
            }
            // pivot, let initial freq
            if (pivotLookup.contains(formId)) {
                
            }
            // new node
            else if (!nodes.contains(formId)) {
                final long freq = pivotCoocs[i].freq();
                nodes.put(formId, freq, pivotCoocs[i].score());
                continue;
            }
            // change nodeStats
            else {
                FormStats stats = nodes.get(formId);
                final long freq = stats.freq + pivotCoocs[i].freq();
                stats.freq = freq;
                // what to do with scores ? Are they additive ?
            }
        }
        if (pivotRemain < 1) break;
    }
    nodes.sort(FormIterator.Order.INSERTION, Math.min(nodeLimit, nodes.size()));
    nodeIds = nodes.sorter();
    matrix = frail.edges(pivots, left, right, nodeIds, docFilter);
    matrix.mi(MI.JACCARD);
    nodeEnum = nodes;
}
// no query, get words from corpus
else {
    edgeCoef = 2;
    // G score seems the best to get most significant words of a corpus
    nodeEnum = ftext.formEnum(docFilter, TagFilter.NOSTOP, Distrib.G);
    nodeEnum.sort(order, nodeLimit);
    nodeIds = nodeEnum.sorter();
    // nodeLimit = nodeEnum.limit(); // if less than requested
    matrix = frail.edges(nodeIds, left, right, nodeIds, docFilter);
    matrix.mi(MI.G);
}

// Collect the formIds in score order
int nodeIdMax = -1;
double nodeScoreMin = Double.MAX_VALUE;
double nodeScoreMax = Double.MIN_VALUE;
long freqMax = Long.MIN_VALUE;
long freqMin = Long.MAX_VALUE;
nodeEnum.reset();
while (nodeEnum.hasNext()) {
    nodeEnum.next();
    if (nodeEnum.formId() > nodeIdMax) nodeIdMax = nodeEnum.formId();
    final double score = nodeEnum.score();
    nodeScoreMax = Math.max(score, nodeScoreMax);
    nodeScoreMin = Math.min(score, nodeScoreMin);
    if (pivotLookup.contains(nodeEnum.formId())) {
        // do not keep freqMax of pivots
        continue;
    }
    final long freq = nodeEnum.freq();
    if (freq > freqMax) freqMax = freq;
    if (freq < freqMin) freqMin = freq;
}
//collect edges first, to hide orphan nodes
BitSet bros = new SparseFixedBitSet(nodeIdMax + 1);
// matrix.setMI(MI.OCCS); // set scorer for listing

out.println("{");

out.println("  \"edges\": [");
first = true;
int edgeCount = 0;
int edgeLimit = tools.getInt("edges", new int[]{20, 400}, (int)(nodeLimit * edgeCoef));
for (Edge edge : matrix) {
    if (edge.sourceId == edge.targetId) {
        continue;
    }
    final int sourceId = edge.sourceId;
    final int targetId = edge.targetId;
    double score = edge.count();
    if (Double.isNaN(score)) {
        // should be fixed
        continue;
    }
    // reduce size of radial edges
    if (pivotLookup.contains(sourceId) || pivotLookup.contains(targetId)) {
        // score = 1;
    }
    bros.set(edge.sourceId);
    bros.set(edge.targetId);
    if (first)
        first = false;
    else
        out.println(", ");
    out.print("    {\"id\":\"e" + (edgeCount) + "\""
    + ", \"size\":" + (score <= 0 ? 0.1 : score * 10) 
    + ", \"s\":\"" + ftext.form(sourceId).replace("\"", "\\\"") + "\""
    + ", \"t\":\"" + ftext.form(targetId).replace("\"", "\\\"") + "\""
    + ", \"source\":\"n" + sourceId + "\""
    + ", \"target\":\"n" + targetId + "\""
    // + ", \"color\":\"rgba(255, 255, 255, 0.3    )\""
    // for debug
    // + ", \"sourceOccs\":" + ftext.occs(sourceId) 
    // + ", \"targetOccs\":" + ftext.occs(targetId) 
    // + ", freq:" + freqList.freq()
    + "}");
    if (++edgeCount >= edgeLimit) {
        break;
    }
}
out.println("\n  ],");

out.println("  \"nodes\": [");
first = true;

int nodeCount = 0;

// initial position, as a spiral matrix
int spix = 0;
int spiy = 0;
int spidir = 3; // current direction; 0=RIGHT, 1=DOWN, 2=LEFT, 3=UP
int spiwidth = 0; // width of segment
int spicount = 0; // counter
int n = 1;
IntList orphans = new IntList();
double angle = Math.toRadians(-45);
final double rot = Math.toRadians(97);
nodeEnum.reset();
while (nodeEnum.hasNext()) {
    nodeEnum.next();
    final int formId = nodeEnum.formId();
    // orphan
    if (!bros.get(formId)) {
        orphans.push(formId);
        continue;
    }
    if (first) {
        first = false;
    } else {
        out.println(", ");
    }
    int tag = ftext.tag(formId);
    String type = Tag.name(tag);
    
    // score for size is not intuitive, freq() is better
    // but log is better
    double size = Math.sqrt(1 + nodeEnum.freq() - freqMin);
    if (q != null) size = nodeEnum.freq();
    // double alpha = 
    
    String color = "rgba(255, 255, 255, 1)";
    if (pivotLookup.contains(formId)) {
        size = freqMax;
        type = "pivot";
        
    }
    
    
    if (Tag.NAME.sameParent(tag)) {
        color = "#cf1408"; // ddr_red
    }
    else if (Tag.SUB.flag() == tag) {
        color = "#000";
    }
    else if (Tag.ADJ.flag() == tag) {
        color = "#008";
    }
    /*
    else if (Tag.VERB.sameParent(tag)) {
        color = "rgba(0, 0, 0, 0.7)";
    }
    */
    else  {
        color = "#888";
    }
    // if (node.type() == STAR) color = "rgba(255, 0, 0, 0.9)";
    // else if (Tag.isVerb(tag)) color = "rgba(0, 0, 0, 1)";
    // else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
    // else color = "rgba(159, 183, 159, 1)";
    // {id:\"n204\", label:\"coeur\", x:-16, y:99, size:86, color:\"hsla(0, 86%, 42%, 0.95)\"},
    final int x = spix * 15;
    final int y = spiy * 10;
    switch (spidir) {
        case 0: spix = spix + 1; break;
        case 1: spiy = spiy + 1; break;
        case 2: spix = spix - 1; break;
        case 3: spiy = spiy - 1; break;
    }
    if (++spicount >= spiwidth) {
        spicount = 0;
        spidir = (spidir + 1)%4;
        if (spidir == 0 || spidir == 2) spiwidth = spiwidth + 1;
        
    }
    /* bad for Atlas2
    final int x = (int)(size * 150.0 * Math.cos(angle));
    final int y = (int)(size * 100.0 * Math.sin(angle));
    angle = angle + rot;
    */
    out.print("    {\"id\":\"n" + formId + "\"");
    out.print(", \"label\":\"" + ftext.form(formId).replace("\"", "\\\"") + "\"");
    out.print(", \"size\":" + size); // node.count
    out.print(", \"x\":" + x + ", \"y\":" + y);
    out.print(", \"color\":\"" + color + "\"");
    out.print(", \"type\":\"" + type + "\"");
    out.print("}");
    // if nodes are limited here, edges may not have nodes
    // if (++nodeCount >= nodeLimit)  break;
    // spiral matrix placement, works but not ideal
    n++;
}
out.println("\n  ],");
if (!orphans.isEmpty()) {
    first = true;
    out.println("  \"orphans\":[");
    for (int i = 0, max = orphans.size(); i < max; i++) {
        final int formId = orphans.get(i);
        if (first) {
            first = false;
        }
        else {
            out.println(",");
        }
        out.print("    {\"form\":\""+ ftext.form(formId).replace("\"", "\\\"") + "\"}");
    }
    out.println("\n  ],");
}
out.println("  \"time\": \"" + ((System.nanoTime() - timeStart) / 1000000) + "ms\"");
out.println("}");
%>



