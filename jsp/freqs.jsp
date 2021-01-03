<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="java.util.Locale" %>
<%@ page import="org.apache.lucene.analysis.miscellaneous.ASCIIFoldingFilter" %>
<%@ page import="org.apache.lucene.search.Sort" %>
<%@ page import="org.apache.lucene.search.SortField" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.fr.Tag.TagFilter" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.analysis.tokenattributes.CharsAtt" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.analysis.FrDics.LexEntry" %>
<%@ page import="alix.lucene.search.FieldText" %>
<%@ page import="alix.lucene.search.FormEnum" %>
<%@ page import="alix.lucene.search.TermList" %>
<%@ page import="alix.util.Char" %>
<%@ page import="alix.web.*" %>
<%@include file="prelude.jsp"%>
<%!
/** Uded to sort books, good place ? */
static String bookYear = "year";
static final DecimalFormat formatScore = new DecimalFormat("0.00000", DecimalFormatSymbols.getInstance(Locale.ENGLISH));
static final DecimalFormat formatDec3 = new DecimalFormat("0.###", DecimalFormatSymbols.getInstance(Locale.ENGLISH));

/**
 * Specific pars for this display
 */
class Pars {
  String fieldName;
  Cat cat;
  Ranking ranking;
  Mime mime;
  int limit;
  Order order;
  String q;
  int left;
  int right;
  String book;
}

/**
 * Get default pars 
 */
public Pars pars(final PageContext page)
{
  Pars pars = new Pars();
  JspTools tools = new JspTools(page);
  //parameters
  pars.q = tools.getString("q", null);
  //final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
  pars.cat = (Cat)tools.getEnum("cat", Cat.ALL);
  pars.ranking = (Ranking)tools.getEnum("ranking", Ranking.chi2);
  String format = tools.getString("format", null);
  //if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
  pars.mime = (Mime)tools.getEnum("format", Mime.html);
  pars.order = (Order)tools.getEnum("order", Order.top);
  
  // limit to a book
  pars.book = tools.getString("book", null);

  
  pars.limit = tools.getInt("limit", limitMax);
  //limit a bit if not csv
  if (pars.mime == Mime.csv);
  else if (pars.limit < 1 || pars.limit > limitMax) pars.limit = limitMax;
  
  // coocs
  pars.left = tools.getInt("left", 5);
  if (pars.left < 0) pars.left = 0;
  else if (pars.left > 10) pars.left = 50;
  pars.right = tools.getInt("right", 5);
  if (pars.right < 0) pars.right = 0;
  else if (pars.right > 10) pars.right = 50;
  return pars;
}



final static Sort bookSort = new Sort(
  new SortField[] {
    new SortField(bookYear, SortField.Type.INT),
    new SortField(Alix.BOOKID, SortField.Type.STRING),
  }
);

private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;
private static int limitMax = 500;


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
  if (href != null) sb.append(" href=\"" + href + JspTools.escUrl(term) + "\"");
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
  sb.append(formatScore.format(forms.score()));
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
  sb.append(formatDec3.format(forms.score()));
  sb.append(", \"attributes\" : {\"class\" : \"");
  sb.append(Tag.label(Tag.group(forms.tag())));
  sb.append("\"}");
  sb.append("}");
}


/*
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
*/


%>