<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="alix.util.EdgeSquare" %>
<%@ page import="alix.util.Edge" %>


<%!private double count(FormEnum results, int formId, OptionOrder order)
{
    switch (order) {
        case SCORE:
            return results.score(formId);
        case HITS:
            return results.hits(formId);
        case FREQ:
            return results.freq(formId);
        default:
            return results.occs(formId);
    }

}%>
<%
pars.q = tools.getString("q", "personne individu");
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
        filter = Corpus.bits(alix, Names.ALIX_BOOKID, new String[] { pars.book });
}

int[] pivotIds = ftext.formIds(forms, filter);
if (pivotIds == null) {
    if (filter != null) {
        out.println("    'error': 'Mots introuvables pour le corpus");
    } 
    else {
        out.println("'error': 'Mots introuvables'");
    }
    out.println("}");
    return;
}
Arrays.sort(pivotIds); // sort pivots to make it esier to found later
int pivotLen = pivotIds.length;


//normalize forms
for (int i =0; i < pivotLen; i++) {
    forms[i] = ftext.form(pivotIds[i]);
}
boolean first;



// for each pivot word, we need a separate word list, with separate scoring
FormEnum[] stats = new FormEnum[pivotLen];
for (int i = 0; i < pivotLen; i++) {
    int[] pivotx = new int[]{pivotIds[i]};
    // build a freq list for coocs
    FormEnum results = ftext.forms();
    results.limit = pars.nodes;
    results.filter = filter; // corpus filter
    results.tags = pars.cat.tags(); // filter word list by tags
    // DO NOT record edges here
    long found = frail.coocs(results, pivotIds, pars.left, pars.right, OptionMI.G); // populate the wordlist
    results.sort(pars.order.order());
    stats[i] = results;
}


// load nodes, and set their score
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
    final int pivotId = pivotIds[mark];
    int formId = results.formId();
    boolean isPivot = false;
    // a pivot ?
    if (Arrays.binarySearch(pivotIds, formId) >= 0) {
        isPivot = true;
        nodes.put(formId, Double.MIN_VALUE);
        continue;
    }
    // min-max size of nodes keps
    double count = count(results, formId, pars.order);
    // out.println(nodeCount+". "+ftext.form(pivotId)+"--"+ftext.form(formId)+" (" + count + ")");
    // node already recorded update its score 
    if (nodes.containsKey(formId)) {
        Double score = nodes.get(formId);
        // cooc shared
        score += count;
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
    if (mark == pivotLen) {
        mark = 0;
    }
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
int[] nodeIds = new int[nodes.size()];
int nodeIndex = 0;
out.println("  nodes: [");
first = true;
int hub = 0;
for (Map.Entry<Integer, Double> entry : nodes.entrySet()) {
    // if (entry.getValue() < 1) continue;
    int formId = entry.getKey();
    nodeIds[nodeIndex] = formId;
    nodeIndex++;
    if (first) first = false;
    else out.println(", ");
    int tag = ftext.tag(formId);
    String color = "rgba(0, 0, 0, 1)";
    if (Tag.SUB.sameParent(tag)) color = "rgba(255, 255, 255, 0.9)";
    else if (Tag.VERB.sameParent(tag)) color = "rgba(0, 0, 0, 0.8)";
    else if (Tag.NAME.sameParent(tag)) color = "rgba(207, 19, 8, 0.8)";
    else if (Tag.ADJ.sameParent(tag)) color = "rgba(160, 160, 160, 1)";
    // if (node.type() == STAR) color = "rgba(255, 0, 0, 0.9)";
    // else if (Tag.isVerb(tag)) color = "rgba(0, 0, 0, 1)";
    // else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    double size = entry.getValue();
    // pivot medium size
    if (size == Double.MIN_VALUE) {
        size = nodeMin + (nodeMax - nodeMin) / 2;
    }
    out.print("    {id:'n" + formId + "', label:'" + ftext.form(formId).replace("'", "\\'") + "', size:" + size); // node.count
    
    out.print(", color:'" + color + "'");
    // is a pivot
    if (entry.getValue() < 1) {
        out.print(", type:'hub'");
        if (pivotLen == 1) {
    out.print(", x:" + 50 + ", y:" + 50 );
        }
        else if (hub < 8) {
    final int[] xx = new int[]{0, 100, 50, 50, 0, 100, 100, 0};
    final int[] yy = new int[]{50, 50, 0,  100, 0, 100, 0, 100};
    out.print(", x:" + xx[hub] + ", y:" + yy[hub] );
        }
        else {
    out.print(", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) );
        }
        hub++;
    }
    else {
        out.print(", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) );
    }
    out.print("}");
}
out.println("\n  ],");

// build edges
EdgeSquare edges = frail.edges(pivotIds, pars.left, pars.right, nodeIds, filter);
out.println("  edges: [");
first = true;
int edgeCount = 0;
for (Edge edge: edges) {
    if (edge.source == edge.target) {
        continue;
    }
    final double score = edge.score();
    if (first) first = false;
    else out.println(", ");
    out.print("    {id:'e" + (edgeCount) + "', source:'n" + edge.source + "', target:'n" + edge.target + "', size:" + (score<=0?0.1:score * 100) 
    + ", color:'rgba(192, 192, 192, 0.2)'"
    // for debug
    // + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
    if (++edgeCount >= pars.edges) {
        break;
    }
}
out.println("\n  ],");
out.println("  time: '" + ( (System.nanoTime() - time) / 1000000) + "ms'");
out.println("};");
%>



