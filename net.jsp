<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.io.StringReader" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.nio.file.Files" %>
<%@ page import="java.nio.file.StandardOpenOption" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.util.List" %>

<%@ page import="org.apache.lucene.analysis.Analyzer" %>
<%@ page import="org.apache.lucene.analysis.TokenStream" %>
<%@ page import="org.apache.lucene.analysis.Tokenizer" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.CharTermAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.FlagsAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.OffsetAttribute" %>

<%@ page import="alix.lucene.analysis.CharsNet" %>
<%@ page import="alix.lucene.analysis.CharsNet.Node" %>
<%@ page import="alix.lucene.analysis.CharsNet.Edge" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsAtt" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsLemAtt" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsOrthAtt" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.fr.Tag.TagFilter" %>
<%@ page import="alix.util.Dir" %>
<%@ page import="alix.util.IntPair" %>


<%!
/*
      <form id="form" style="position: absolute; z-index: 2;">
        <input name="term" value="conscience"/>
        <label onchange="this.form.submit()">Locutions <input name="loc" type="checkbox" /></label>
      </form>
*/
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8"/>
    <title>Graphe de texte</title>
    <script src="vendor/sigma/sigma.min.js">//</script>
    <script src="vendor/sigma/sigma.plugins.dragNodes.js">//</script>
    <script src="vendor/sigma/sigma.exporters.image.js">//</script>
    <script src="vendor/sigma/sigma.plugins.animate.js">//</script>
    <script src="vendor/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="vendor/sigma/sigma.layout.forceAtlas2.js">//</script>
    <script src="vendor/sigma/sigma.layout.noverlap.js">//</script>
    <script src="static/sigmot.js">//</script>
    <style>
html, body {
  height: 100%; 
  margin: 0;
}
body {
  background: #000;
  font-family: sans-serif;
}
#graph {
  height:90%;
  width:90%;
  resize:both;
  border: 1px solid #FFF;
  overflow: hidden;
  margin-left: auto;
  margin-right: auto;
}
.butbar button {
  cursor: pointer;
  display: inline-block;
  border: none;
  width: 2.5rem;
  margin: 0;
  text-decoration: none;
  background: #FFFFFF;
  color: #000000;
  font-family: sans-serif;
  font-size: 1.3rem;
  text-align: center;
  transition: background 250ms ease-in-out, transform 150ms ease;
  /*
  -webkit-appearance: none;
  -moz-appearance: none;
  */
}
    </style>
  </head>
  <body>
  <%

Analyzer analyzer = alix.analyzer();
int width = tools.getInt("width", 20);
int density = tools.getInt("density", 5);
int words = tools.getInt("words", 200);


List<File> ls = Dir.ls("/home/fred/code/ddr-test/ddr1977aena*\\.xml");
TagFilter tagfilter = new TagFilter()
  .setGroup(Tag.SUB).setGroup(Tag.ADJ)
//  .setGroup(Tag.VERB).clear(Tag.VERBaux).clear(Tag.VERBsup)
  .setGroup(Tag.NAME).set(Tag.NULL)
;
CharsNet net = new CharsNet(width, false);
TokenStream stream;
for (File entry : ls) {
  Path path = entry.toPath();
  String text = Files.readString(path);
  // text = "<p>Au train où elle va, l’humanité court vers sa perte programmée. Mais le chemin de fer d'intérêt local, dans son écrasante majorité, elle ne veut pas le savoir";
  stream = analyzer.tokenStream("cloud", new StringReader(text));
  
  // get the CharTermAttribute from the TokenStream
  CharsAtt term = (CharsAtt)stream.addAttribute(CharTermAttribute.class);
  CharsAtt orth = (CharsAtt)stream.addAttribute(CharsOrthAtt.class);
  CharsAtt lem = (CharsAtt)stream.addAttribute(CharsLemAtt.class);
  FlagsAttribute flags = stream.addAttribute(FlagsAttribute.class);
  OffsetAttribute offsets = stream.addAttribute(OffsetAttribute.class);
  
  stream.reset();
  while (stream.incrementToken()) {
    /*
    out.println(
      "<li>"
      + term 
      + "\t" + orth  
      + "\t" + Tag.label(flags.getFlags())
      + "\t" + lem  
      + " |" + text.substring(offsets.startOffset(), offsets.endOffset()) + "|"
      + "</li>"
    );
    */

    int tag = flags.getFlags();
    if (FrDics.isStop(orth)) continue;
    if (Tag.isVerb(tag)) continue;
    
    
    // if (!tagfilter.accept(tag)) continue;
    if (lem.length() > 0) net.inc(lem, tag);
    else if (orth.length() > 0) net.inc(orth, tag);
    else net.inc(term, tag);
  }
%>
  
    <div id="graph" class="graph" oncontextmenu="return false" style="position:relative; ">
      <form id="form" style="position: absolute; z-index: 2;">
        <label title="Nombre de mots à afficher">nœuds <input name="words" value="<%= words %>" size="3"/></label>
        <label title="Nombre de mots reliés">fenêtre <input name="width" value="<%= width %>" size="2"/></label>
        <label title="Densité de liens">densité <input name="density" value="<%= density %>"  size="2"/></label>
        <button type="submit">O</button>
      </form>
      <div class="butbar" style="position: absolute; bottom: 0; right: 2px; z-index: 2; ">
        <button class="zoomout but" type="button" title="Diminuer">–</button>
        <button class="zoomin but" type="button" title="Grossir">+</button>
        <button class="fontdown but" type="button" title="Diminuer le texte">S↓</button>
        <button class="fontup but" type="button" title="Grossir le texte">S↑</button>
        <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
        <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
        <button class="shot but" type="button" title="Prendre une photo">📷</button>
        <!--
        <button class="colors but" type="button" title="Gris ou couleurs">◐</button>
        <button class="but restore" type="button" title="Recharger">O</button>
      -->
        <button class="mix but" type="button" title="Mélanger le graphe">♻</button>
        <button class="FR but" type="button" title="Spacialisation Fruchterman Reingold">☆</button>
        <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button>
        <button class="atlas2 but" type="button" title="Démarrer ou arrêter la gravité atlas 2">►</button>
        <!--
        <span class="resize interface" style="cursor: se-resize; font-size: 1.3em; " title="Redimensionner la feuille">⬊</span>
        -->
      </div>
    </div>
   <script>
<%
  boolean first;
  int max;

  
  Node[] nodes = net.nodes();
  java.util.BitSet nodeset = new java.util.BitSet(nodes.length);
  out.println("var data = {");

  max = Math.min(words, nodes.length);
  out.println("  nodes: [");
  first = true;
  for (int i = 0; i < max; i++) {
    Node node = nodes[i];
    nodeset.set(node.id());
    if (first) first = false;
    else out.println(", ");
    String color = "rgba(64, 64, 64, 0.5)";
    if (Tag.isSub(node.tag())) color = "rgba(255, 255, 255, 1)";
    else if (Tag.isName(node.tag())) color = "rgba(255, 0, 0, 1)";
    else if (Tag.isVerb(node.tag())) color = "rgba(0, 0, 128, 0.5)";
    else if (Tag.isAdj(node.tag())) color = "rgba(128, 128, 255, 1)";
    // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
    out.print("    {id:'n" + node.id() + "', label:'" + node.label().toString().replace("'", "\\'") + "', size:" + dfdec2.format(10 * Math.sqrt(node.count())) // node.count()
    + ", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) 
    + ", color:'" + color + "'"
    + "}");
  }
  out.println("\n  ],");

  
  Edge[] edges = net.edges();
  out.println("  edges: [");
  
  int[] nodeCounts = new int[nodes.length];
  
  first = true;
  max = edges.length;
  for (int i = 0; i < max; i++) {
    Edge edge = edges[i];
    if (!nodeset.get(edge.source())) continue;
    if (!nodeset.get(edge.target())) continue;
    // if ((nodeCounts[edge.source()]+ nodeCounts[edge.target()]) >= density) continue;
    if (nodeCounts[edge.source()] >= density) continue;
    if (nodeCounts[edge.target()] >= density) continue;
    nodeCounts[edge.target()]++;
    nodeCounts[edge.source()]++;
    
    if (first) first = false;
    else out.println(", ");
    // out.println(edge);
    // {id:'e384606', source:'n907', target:'n4225', size:4, color:'rgba(192, 192, 192, 0.4)', type:'halo'}
    out.print("    {id:'e" + edge.id() + "', source:'n" + edge.source() + "', target:'n" + edge.target() + "', size:" + edge.count() 
    + ", color:'rgba(128, 128, 128, 0.3)'"
    + "}");
  }
  out.println("\n  ]");


  out.println("}");

}

%>
var graph = new sigmot('graph', data);
    </script>
  </body>
</html>