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



private final int STAR = 2; // confirmed star
private final int NEBULA = 1; // candidate star
private final int COMET = -1; // floating corp
private final int PLANET = -2; // linked corp


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
// global data handlers
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
// page parameters
final String fieldName = "text";
/*
int starsCount = tools.getInt("stars", starsDefault);
if (starsCount < 1) starsCount = starsDefault;
else if (starsCount > starsMax) starsCount = starsMax;
*/
String q = tools.getString("q", null);
int width = tools.getInt("width", 20, alix.name()+"Width");
if (width < 3) width = 3;
final int planetMax = 50;
final int planetMid = 10;
int planets = tools.getInt("planets", planetMid, alix.name()+"Planets");
if (planets > planetMax) planets = planetMax;
if (planets < 1) planets = planetMid;
String book = tools.getString("book", null);

// local data object, to build from parameters
BitSet filter = null;
if (book != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{book});
final FieldText ftext = alix.fieldText(fieldName);
final FieldRail frail = alix.fieldRail(fieldName);
final int context = (width + 1) / 2;
FormEnum coocs = new FormEnum(ftext); // build a wrapper to have results
coocs.left = context; // left context
coocs.right = context; // right context
coocs.filter = filter; // limit to some documents
coocs.tags = Cat.STRONG.tags(); // limit word list to SUB, NAME, adj
coocs.specif = Ranking.g.specif(); // best ranking for coocs
boolean first;

%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="ddr_head.jsp" %>
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
        <jsp:include page="tabs.jsp"/>
      </header>

  <%


// keep nodes in insertion order (especially for query)
Map<Integer, Node> nodeMap = new LinkedHashMap<Integer, Node>();
final int nodeMax = 100;

// Find here the stars around which add coocs
if (q != null && !q.trim().isEmpty()) { // words requested, search for them
  long[] freqs;
  if (book != null) freqs = ftext.formOccs(filter);
  else freqs = ftext.formAllOccs;
  String[] forms = alix.forms(q); // parse query as a set of terms
  // rewrite queries, with only known terms
  int nodeCount = 0;
  for (String form: forms) {
    int formId = ftext.formId(form);
    if (formId < 0) continue;
    long freq = freqs[formId];
    if (freq < 1) continue;
    // keep query words as stars
    nodeMap.put(formId, new Node(formId, form).count(freq).type(STAR));
    if (++nodeCount >= nodeMax) break;
  }
  final int starCount = nodeCount;
  // reloop on nodes found in query, add coocs
  first = true;
  // try to add quite same node to on an another
  int i = 1;
  Node[] toloop = nodeMap.values().toArray(new Node[nodeMap.size()]);
  q = "";
  coocs.limit = nodeMax + starCount; // take more coccs we need
  for (Node src: toloop) {
    if (first) first = false;
    else q += " ";
    q += src.form;
    coocs.search = new String[]{src.form}; // parse query as terms
    long found = frail.coocs(coocs);
    if (found < 0) continue;
    // score the coocs found before loop on it
    frail.score(coocs);
    final int srcId = src.formId;
    final long srcFreq = src.count; // local freq

    final int countMax = (int)((double)nodeMax * i / starCount);
    i++;
    while (coocs.hasNext()) {
      coocs.next();
      final int dstId = coocs.formId();
      final Node dst = nodeMap.get(dstId);
      if (dst != null) continue; // node already found
      Node comet = new Node(dstId, coocs.form()).count(coocs.freq()).type(COMET);
      nodeMap.put(dstId, comet);
      if (++nodeCount >= countMax) break;
    }
  }
}
else { // 

  FormEnum top = null;
  // a book selected, g test seems better, with no stops
  if (book != null) {
    top = ftext.iterator(nodeMax, Ranking.g.specif(), filter, Cat.STRONG.tags(), false);
  }
  // global base, best selection is BM25 scoring with no stop words
  else {
    top = ftext.iterator(nodeMax, Ranking.bm25.specif(), null, Cat.STRONG.tags(), false);
  }
  while (top.hasNext()) {
    top.next();
    final int formId = top.formId();
    // add a linked node candidate
    nodeMap.put(formId, new Node(formId, top.form()).count(top.freq()).type(COMET));
  }
  
}
  %>
       <form id="form" class="search">
         <div class="line">
           <label for="width" title="Largeur du contexte, en nombre de mots, dont sont extraits les co-occurrents">Contexte</label>
           <input type="text" name="width" value="<%=width%>" class="nb" size="2"/>
           <label for="planets" title="Compacité du réseau, en nombre maximal de liens par nœuds">Compacité</label>
           <input type="text" name="planets" value="<%=planets%>" class="nb" size="2"/>
           <label for="words">Pivots</label>
           <div class="elastic">
             <input type="text" name="q" value="<%=tools.escape(q)%>" size="100"  />
           </div>
         </div>
         <label for="book">Livre</label>
         <select name="book" onchange="this.form.submit()">
           <option value=""></option>
            <%
int[] books = alix.books(sortYear);
String title = "";
for (int docId: books) {
  Document doc = alix.reader().document(docId, BOOK_FIELDS);
  String txt = "";
  txt = doc.get("year");
  if (txt != null) txt += ", ";
  txt += doc.get("title");
  String abid = doc.get(Alix.BOOKID);
  out.print("<option value=\"" + abid + "\"");
  if (abid.equals(book)) {
    out.print(" selected=\"selected\"");
    title = doc.get("title");
  }
  out.print(">");
  out.print(txt);
  out.println("</option>");
}
                  %>
          </select>
          <button type="submit">▶</button>
          <a class="help button" href="#aide">?</a>
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
<%first = true;
out.println("var data = {");
out.println("  edges: [");

Node tester = new Node(0, null);

// reloop to get cooc
first = true;
int edgeId = 0;

 
// Set<Node> nodeSet = new TreeSet<Node>(starSet);
coocs.limit = nodeMap.size() * 2; // collect enough edges
for (Node src: nodeMap.values()) {
  coocs.search = new String[]{src.form}; // set pivot of the coocs
  long found = frail.coocs(coocs);
  if (found < 0) continue;
  // score the coocs found before loop on it
  frail.score(coocs);
  final int srcId = src.formId;
  int count = 0;
  while (coocs.hasNext()) {
    coocs.next();
    final int dstId = coocs.formId();
    if (srcId == dstId) continue;
    // link only selected nodes
    final Node dst = nodeMap.get(dstId);
    if (dst == null) continue;
    if (src.type() == COMET) src.type(PLANET);
    if (dst.type() == COMET) dst.type(PLANET);
    if (first) first = false;
    else out.println(", ");
    out.print("    {id:'e" + (edgeId++) + "', source:'n" + srcId + "', target:'n" + dstId + "', size:" + coocs.freq() 
    + ", color:'rgba(0, 0, 0, 0.2)'"
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
   if (node.type() == STAR) color = "rgba(255, 0, 0, 1)";
   else if (Tag.isSub(tag)) color = "rgba(255, 255, 255, 1)";
   else if (Tag.isName(tag)) color = "rgba(0, 255, 0, 1)";
   else if (Tag.isVerb(tag)) color = "rgba(0, 0, 128, 1)";
   else if (Tag.isAdj(tag)) color = "rgba(255, 128, 0, 1)";
   else color = "rgba(0, 0, 0, 0.8)";
   // {id:'n204', label:'coeur', x:-16, y:99, size:86, color:'hsla(0, 86%, 42%, 0.95)'},
   out.print("    {id:'n" + node.formId + "', label:'" + node.form.replace("'", "\\'") + "', size:" + dfdec2.format(10 * node.count) // node.count
   + ", x:" + ((int)(Math.random() * 100)) + ", y:" + ((int)(Math.random() * 100)) 
   + ", color:'" + color + "'"
   + "}");
 }
 out.println("\n  ]");

  


 out.println("}");
%>



var graph = new sigmot('graph', data);
    </script>
    <main>
      <div class="row">
        <div class="text" id="aide">
          <p>Ce réseau relie des mots qui apparaissent ensemble dans un contexte de <%= width %> mots de large,
<%
if (book != null) {
  out.println("dans <i>" + title + "</i>.");
}
else {
  out.println("dans la base <i>" + alix.props.getProperty("label") + "</i>.");
}
if (q == null && book != null) {
  out.println(
      " Les mots reliés sont les plus significatifs du livre relativement au reste de la base,"
    + " selon un calcul de distance statistique "
    + " (<i><a href=\"https://en.wikipedia.org/wiki/G-test\">G-test</a></i>, "
    + " voir <a class=\"b\" href=\"index.jsp?book=" + book + "&amp;cat=STRONG&amp;ranking=g\">les résultats</a>)."
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



