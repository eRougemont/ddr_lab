<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
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
<%@ page import="java.util.TreeMap" %>

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
static int starsDefault = 15;

private static final int STAR = 2; // confirmed star
private static final int NEBULA = 1; // candidate star
private static final int COMET = -1; // floating corp
private static final int PLANET = -2; // linked corp


static class Node implements Comparable<Node>
{
  /** persistent id */
  private int formId;
  /** persistent label */
  private final String form;
  /** persistent tag from source  */
  // private final int tag;
  /** growable size */
  private long count;
  /** mutable type */
  private int type;
  /** a counter locally used */
  private double score;
  
  public Node(final int formId, final String form)
  {
    this.form = form;
    this.formId = formId;
  }

  public int type()
  {
    return type;
  }

  public Node type(final int type)
  {
    this.type = type;
    return this;
  }

  /** Modify id, to use a node as a tester */
  public Node id(final int id)
  {
    this.formId = id;
    return this;
  }

  public Node count(final long count)
  {
    this.count = count;
    return this;
  }
  
  public int compareTo(Node o)
  {
    return Integer.compare(this.formId, o.formId);
  }
  @Override
  public boolean equals(Object o)
  {
    if (o == null) return false;
    if (!(o instanceof Node)) return false;
    return (this.formId == ((Node)o).formId);
  }
  
  @Override
  public String toString()
  {
    StringBuilder sb = new StringBuilder();
    sb.append(formId).append(":").append(form).append(" (").append(type).append(", ").append(count).append(")");
    return sb.toString();
  }
}

%>
<%
boolean first;
// global data handlers
String field = pars.field.name();
/*
int starsCount = tools.getInt("stars", starsDefault);
if (starsCount < 1) starsCount = starsDefault;
else if (starsCount > starsMax) starsCount = starsMax;
*/

// the consistency magic
final int planetMax = 50;
final int planetMid = 5;
int planets = tools.getInt("planets", planetMid, alix.name()+"Planets");
if (planets > planetMax) planets = planetMax;
if (planets < 1) planets = planetMid;

pars.left = tools.getInt("left", 50);
pars.right = tools.getInt("right", 50);
pars.limit = tools.getInt("limit", 50);
if (pars.limit > 200) pars.limit = 200;

// for consistency, same freqlist as table.jsp
// this list will be reused to get the matrix of distances
FormEnum freqList = freqList(alix, pars);
// don’t forget to sort, with a limit
freqList.sort(pars.order.sorter(), pars.limit);

final FieldText ftext = alix.fieldText(field);
final FieldRail frail = alix.fieldRail(field);


%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="local/head.jsp" %>
    <title>Graphe de texte</title>
    <script src="<%=hrefHome%>vendor/sigma/sigma.min.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.dragNodes.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.exporters.image.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.animate.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.forceAtlas2.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.noverlap.js">//</script>
    <script src="<%=hrefHome%>static/sigmot.js">//</script>
    <script src="<%=hrefHome%>static/alix.js">//</script>
    <style>
    </style>
  </head>
  <body class="wordnet">
    <div id="graphcont">
      <header>
        <jsp:include page="local/tabs.jsp"/>
      </header>
  <%
  // keep nodes in insertion order (especially for query)
  Map<Integer, Node> nodeMap = new LinkedHashMap<Integer, Node>();
  int i = 0;
  freqList.reset();
  while (freqList.hasNext()) {
    freqList.next();
    final int formId = freqList.formId();
    // add a linked node candidate
    long count = 1;
    if (pars.order.equals(Order.hits)) count = freqList.hits();
    else count = freqList.freq();
    nodeMap.put(formId, new Node(formId, freqList.form()).count(count).type(COMET));
    if (++i >= 500) break;
  }

  %>
<!-- Nodes <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
      <form id="form" class="search">
        <%= selectCorpus(alix.name) %>,
        <%= selectBook(alix, pars.book) %>
        <button type="submit">▶</button>
        
        <br/>
        <input name="limit" type="text" value="<%= pars.limit %>" class="num3" size="2"/>
        <select name="f" onchange="this.form.submit()">
          <option/>
          <%=pars.field.options()%>
        </select>
        <label for="cat" title="Filtrer les mots par catégories grammaticales">filtre</label>
        <select name="cat" onchange="this.form.submit()">
          <option/>
          <%=pars.cat.options()%>
        </select>
        <label for="order" title="Sélectionner et ordonner le tableau selon une colonne">rangés par</label>
        <select name="order" onchange="this.form.submit()">
          <option/>
          <%= pars.order.options("score freq hits")%>
        </select>
        
        <br/>
        <label for="left" title="Largeur du contexte dont sont extraits les liens, en nombre de mots, à gauche">Contexte gauche</label>
        <input name="left" value="<%=pars.left%>" size="1" class="num3"/>
        <label for="right" title="Nombre de mots à capturer à droite">à droite</label>
        <input name="right" value="<%=pars.right%>" size="1" class="num3"/>
        <label for="planets" title="Nombre maximum de liens sortants par nœud">Compacité</label>
        <input type="text" name="planets" value="<%=planets%>"  class="num3" size="2"/>
        <a class="help button" href="#aide">?</a>
        
         <br/>
         <label for="words">Chercher</label>
         <input type="text" class="q" name="q" value="<% JspTools.escape(out, pars.q); %>" size="40" />
      </form>
      <div id="graph" class="graph" oncontextmenu="return false">
      </div>
       <div class="butbar">
         <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
         <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
         <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button>
         <button class="zoomout but" type="button" title="Diminuer">–</button>
         <button class="zoomin but" type="button" title="Grossir">+</button>
         <button class="fontdown but" type="button" title="Diminuer le texte">S↓</button>
         <button class="fontup but" type="button" title="Grossir le texte">S↑</button>
         <button class="shot but" type="button" title="Prendre une photo">📷</button>
         <!--
         <button class="colors but" type="button" title="Gris ou couleurs">◐</button>
         <button class="but restore" type="button" title="Recharger">O</button>
         <button class="FR but" type="button" title="Spacialisation Fruchterman Reingold">☆</button>
       -->
         <button class="mix but" type="button" title="Mélanger le graphe">♻</button>
         <button class="atlas2 but" type="button" title="Démarrer ou arrêter la gravité atlas 2">▶</button>
         <!--
         <span class="resize interface" style="cursor: se-resize; font-size: 1.3em; " title="Redimensionner la feuille">⬊</span>
         -->
       </div>
    </div>
    <script>
<%
first = true;
out.println("var data = {");
out.println("  edges: [");

// Node tester = new Node(0, null);

// reloop to get cooc
first = true;
int edgeId = 0;

 
// Set<Node> nodeSet = new TreeSet<Node>(starSet);
freqList.limit = nodeMap.size() * 2; // collect enough edges
freqList.left = pars.left;
freqList.right = pars.right;
for (Node src: nodeMap.values()) {
  freqList.search = new String[]{src.form}; // set pivot of the coocs
  long found = frail.coocs(freqList);
  if (found < 1) continue;
  // score the coocs found before loop on it
  final int srcId = src.formId;
  frail.score(freqList, ftext.formOccs(srcId));
  int count = 0;
  while (freqList.hasNext()) {
    freqList.next();
    final int dstId = freqList.formId();
    if (srcId == dstId) continue;
    // link only selected nodes
    final Node dst = nodeMap.get(dstId);
    if (dst == null) continue;
    if (src.type() == COMET) src.type(PLANET);
    if (dst.type() == COMET) dst.type(PLANET);
    if (first) first = false;
    else out.println(", ");
    out.print("    {id:'e" + (edgeId++) + "', source:'n" + srcId + "', target:'n" + dstId + "', size:" + freqList.score() 
    + ", color:'rgba(128, 128, 128, 0.2)'"
    + ", srcLabel:'" + ftext.form(srcId).replace("'", "\\'") + "', srcOccs:" + ftext.formOccs(srcId) + ", dstLabel:'" + ftext.form(dstId).replace("'", "\\'") + "', dstOccs:" + ftext.formOccs(dstId) + ", freq:" + freqList.freq()
    + "}");
    if (src.type() != STAR &&  count == planets) break;
    count++;
  }
}

out.println("\n  ],");


out.println("  nodes: [");
first = true;
for (Node node: nodeMap.values()) {
   if (node.type == COMET) continue; // not connected
   if (first) first = false;
   else out.println(", ");
   int tag = ftext.tag(node.formId);
   String color = "rgba(255, 255, 255, 1)";
   if (Tag.SUB.sameParent(tag)) color = "rgba(255, 255, 255, 0.8)";
   else if (Tag.ADJ.sameParent(tag)) color = "rgba(240, 255, 240, 0.7)";
   // if (node.type() == STAR) color = "rgba(255, 0, 0, 0.9)";
   else if (Tag.NAME.sameParent(tag)) color = "rgba(255, 192, 0, 1)";
   // else if (Tag.isVerb(tag)) color = "rgba(0, 0, 0, 1)";
   // else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
   else color = "rgba(159, 183, 159, 1)";
   // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
   out.print("    {id:'n" + node.formId + "', label:'" + node.form.replace("'", "\\'") + "', size:" + (node.count)); // node.count
   out.print(", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) );
   if (node.type() == STAR) out.print(", type:'hub'");
   out.print(", color:'" + color + "'");
   out.print("}");
 }
 out.println("\n  ]");

  


 out.println("}");
 %>



var graph = new sigmot('graph', data);
    </script>
    <!-- Edges <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
    <main>
      <div class="row">
        <div class="text" id="aide">
          <p>Ce réseau relie des mots qui apparaissent ensemble dans un contexte de <%= pars.context %> mots de large,
<%
Document doc = null;
if (pars.book != null) {
  final int docId = alix.getDocId(pars.book);
  if (docId > 0) doc = alix.reader().document(docId, BOOK_FIELDS);
}
if (doc != null) {
  final String title = doc.get("title");
  out.println("dans <i>" + title + "</i>.");
}
else {
  out.println("dans la base <i>" + alix.props.getProperty("label") + "</i>.");
}
if (pars.q == null && pars.book != null) {
  out.println(
      " Les visibles sont les plus significatifs du livre relativement au reste de la base,"
    + " selon un calcul de distance statistique "
    + " (<i><a href=\"https://en.wikipedia.org/wiki/G-test\">G-test</a></i>, "
    + " voir <a class=\"b\" href=\"index.jsp?book=" + pars.book + "&amp;cat=STRONG&amp;ranking=g\">les résultats</a>)."
  );
}
else {
  out.println(
      " Les mots reliés sont les plus significatifs de la base,"
    + " selon un calcul de distance documentaire"
    + " (<i><a href=\"https://en.wikipedia.org/wiki/Okapi_BM25\">BM25</a></i>"
    + " voir <a class=\"b\" href=\"index.jsp?cat=STRONG&amp;ranking=bm25\">les résultats</a>)."
  );
}
%>
          
          </p>
          <p><strong>Indices de lecture —</strong>
            Les mots sont colorés selon leur fonction, les substantifs sont en blanc, les noms en vert, et les adjectifs en orange.
            Ces types de mots sont généralement les plus significatifs du contenu sémantique d’un texte. 
            La taille d’un mot est représentative de son nombre d’occurrences dans la section de texte sélectionnée.
            L’épaisseur d’un lien entre deux mots est représentative du nombre d’apparitions ensemble.
          </p>
          <p><strong>Placement gravitationnel —</strong>
          Le placement des mots résulte d’un algorithme <i>gravitationnel</i>, qui essaie de rapprocher les mots les plus liés
          (comme des planètes par l’attraction). Il en résulte que le les directions haut ou bas ne sont pas significatives,
          c’est à l’humain de retourner le réseau dans le sens qui est le plus lisible pour lui (avec les boutons 
           <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
           <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
          ). Dans la mesure du possible, l’algorithme essaie d’éviter que les mots se recouvrent, mais 
          l’arbitrage entre cohérence générale des dsitances et taille des mots peut laisser quelques mots peu lisibles.
          Le bouton <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button> tente d’écater au mieux les étiquettes.
          L’utilisateur peut aussi zoomer pour entrer dans le détail d’une zone
          (<button class="zoomout but" type="button" title="Diminuer">–</button>
            <button class="zoomin but" type="button" title="Grossir">+</button>), et déplacer le réseau en cliquant tirant l’image globale.
            Le bouton <button class="mix but" type="button" title="Mélanger le graphe">♻</button> permet de tout mélanger,
            
            
          </p>
        </div>
      </div>
    </main>
  </body>
</html>



