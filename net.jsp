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
<%@ page import="alix.util.IntList" %>
<%@ page import="alix.util.IntPair" %>


<%!
private final int STAR = 1;
private final int NOVA = 2;
private final int PLANET = -1;
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
    <link rel="stylesheet" type="text/css" href="static/ddrlab.css"/>
    <style>
html, body {
  height: 100%; 
  margin: 0;
}
body {
  background-color: #666;
  font-family: sans-serif;
  color: #fff;
}
#graphcont {
  display: flex;
  flex-direction: column;
  height:100%;
}
#graph {
  position: relative;
  flex-grow: 4;
  width: 100%;
  border: none;
  overflow: hidden;
  margin-left: auto;
  margin-right: auto;
}
#form {
  display: flex;
  align-items: center;
}
#form label {
  margin-left: 1rem;
  margin-right: 0.2rem;
}

#form .elastic {
  flex-grow: 4;
}
#form .elastic input {
  width: 100%;
}

input.nb {
  text-align: right;
  width: 3rem;
}
.butbar {
  text-align: right;
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
boolean first;


Analyzer analyzer = alix.analyzer();
String glob = tools.getString("glob", "ddr1977aena*");
final int ntopmid = 10;
final int ntopmax = 50;
int ntop = tools.getInt("words", -1);
if (ntop > ntopmax) ntop = ntopmax;
String words = tools.getString("words", null);
int width = tools.getInt("width", 20);
int planets = tools.getInt("planets", 50);

String files = "/var/www/html/critique/bergson/*.xml";
// String files = "/var/www/html/ddr-livres/"+glob+".xml";
List<File> ls = Dir.ls(files);
TagFilter tagfilter = new TagFilter()
  .setGroup(Tag.SUB).setGroup(Tag.ADJ)
  .setGroup(Tag.VERB).clear(Tag.VERBaux).clear(Tag.VERBsup)
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
    
    
    if (!tagfilter.accept(tag)) continue;
    if (lem.length() > 0) net.inc(lem, tag);
    else if (orth.length() > 0) net.inc(orth, tag);
    else net.inc(term, tag);
  }
}
Edge[] edgesAll = net.edges();
Node[] nodesAll = net.nodes();
//the focus nodes

StringBuilder sb = new StringBuilder();
if (words != null) {
  first = true;
  int count = 0;
  for (String w: words.split("\\s*[\n,;]\\s*")) {
    Node node = net.node(w);
    if (node == null) continue;
    node.type(STAR);
    if (first) first = false;
    else sb.append(", ");
    sb.append(node.label());
    if (++count >= ntopmax) break;
  }
  if (count > 0) words = sb.toString();
  else words = null;
}

if (words == null) {
  if (ntop < 1) ntop = ntopmid;
  first = true;
  int count = 0;
  for (int i = 0; i < nodesAll.length; i++) {
    Node node = nodesAll[i];
    if (Tag.isAdj(node.tag())) continue;
    node.type(STAR);
    if (first) first = false;
    else sb.append(", ");
    sb.append(node.label());
    if (++count >= ntop) break;
  }
  words = sb.toString();
}



%>
	  <div id="graphcont">
       <form id="form">
         <label for="glob">livre </label>
         <input name="glob" value="<%= glob %>" size="5"/>
         <label for="words">pivots </label>
         <div class="elastic">
           <input name="words" value="<%= words %>" size="100"/>
         </div>
         <label for="width">fenêtre </label>
         <input name="width" value="<%= width %>" class="nb" size="2"/>
         <label for="planets">rayons </label>
         <input name="planets" value="<%= planets %>" class="nb" size="2"/>
         <button type="submit">O</button>
       </form>
	    <div id="graph" class="graph" oncontextmenu="return false">
	    </div>
       <div class="butbar">
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
int max;

out.println("var data = {");

out.println("  edges: [");
// loop on all edges to select nmax edges by star
max = edgesAll.length;
java.util.BitSet nodeset = new java.util.BitSet(net.nodecount());
first = true;
for (int i = 0; i < max; i++) {
  final Edge edge = edgesAll[i];
  final Node source = edge.source();
  final Node target = edge.target();
  if (source.type() != STAR  && target.type() != STAR) continue;
  if (source.type() == NOVA || target.type() == NOVA) continue;
  if (source.type() == STAR) {
    if (source.counterInc() >= planets) source.type(NOVA);
  }
  else {
    source.type(PLANET);
  }
  if (target.type() == STAR) {
    if (target.counterInc() >= planets) target.type(NOVA);
  }
  else {
    target.type(PLANET);
  }
  nodeset.set(source.id());
  nodeset.set(target.id());
  if (first) first = false;
  else out.println(", ");
  out.print("    {id:'e" + edge.id() + "', source:'n" + source.id() + "', target:'n" + target.id() + "', size:" + edge.size() 
  + ", color:'rgba(0, 0, 0, 0.3)'"
  + "}");
}
out.println("\n  ],");




  // 
  
  
  
 out.println("  nodes: [");
 first = true;
 for (int i = nodeset.nextSetBit(0); i >= 0; i = nodeset.nextSetBit(i+1)) {
   Node node = net.node(i);
   if (first) first = false;
   else out.println(", ");
   String color = "rgba(200, 200, 255, 1)";
   if (node.type() == STAR || node.type() == NOVA) color = "rgba(255, 0, 0, 1)";
   else if (Tag.isSub(node.tag())) color = "rgba(255, 255, 255, 1)";
   else if (Tag.isName(node.tag())) color = "rgba(0, 255, 0, 1)";
   // else if (Tag.isVerb(node.tag())) color = "rgba(0, 0, 128, 0.5)";
   // else if (Tag.isAdj(node.tag())) color = "rgba(128, 128, 255, 1)";
   // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
   out.print("    {id:'n" + node.id() + "', label:'" + node.label().toString().replace("'", "\\'") + "', size:" + dfdec2.format(10 * Math.sqrt(node.size())) // node.count()
   + ", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) 
   + ", color:'" + color + "'"
   + "}");
 }
 out.println("\n  ]");

  


 out.println("}");


%>
var graph = new sigmot('graph', data);
    </script>
  </body>
</html>