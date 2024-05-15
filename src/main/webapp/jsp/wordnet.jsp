<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp" %>
<%@ page import="alix.util.Edge" %>
<%@ page import="alix.util.EdgeSquare" %>

<%!/**
 * Frequent words linked by co-occurrence
 */%>
<%
out.println("var data = {");
// global data handlers
String field = pars.field.name();
final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);
boolean first;
// define patition
Corpus corpus = null;
BitSet filter = null;
if (pars.book != null) {
    final int bookid = alix.getDocId(pars.book);
    if (bookid < 0)
        pars.book = null;
    else
        filter = Corpus.bits(alix, Names.ALIX_BOOKID, new String[] { pars.book });
}
// collect nodes 
int nodeLen = tools.getInt("nodes", 50);

FormEnum nodes = ftext.forms(filter, pars.cat.tags(), OptionDistrib.BM25);
nodes.sort(pars.order.order(), nodeLen);
nodeLen = nodes.limit(); // if less than requested
// Collect the formIds
int[] formIds = new int[nodeLen];

out.println("  nodes: [");
first = true;
nodes.reset();
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
    String color = "rgba(0, 0, 0, 1)";
    if (Tag.SUB.sameParent(tag)) color = "rgba(255, 255, 255, 0.9)";
    else if (Tag.VERB.sameParent(tag)) color = "rgba(0, 0, 0, 0.8)";
    else if (Tag.NAME.sameParent(tag)) color = "rgba(207, 19, 8, 0.8)";
    else if (Tag.ADJ.sameParent(tag)) color = "rgba(160, 160, 160, 1)";
    // if (node.type() == STAR) color = "rgba(255, 0, 0, 0.9)";
    // else if (Tag.isVerb(tag)) color = "rgba(0, 0, 0, 1)";
    // else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
    // else color = "rgba(159, 183, 159, 1)";
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    double size = nodes.freq();
    out.print("    {id:'n" + formId + "', label:'" + ftext.form(formId).replace("'", "\\'") + "', size:" + size); // node.count
    out.print(", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) );
    out.print(", color:'" + color + "'");
    out.print("}");
}
out.println("\n  ],");

 // build edges
EdgeSquare edges =  frail.edges(formIds, pars.dist, filter);
out.println("  edges: [");
first = true;
int edgeCount = 0;
for (Edge edge: edges) {
    if (edge.source == edge.target) {
        continue;
    }
    final double score = edge.score();
    // seen but not explained
    if (Double.isNaN(score)) continue;
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



