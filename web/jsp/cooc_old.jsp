<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp" %>
<%@ page import="java.util.Iterator" %>

<%@ page import="alix.util.EdgeHash" %>
<%@ page import="alix.util.Edge" %>


<%!private double count(FormEnum results, int formId, OptionOrder order)
{
    switch (order) {
        case SCORE:
            return results.score(formId);
        case hits:
            return results.hits(formId);
        case FREQ:
            return results.freq(formId);
        default:
            return results.occs(formId);
    }

}%>
<%
final double radialWeight = 0.1; // lightnimg radial
// final int edgeMax = 4; // may become parameter
out.println("var data = {");
out.println("  right: " + pars.right +",");
out.println("  left: " + pars.left +",");
// global data handlers
String field = pars.field.name();
final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);

// for each requested forms, get co-occurences stats
String[] forms = alix.tokenize(pars.q, pars.field.name());
if (forms == null || forms.length < 1) {
    out.println("    'error': 'Aucun mot demandé.'");
    out.println("}");
    return;
}
// Todo, get here corpus filter
Corpus corpus = null;
BitSet filter = null;
if (pars.book != null) {
    final int bookid = alix.getDocId(pars.book);
    if (bookid < 0)
        pars.book = null;
    else
        filter = Corpus.bits(alix, Alix.BOOKID, new String[] { pars.book });
}

int[] formIds = ftext.formIds(forms, filter);
if (formIds == null) {
    if (filter != null) {
        out.println("    'error': 'Mots introuvables pour le corpus");
    } 
    else {
        out.println("'error': 'Mots introuvables'");
    }
    out.println("}");
    return;
}
int formCount = formIds.length;
//normalize forms
for (int i =0; i < formCount; i++) {
    forms[i] = ftext.form(formIds[i]);
}
pars.left = tools.getInt("left", 50);
pars.right = tools.getInt("right", 50);
boolean first;



// for each term, collect freqlist
FormEnum[] stats = new FormEnum[formCount];
for (int i = 0; i < formCount; i++) {
    // build a freq list for coocs
    FormEnum results = new FormEnum(ftext);
    results.filter = filter; // corpus filter
    results.left = pars.left; // left context
    results.right = pars.right; // right context
    results.tags = pars.cat.tags(); // filter word list by tags
    // set the word
    results.search = new String[]{forms[i]};
    // record edges
    results.edges();
    long found = frail.coocs(formIds, results); // populate the wordlist
    // sort coocs by score 
    if (pars.order == OptionOrder.SCORE) {
        // calculate score
        frail.score(formIds, results);
    }
    results.sort(pars.order.order());
    stats[i] = results;
}

// record radial edges
Map<Edge, Double> edges =  new HashMap<>();
// default, ensure light edges between pivots
for (int i = 0; i < formCount; i++) {
    for (int j = 1 + 1; j < formCount; j++) {
        // false = undirected
        double value = 0;
        final Edge edge = new Edge(formIds[i], formIds[j], value, false);
        edges.put(edge, value);
    }
}
//load nodes, and set their score
Map<Integer, Double> nodes = new HashMap<Integer, Double>();
double nodeMin = Double.MAX_VALUE;
double nodeMax = Double.MIN_VALUE;
int nodeCount = 0;
int mark = 0;
while (nodeCount < pars.nodes) {
    FormEnum results = stats[mark];
    // if no more form in this freqList, stop here
    if (!results.hasNext()) {
        break;
    }
    results.next();
    final int source = formIds[mark];
    int formId = results.formId();
    // ensure radial edge bteween pivots and planets
    if (source != formId) {
    	final Edge edge = new Edge(source, formId, 0, false);
        double value = (long)(results.freq() * radialWeight);
        Double edgeCount = edges.get(edge);
        if (edgeCount != null) {
    value = value + edgeCount;
        }
        edges.put(edge, value);
    }
    // node already recorded update its score 
    if (nodes.containsKey(formId)) {
        Double score = nodes.get(formId);
        if (score == Double.MIN_VALUE) { // is pivot
    continue;
        }
        // cooc shared
        score += results.score();
        if (score < nodeMin) {
    nodeMin = score;
        }
        if (score > nodeMax) {
    nodeMax = score;
        }
        nodes.put(formId, score);
        continue;
    }
    // new node
    nodeCount++;
    mark++; // pass to next results
    if (mark == formCount) {
        mark = 0;
    }
    // a pivot ?
    boolean found = false;
    for (String word: forms) {
        // is a pivot, no score
        if (word.equals(results.form())) {
    nodes.put(formId, Double.MIN_VALUE);
    found = true;
    break;
        }
    }
    if (found) {
        continue;
    }
    // min-max size of nodes keps
    double count = count(results, results.formId(), pars.order);
    if (count < nodeMin) {
        nodeMin = count;
    }
    if (count > nodeMax) {
        nodeMax = count;
    }
    // not a pivot record score
    nodes.put(formId, count);
}

// show nodes
out.println("  nodes: [");
first = true;
for (Map.Entry<Integer, Double> entry : nodes.entrySet()) {
    // if (entry.getValue() < 1) continue;
    int formId = entry.getKey();
    
    if (first) first = false;
    else out.println(", ");
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
    double size = entry.getValue();
    // pivot medium size
    if (size == Double.MIN_VALUE) {
        size = nodeMin + (nodeMax - nodeMin) / 2;
    }
    out.print("    {id:'n" + formId + "', label:'" + ftext.form(formId).replace("'", "\\'") + "', size:" + size); // node.count
    out.print(", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) );
    out.print(", color:'" + color + "'");
    // is a pivot
    if (entry.getValue() < 1) out.print(", type:'hub'");
    out.print("}");
}
out.println("\n  ],");

//collect edges, check duplicate
Iterator<Edge>[] its = new Iterator[formCount];
for (int i = 0; i < formCount; i++) {
    its[i] = stats[i].edges().iterator();
}
// reloop on nodes to use map as an edge count recorder (except for pivots)
for (Integer nodeId: nodes.keySet()) {
    if (nodes.get(nodeId) == Double.MIN_VALUE) {
        continue;
    }
    nodes.put(nodeId, 0.0);
}
int edgeCount = 0;
mark = 0;
while (edgeCount < pars.edges) {
    Iterator<Edge> it = its[mark];
    if (!it.hasNext()) {
        break;
    }
    Edge edge = it.next();
    // get count of edges for each node
    Double srcEdges = nodes.get(edge.source);
    Double tgtEdges = nodes.get(edge.target);
    // these nodes are not waited
    if (srcEdges == null) {
        continue;
    }
    if (tgtEdges == null) {
        continue;
    }
    // limit number of edges by nodes ?
    /*
    if (srcEdges > edgeMax && tgtEdges > edgeMax) {
        continue;
    }
    */
    double score = edge.score();
    // Is a radial, do something ?
    if (tgtEdges == Double.MIN_VALUE || srcEdges == Double.MIN_VALUE) {
        continue;
    }
    // Source is not a pivot word, count edge
    nodes.put(edge.source, srcEdges + 1);
    nodes.put(edge.target, tgtEdges + 1);
    edgeCount++;
    mark++; // pass to next results
    if (mark == formCount) {
        mark = 0;
    }
    Double old = edges.get(edge);
    if (old != null && score != 0) {
    	score += old;
    }
    edges.put(edge, score);
    
}
out.println("  edges: [");
first = true;
int edgeId = 0;
for (Map.Entry<Edge, Double> entry : edges.entrySet()) {
    edgeId++;
    Edge edge = entry.getKey();
    double value = entry.getValue();
    if (first) first = false;
    else out.println(", ");
    out.print("    {id:'e" + (edgeId) + "', source:'n" + edge.source + "', target:'n" + edge.target + "', size:" + (value<=0?0.1:value) 
    + ", color:'rgba(128, 128, 128, 0.2)'"
    // for debug
    // + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
}
out.println("\n  ],");
out.println("  time: '" + ( (System.nanoTime() - time) / 1000000) + "ms'");
out.println("};");
%>



