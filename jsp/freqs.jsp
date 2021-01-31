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
static final DecimalFormat formatScore = new DecimalFormat("0.00000", DecimalFormatSymbols.getInstance(Locale.ENGLISH));

/**
 * Specific pars for this display
 */



private static final int OUT_HTML = 0;
private static final int OUT_CSV = 1;
private static final int OUT_JSON = 2;


private static String lines(final FormEnum forms, final Mime mime)
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
        // htmlLine(sb, forms, no, href);
    }
    no++;
    first = false;
  }

  return sb.toString();
}


private static void csvLine(StringBuilder sb, final FormEnum forms, final int no)
{
  sb.append(forms.form().replaceAll("\t\n", " "));
  sb.append("\t").append(Tag.label(forms.tag())) ;
  sb.append("\t").append(forms.hits()) ;
  sb.append("\t").append(forms.freq()) ;
  sb.append("\n");
}

static private void jsonLine(StringBuilder sb, final FormEnum forms, final int no)
{
  sb.append("    {\"word\" : \"");
  sb.append(forms.form().replace( "\"", "\\\"" ).replace('_', ' ')) ;
  sb.append("\"");
  sb.append(", \"weight\" : ");
  sb.append(formatScore(forms.score()));
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
*/%>