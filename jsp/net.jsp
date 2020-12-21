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
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.TreeSet" %>

<%@ page import="org.apache.lucene.analysis.Analyzer" %>
<%@ page import="org.apache.lucene.analysis.TokenStream" %>
<%@ page import="org.apache.lucene.analysis.Tokenizer" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.CharTermAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.FlagsAttribute" %>
<%@ page import="org.apache.lucene.analysis.tokenattributes.OffsetAttribute" %>
<%@ page import="org.apache.lucene.util.BytesRef" %>

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


<%!/** most significant words, no happax (could bug for smal texts) */
static private int FREQ_FLOOR = 5;
/** default number of focus on load */
static int hubsDefault = 15;

/** most semantic words, filter by pos */
private final static TagFilter tagSem = new TagFilter();
static {
  tagSem.setGroup(Tag.ADJ);
  // tagSem.setAdj();
}


private final int STAR = 1;
private final int NOVA = 2;
private final int PLANET = -1;

public static TopArray top(FieldText fstats, final int pivotId, final long[] cooc, int limit, final Distance distance)
{
  TopArray top = new TopArray(limit);
  for (int termId = 0, length = cooc.length; termId < length; termId++) {
    if (fstats.isStop(termId)) continue; // sauter les mots vides
    long m11 = cooc[termId];
    long m10 = fstats.occs(termId) - m11;
    long m01 = fstats.occs(pivotId) - m11;
    // TODO, should be the sub corpus filtered total occs
    long m00 = fstats.occsAll;
    double score = distance.score(m11, m10, m01, m00);
    top.push(termId, score);
  }
  return top;
}


static class Node implements Comparable<Node>
{
  /** persistent id */
  private int id;
  /** persistent label */
  private String label;
  /** persistent tag from source  */
  // private final int tag;
  /** growable size */
  private long count;
  /** mutable type */
  private int type;
  /** a counter locally used */
  private double score;
  
  public Node(final int termId, final String label)
  {
    this.label = label;
    this.id = termId;
  }
  
  public Node type(final int type)
  {
    this.type = type;
    return this;
  }

  public Node id(final int id)
  {
    this.id = id;
    return this;
  }

  public Node count(final long count)
  {
    this.count = count;
    return this;
  }
  
  public int compareTo(Node o)
  {
    return Integer.compare(this.id, o.id);
  }
  @Override
  public boolean equals(Object o)
  {
    if (o == null) return false;
    if (!(o instanceof Node)) return false;
    return (this.id == ((Node)o).id);
  }
  
  @Override
  public String toString()
  {
    StringBuilder sb = new StringBuilder();
    sb.append(id).append(":").append(label).append(" (").append(type).append(", ").append(count).append(")");
    return sb.toString();
  }
}

/*
      <form id="form" style="position: absolute; z-index: 2;">
        <input name="term" value="conscience"/>
        <label onchange="this.form.submit()">Locutions <input name="loc" type="checkbox" /></label>
      </form>
*/%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8"/>
    <title>Graphe de texte</title>
    <script src="<%=hrefHome%>vendor/sigma/sigma.min.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.dragNodes.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.exporters.image.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.animate.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.forceAtlas2.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.noverlap.js">//</script>
    <script src="<%=hrefHome%>static/sigmot.js">//</script>
    <script src="<%=hrefHome%>static/ddrlab.js">//</script>
    <link rel="stylesheet" type="text/css" href="<%=hrefHome%>static/ddrlab.css"/>
    <style>
html, body {
  height: 100%; 
  margin: 0;
}
body {
  background-color: #666;
}
body,
h1 {
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
    final String fieldName = "text";
      boolean first;
      final int ntopmax = 50;
      int ntop = tools.getInt("words", hubsDefault);
      if (ntop < 1) ntop = hubsDefault;
      else if (ntop > ntopmax) ntop = ntopmax;
      String words = tools.getString("words", null);
      int width = tools.getInt("width", 10, baseName+"Width");
      if (width < 3) width = 3;
      
      final int planetMax = 50;
      final int planetMid = 10;
      int planets = tools.getInt("planets", planetMid, baseName+"Planets");
      if (planets > planetMax) planets = planetMax;
      if (planets < 1) planets = planetMid;

      BitSet filter = null;
      Corpus corpus = (Corpus)session.getAttribute(corpusKey);
      if (corpus != null) filter = corpus.bits();
      
      FieldText fstats = alix.fieldStats(fieldName);
      Rail rail = alix.rail(fieldName);
      long[] freqs = rail.freqs(filter); // term frequencies for this query
      BytesRef bytes = new BytesRef();

      Distance distance = (Distance)tools.getEnum("distance", Distance.none, baseName+"Distance");


      // if we add nodes here, we wil have to take a copy of the 
      ArrayList<String> alist = new ArrayList<String>();
      // get the focus nodes from query
      if (words != null) {
    String[] terms = alix.qAnalyze(words); // parse query as a set of terms
    first = true;
    int count = 0;
    // rewrite queries, with only known terms
    for (String w: terms) {
      int termId = fstats.termId(w);
      if (termId < 0) continue;
      long freq = freqs[termId];
      if (freq < 1) continue;
      if (first) first = false;
      alist.add(w);
      if (++count >= ntopmax) break;
    }
    if (alist.size() > 0) {
    }
    
      }
      // if no nodes found, get the first non stop word for the field
      // filter for the corpus
      if (alist.size() < 1) {
    TopArray top = new TopArray(ntop);
    CharsAtt chars = new CharsAtt();
    for (int termId = 0, length = freqs.length; termId < length; termId++) {
      if (freqs[termId] < FREQ_FLOOR) continue;
      if (fstats.isStop(termId)) continue;
      // test tag against dic, needs some gymnastics between utf8 bytes -> utf16 chars
      fstats.term(termId, bytes);
      chars.copy(bytes);
      FrDics.LexEntry entry = FrDics.word(chars);
      if (entry != null) {
    if (!tagSem.accept(entry.tag)) continue;
      }
      top.push(termId, freqs[termId]);
    }
    first = true;
    int count = 0;
    
    for (TopArray.Entry entry: top) {
      final String w = fstats.term(entry.id(), bytes).utf8ToString();
      alist.add(w);
      
    }
      }
      String[] stars = alist.toArray(new String[alist.size()]);
      words = String.join(", ", stars);
      //
  %>
	  <div id="graphcont">
       <form id="form">
         <button type="button" onclick="clearForm(this.form); this.form.submit()">❌</button>
         <label for="words">pivots </label>
         <div class="elastic">
           <input name="words" value="<%=words%>" size="100"/>
         </div>
         <label for="planets">rayons </label>
         <input name="planets" value="<%=planets%>" class="nb" size="2"/>
         <label for="width">fenêtre </label>
         <input name="width" value="<%=width%>" class="nb" size="2"/>
         <label for="distance">Distance </label>
         <select name="distance" oninput="this.form.submit()">
           <option value="">…distance</option>
            <%=distance.options()%>
         </select>
         <button type="submit">▷</button>
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
<%first = true;
out.println("var data = {");
out.println("  edges: [");

// loop on all stars, get there coocs, store the nodes 
TreeSet<Node> nodeSet = new TreeSet<Node>();
Node tester = new Node(0, null);
final int context = (width + 1) / 2;
int edgeId = 0;
long[] cooc = null;
// first, loop on stars, to add them to the nodeSet
for (String starLabel: stars) {
  final int starId = fstats.termId(starLabel);
  final long starFreq = freqs[starId]; // local freq
  nodeSet.add(new Node(starId, starLabel).count(starFreq).type(STAR));
}

// reloop to get cooc
for (String starLabel: stars) {
  final int starId = fstats.termId(starLabel);
  final long starFreq = freqs[starId]; // local freq
  // out.println("\n get="+nodeSet.contains(tester.id(starId)));
  if (cooc != null) Arrays.fill(cooc, 0); // reuse cooc, wash it before
  cooc = rail.cooc(new String[]{starLabel}, context, context, filter, cooc);
  TopArray top = top(fstats, starId, cooc, planets, distance);
  for (TopArray.Entry entry: top) {
    int planetId = entry.id();
    if (first) first = false;
    else out.println(", ");
    out.print("    {id:'e" + (edgeId++) + "', source:'n" + starId + "', target:'n" + planetId + "', size:" + cooc[planetId] 
    + ", color:'rgba(0, 0, 0, 0.3)'"
    + "}");
    ;
    if (nodeSet.contains(tester.id(planetId))) continue;
    String planetLabel = fstats.term(planetId, bytes).utf8ToString();
    long planetFreq = freqs[planetId];
    Node planet = new Node(planetId, planetLabel).count(planetFreq).type(PLANET);
    // out.println("\ntester="+tester+" planet="+planet+" eqals="+tester.equals(planet)+" contains="+(nodeSet.contains(tester)));
    nodeSet.add(planet);
  }
  
}

out.println("\n  ],");


out.println("  nodes: [");
first = true;
for (Node node: nodeSet) {
   if (first) first = false;
   else out.println(", ");
   String color = "rgba(255, 255, 255, 1)";
   if (node.type == STAR || node.type == NOVA) color = "rgba(255, 0, 0, 1)";
   // else if (Tag.isSub(node.tag())) color = "rgba(255, 255, 255, 1)";
   // else if (Tag.isName(node.tag())) color = "rgba(0, 255, 0, 1)";
   // else if (Tag.isVerb(node.tag())) color = "rgba(0, 0, 128, 0.5)";
   // else if (Tag.isAdj(node.tag())) color = "rgba(128, 128, 255, 1)";
   // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
   out.print("    {id:'n" + node.id + "', label:'" + node.label.toString().replace("'", "\\'") + "', size:" + dfdec2.format(10 * Math.sqrt(node.count)) // node.count
   + ", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) 
   + ", color:'" + color + "'"
   + "}");
 }
 out.println("\n  ]");

  


 out.println("}");%>
var graph = new sigmot('graph', data);
    </script>
  </body>
</html>