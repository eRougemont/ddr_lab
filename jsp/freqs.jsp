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
<%!

final static Sort bookSort = new Sort(
  new SortField[] {
    new SortField(YEAR, SortField.Type.INT),
    new SortField(Alix.BOOKID, SortField.Type.STRING),
  }
);

private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;
private static int limitMax = 500;

static public enum Cat implements Option {
  ALL("Tout"),
  NOSTOP("Mots pleins"), 
  SUB("Substantifs"), 
  NAME("Noms propres"),
  VERB("Verbes"),
  ADJ("Adjectifs"),
  ADV("Adverbes"),
  STOP("Mots vides"), 
  NULL("Mots inconnus"), 
  ;
  private Cat(final String label) {  
    this.label = label ;
  }

  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}

static public enum Order implements Option {
  top("Score, haut"), 
  last("Score, bas"), 
  ;
  private Order(final String label) {  
    this.label = label ;
  }

  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}


private static String lines(final FormEnum forms, final Mime mime, final String href)
{
  StringBuilder sb = new StringBuilder();

  CharsAtt att = new CharsAtt();
  int no = 1;
  Tag zetag;
  // dictonaries coming fron analysis, wev need to test attributes
  boolean first = true;
  while (forms.hasNext()) {
    forms.next();
    // if (term.isEmpty()) continue; // ?
    // get nore info from dictionary
    
    switch(mime) {
      case json:
        if (!first) sb.append(",\n");
        jsonLine(sb, forms, no);
        break;
      case csv:
        csvLine(sb, forms, no);
        break;
      default:
        // sb.append(entry+"<br/>");
        htmlLine(sb, forms, no, href);
    }
    no++;
    first = false;
  }

  return sb.toString();
}

/**
 * An html table row &lt;tr&gt; for lexical frequence result.
 */
private static void htmlLine(StringBuilder sb, final FormEnum forms, final int no, final String href)
{
  String term = forms.label();
  // .replace('_', ' ') ?
  sb.append("  <tr>\n");
  sb.append("    <td class=\"no left\">").append(no).append("</td>\n");
  sb.append("    <td class=\"form\">");
  sb.append("    <a");
  if (href != null) sb.append(" href=\"" + href + Jsp.escUrl(term) + "\"");
  sb.append(">");
  sb.append(term);
  sb.append("</a>");
  sb.append("</td>\n");
  sb.append("    <td>");
  sb.append(Tag.label(forms.tag()));
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(forms.occsMatching()) ;
  sb.append("</td>\n");
  sb.append("    <td class=\"num\">");
  sb.append(forms.docsMatching()) ;
  sb.append("</td>\n");
  // fréquence
  // sb.append(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
  sb.append("    <td class=\"num\">");
  sb.append(dfscore.format(forms.score()));
  sb.append("</td>\n");
  sb.append("    <td></td>\n");
  sb.append("    <td class=\"no right\">").append(no).append("</td>\n");
  sb.append("  </tr>\n");
}

private static void csvLine(StringBuilder sb, final FormEnum forms, final int no)
{
  sb.append(forms.label().replaceAll("\t\n", " "));
  sb.append("\t").append(Tag.label(forms.tag())) ;
  sb.append("\t").append(forms.docsMatching()) ;
  sb.append("\t").append(forms.occsMatching()) ;
  sb.append("\n");
}

static private void jsonLine(StringBuilder sb, final FormEnum forms, final int no)
{
  sb.append("    {\"word\" : \"");
  sb.append(forms.label().replace( "\"", "\\\"" ).replace('_', ' ')) ;
  sb.append("\"");
  sb.append(", \"weight\" : ");
  sb.append(dfdec3.format(forms.score()));
  sb.append(", \"attributes\" : {\"class\" : \"");
  sb.append(Tag.label(Tag.group(forms.tag())));
  sb.append("\"}");
  sb.append("}");
}%>
<%
  // parameters
final String q = tools.getString("q", null);


// final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
Cat cat = (Cat)tools.getEnum("cat", Cat.ALL);
Ranking ranking = (Ranking)tools.getEnum("ranking", Ranking.hypergeo);
String format = tools.getString("format", null);
//if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
Mime mime = (Mime)tools.getEnum("format", Mime.html);
Order order = (Order)tools.getEnum("order", Order.top);


int limit = tools.getInt("limit", limitMax);
// limit a bit if not csv
if (mime == Mime.csv);
else if (limit < 1 || limit > limitMax) limit = limitMax;


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

FieldText fstats = alix.fieldText(field);

Specif specif = ranking.specif();


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
  case STOP:
    tags.setAll().clearGroup(Tag.SUB).clearGroup(Tag.NAME).clearGroup(Tag.VERB).clearGroup(Tag.ADJ).clear(0);
    break;
  case NULL:
    tags.set(0);
    break;
  case ALL:
    tags = null;
    break;
}
boolean reverse = false;
if (order == Order.last) reverse = true;

FormEnum forms = fstats.iterator(limit, filter, specif, tags, reverse);





if (Mime.json.equals(mime)) {
  response.setContentType(Mime.json.type);
  out.println("{");
  out.println("  \"data\":[");
  out.println( lines(forms, mime, q));
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
  out.print( lines(forms, mime, q));
}
else {
%>
<%
}
%>
