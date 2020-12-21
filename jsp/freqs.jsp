<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp"%>
<%@ page import="org.apache.lucene.analysis.miscellaneous.ASCIIFoldingFilter" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsAtt" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.analysis.FrDics.LexEntry" %>
<%@ page import="alix.lucene.search.FieldText" %>
<%@ page import="alix.lucene.search.TermList" %>
<%@ page import="alix.util.Char" %>
<%!final static HashSet<String> FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, "byline", "year", "title"}));

private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;

static public enum Ranking implements Select {
  freq("Fréquence"), 
  bm25("BM25 (pondération par documents)"),
  tfidf("tf-idf (term frequency–inverse document frequency)"),
  // jaccard("Jaccard (pondération par occurrences)"),
  // dice("Dice (pondération par occurrences ²)"),
  ;

  private Ranking(final String label) {  
    this.label = label ;
  }

  // Repeating myself
  final public String label;
  public String label() { return label; }
  static final public List<Select> list;
  static { list = Collections.unmodifiableList(Arrays.asList((Select[]) values())); }
  public List<Select> list() { return list; }
  public String hint() { return null; }
}

static public enum Cat implements Select {
  NOSTOP("Mots pleins"), 
  SUB("Substantifs"), 
  NAME("Noms propres"),
  VERB("Verbes"),
  ADJ("Adjectifs"),
  ADV("Adverbes"),
  ALL("Tout"),
  ;
  private Cat(final String label) {  
    this.label = label ;
  }

  
  // Repeating myself
  final public String label;
  public String label() { return label; }
  static final public List<Select> list;
  static { list = Collections.unmodifiableList(Arrays.asList((Select[]) values())); }
  public List<Select> list() { return list; }
  public String hint() { return null; }
}


private static String lines(final SortEnum terms, final Mime mime, final String q)
{
  StringBuilder sb = new StringBuilder();

  CharsAtt att = new CharsAtt();
  int no = 1;
  Tag zetag;
  // dictonaries coming fron analysis, wev need to test attributes
  boolean first = true;
  while (terms.hasNext()) {
    terms.next();
    LexEntry entry = FrDics.word(terms.label(att));
    // if (term.isEmpty()) continue; // ?
    // get nore info from dictionary
    
    switch(mime) {
      case json:
        if (!first) sb.append(",\n");
        jsonLine(sb, terms, no);
        break;
      case csv:
        csvLine(sb, terms, no);
        break;
      default:
        // sb.append(entry+"<br/>");
        htmlLine(sb, terms, no, entry, q);
    }
    no++;
    first = false;
  }

  return sb.toString();
}

/**
 * An html table row &lt;tr&gt; for lexical frequence result.
 */
private static void htmlLine(StringBuilder sb, final SortEnum terms, final int no, final LexEntry entry, final String q)
{
  String term = terms.label();
  // .replace('_', ' ') ?
  sb.append("  <tr>\n");
  sb.append("    <td class=\"no left\">").append(no).append("</td>\n");
  sb.append("    <td class=\"form\">");
  if (q != null) {
    sb.append(" href=\"kwic?sort=score&amp;q=");
    sb.append(q);
    sb.append(" %2B").append(term);
    sb.append("&amp;expression=on");
    sb.append("\">");
  }
  sb.append(term);
  // sb.append("</a>");
  sb.append("</td>\n");
  sb.append("    <td>");
  sb.append(Tag.label(terms.tag()));
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(terms.docsMatching()) ;
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(terms.occsMatching()) ;
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(dfdec1.format((double)terms.occsMatching() * 1000000 / terms.occsCount())) ;
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  if (entry != null) sb.append(dfdec1.format(entry.lemfreq));
  sb.append("</td>\n");
  sb.append("    <td></td>\n");
  sb.append("    <td class=\"no right\">").append(no).append("</td>\n");
  sb.append("  </tr>\n");
}

private static void csvLine(StringBuilder sb, final SortEnum terms, final int no)
{
  sb.append(terms.label().replaceAll("\t\n", " "));
  sb.append("\t").append(Tag.label(terms.tag())) ;
  sb.append("\t").append(terms.docsMatching()) ;
  sb.append("\t").append(terms.occsMatching()) ;
  sb.append("\n");
}

static private void jsonLine(StringBuilder sb, final SortEnum terms, final int no)
{
  sb.append("    {\"word\" : \"");
  sb.append(terms.label().replace( "\"", "\\\"" ).replace('_', ' ')) ;
  sb.append("\"");
  sb.append(", \"weight\" : ");
  sb.append(dfdec3.format(terms.score()));
  sb.append(", \"attributes\" : {\"class\" : \"");
  sb.append(Tag.label(Tag.group(terms.tag())));
  sb.append("\"}");
  sb.append("}");
}%>
<%
// parameters
final String q = tools.getString("q", null);


// final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
Cat cat = (Cat)tools.getEnum("cat", Cat.NOSTOP);
Ranking ranking = (Ranking)tools.getEnum("ranking", Ranking.freq);
String format = tools.getString("format", null);
//if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
Mime mime = (Mime)tools.getEnum("format", Mime.html);


int limit = tools.getInt("limit", -1);
// limit a bit if not csv
if (mime == Mime.csv);
else if (limit < 1 || limit > 2000) limit = 500;


int left = tools.getInt("left", 5);
if (left < 0) left = 0;
else if (left > 10) left = 10;
int right = tools.getInt("right", 5);
if (right < 0) right = 0;
else if (right > 10) right = 10;

Corpus corpus = null;

BitSet filter = null; // if a corpus is selected, filter results with a bitset
String bookid = tools.getString("book", null);
if (bookid != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{bookid});

final String field = TEXT; // the field to process

FieldText fstats = alix.fieldStats(field);

Scorer scorer = null;
switch(ranking) {
  case freq:
    scorer = new ScorerOccs();
    break;
  case bm25:
    scorer = new ScorerBM25();
    break;
  case tfidf:
    scorer = new ScorerTfidf();
    break;
    /*
  case jaccard:
    double[] scores = new double[dic.size()];
    for (int termId = 0, length = dic.size(); termId < length; termId++) {
  long m11 = dic.occs(termId);
  long m10 = fstats.occs(termId) - m11;
  // long m01 = fstats.freq(pivotId) - m11;
  // TODO, should be the sub corpus filtered total occs
  long m00 = fstats.occsAll;
  // double score = distance.score(m11, m10, m01, m00);
  // top.push(termId, score);
    }

    break;
  case dice:
    dic.sortByScores();
    break;
    */
}

TagFilter tags = new TagFilter();
// filtering
switch (cat) {
  case SUB:
    tags.setGroup(Tag.SUB);
    break;
  case NAME:
    tags.setGroup(Tag.NAME);
    break;
  case VERB:
    tags.setGroup(Tag.VERB);
    break;
  case ADJ:
    tags.setGroup(Tag.ADJ);
    break;
  case ADV:
    tags.setGroup(Tag.ADV);
    break;
  case NOSTOP:
    tags.setAll().noStop(true);
    break;
  case ALL:
    tags = null;
    break;
}


SortEnum terms = fstats.iterator(limit, filter, scorer, tags);





if (Mime.json.equals(mime)) {
  response.setContentType(Mime.json.type);
  out.println("{");
  out.println("  \"data\":[");
  out.println( lines(terms, mime, q));
  out.println("\n  ]");
  out.println("\n}");
}
else if (Mime.csv.equals(mime)) {
  response.setContentType(Mime.csv.type);
  StringBuffer sb = new StringBuffer().append(baseName);
  if (corpus != null) {
    sb.append('-').append(corpus.name());
  }
  
  if (q != null) {
    String zeq = q.trim().replaceAll("[ ,;]+", "-");
    final int len = Math.min(zeq.length(), 30);
    char[] zeqchars = new char[len*4]; // 
    ASCIIFoldingFilter.foldToASCII(zeq.toCharArray(), 0, zeqchars, 0, len);
    sb.append('_').append(zeqchars, 0, len);
  }
  response.setHeader("Content-Disposition", "attachment; filename=\""+sb+".csv\"");
  out.print("Mot\tType\tChapitres\tOccurrences");
  out.println();
  out.print( lines(terms, mime, q));
}
else {
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Fréquences, <%=(corpus != null) ? Jsp.escape(corpus.name())+", " : ""%><%=props.get("name")%> [Obvie]</title>
    <!-- 
    <link href="<%=hrefHome%>static/ddrlab.css" rel="stylesheet"/>
     -->
    <style type="text/css">

body,
select,
button {
  font-family: monospace;
}
button,
select {
  font-size: inherit;
  /*
  -moz-appearance: none;
  -webkit-appearance: none;
  appearance: none;
  */
  border: 1px solid #000;
  background: #fff;
  cursor: pointer;
}
body {
  padding: 0 45px;
  font-size:20px;
  line-height: 100%;
  background-color: #fff;
  background-image: 
    url('data:image/svg+xml;utf-8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 72" fill="rgb(64, 64, 64)" stroke="rgb(192, 192, 192)" stroke-width="3%"><circle cx="24" cy="24" r="8"/></svg>'),
    url('data:image/svg+xml;utf-8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 72" fill="rgb(64, 64, 64)" stroke="rgb(192, 192, 192)" stroke-width="3%"><circle cx="24" cy="24" r="8"/></svg>')
  ;
   background-position: left, right;
   background-size: 43px;
   background-repeat: repeat-y;
}
main {
  border-left: 1.5px #ccc dashed;
  border-right: 1.5px #ccc dashed;
  padding: 0 6px;
}

.sortable thead tr th{
  background: rgba(255, 255, 255, 1);
  position: sticky;
  top: 0;
  z-index: 10;
  border-bottom: 2px solid #666;
}
table.sortable {
  border-spacing: 0;
}
table.sortable caption {
  text-align: left;
}
table.sortable th {
  color: #000 !important;
  text-align: left;
  font-weight: bold;
}
.mod1,
.mod5,
.mod6,
.mod0 {
  background-color: #eeffee;
}
.mod3, .mod8 {
  background-color: #ccffcc;
}
.mod0 td {
  border-bottom: 2px solid #666;
}
.mod5 td {
  border-bottom: 1px solid #000;
}

th.form,
td.form {
  padding-left: 1rem;
}
td.no {
  vertical-align: middle;
  color:  #33CC33;
  font-size: 60%;
  background: #fff;
  border: none;
}
caption {
  padding: 0 30px;
}
td.num {
  text-align: right;
}
td.no.left {
  text-align: right;
  padding-right: 5px;
}
td.no.right {
  text-align: left;
  padding-left: 5px;
}
td.form {
  white-space: nowrap;
}
    </style>
  </head>
  <body>
    <main>
      <table class="sortable" width="100%">
        <caption>
          <form id="sortForm">
             <br/>
               <%
                 if (q == null) {
                               // out.println(max+" termes");
                             }
                             else {
                               out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\""+left+"\"/>");
                               out.print(q);
                               out.println("<input style=\"width: 2em;\" name=\"right\" value=\""+right+"\"/>&gt;");
                               out.println("<input type=\"hidden\" name=\"q\" value=\""+Jsp.escape(q)+"\"/>");
                             }
               %>
             <label>Sélectionner un livre de Rougemont (ou bien tous les livres)
             <br/><select name="book" onchange="this.form.submit()">
                  <option value="">TOUT</option>
                  <%
                  FieldFacet facet = alix.facet(Alix.BOOKID, TEXT);
                  SortEnum books = facet.iterator();
                    while (books.hasNext()) {
                      books.next();
                      String id = books.label();
                      Document doc = reader.document(alix.getDocId(id), FIELDS);
                      out.print("<option value=\"" + id + "\"");
                      if (id.equals(bookid)) out.print(" selected=\"selected\"");
                      out.print(">");
                      out.print(doc.get("year"));
                      out.print(", ");
                      out.print(doc.get("title"));
                      out.println("</option>");
                    }
                  %>
               </select>
             </label>
             
             <br/><label>Filtrer par catégorie grammaticale
             <br/><select name="cat" onchange="this.form.submit()">
                 <option/>
                 <%= cat.options() %>
              </select>
             </label>
             <br/><label>Trier les mots
             <br/><select name="ranking" onchange="this.form.submit()">
                 <option/>
                 <%= ranking.options() %>
              </select>
             </label>
             
             <br/>
             <br/><button style="width: 100%; text-align: center;" type="submit">Appuyer ici pour faire calculer votre requête (attention cela peut prendre de nombreuses minutes)</button>
             <br/>
             <br/>
             <br/>
          </form>
        </caption>
        <thead>
          <tr>
            <td/>
		        <th title="Forme graphique indexée">Graphie</th>
		        <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre de chapitres"> Chapitres</th>
            <th title="Nombre d’occurrences"> Occurrences</th>
            <th title="Effectif par million d’occurrences"> Fréquence</th>
            <th title="Frantext, effectif par million d’occurrences"> Frantext</th>
            <th width="100%"/>
          <tr>
        </thead>
        <tbody>
          <%= lines(terms, mime, q) %>
        </tbody>
      </table>
      <pre style="text-align: center;">
██████   ██████  ██    ██  ██████  ███████ ███    ███  ██████  ███    ██ ████████     ██████      ██████  
██   ██ ██    ██ ██    ██ ██       ██      ████  ████ ██    ██ ████   ██    ██             ██    ██  ████ 
██████  ██    ██ ██    ██ ██   ███ █████   ██ ████ ██ ██    ██ ██ ██  ██    ██         █████     ██ ██ ██ 
██   ██ ██    ██ ██    ██ ██    ██ ██      ██  ██  ██ ██    ██ ██  ██ ██    ██        ██         ████  ██ 
██   ██  ██████   ██████   ██████  ███████ ██      ██  ██████  ██   ████    ██        ███████ ██  ██████  
      </pre>
    </main>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
<%
}
%>
