<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.IOException" %>
<%@ page import="org.apache.lucene.search.ScoreDoc" %>
<%@ page import="org.apache.lucene.search.TopDocs" %>
<%@ page import="org.apache.lucene.util.automaton.Automaton" %>
<%@ page import="org.apache.lucene.util.automaton.ByteRunAutomaton" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="alix.lucene.DocType" %>
<%@ page import="alix.lucene.util.WordsAutomatonBuilder" %>
<%@ page import="alix.web.*" %>
<%!
static int hppDefault = 100;
static int hppMax = 1000;

/**
 * Specific pars for this display
 */
class Pars {
  String fieldName;
  String q;
  String book;
  int start;
  int left;
  int right;
  int hpp;
  String href;
  String[] forms;
  DocSort sort;
  boolean expression;
}

/**
 * Get default pars 
 */
public Pars pars(final PageContext page)
{
  Pars pars = new Pars();
  JspTools tools = new JspTools(page);
  
  pars.q = tools.getString("q", null);
  pars.book = tools.getString("book", null);
  
  pars.expression = tools.getBoolean("expression", false);
  pars.hpp = tools.getInt("hpp", hppDefault);
  if (pars.hpp > hppMax || pars.hpp < 1) pars.hpp = hppDefault;
  pars.sort = (DocSort)tools.getEnum("sort", DocSort.year);
  pars.start = tools.getInt("start", 1);
  if (pars.start < 1) pars.start = 1;
  

  
  pars.left = 70;
  pars.right = 50;
  return pars;
}

public void kwic(final PageContext page, final Alix alix, final TopDocs topDocs, Pars pars) throws IOException, NoSuchFieldException
{
  if (topDocs == null) return;
  JspWriter out = page.getOut();

  
  ByteRunAutomaton include = null;
  if (pars.forms != null) {
    Automaton automaton = WordsAutomatonBuilder.buildFronStrings(pars.forms);
    if (automaton != null) include = new ByteRunAutomaton(automaton);
  }
  boolean repetitions = false;
  if (pars.forms.length == 1) repetitions = true;
  // get the index in results
  ScoreDoc[] scoreDocs = topDocs.scoreDocs;
  // where to start loop ?
  int i = pars.start - 1; // private index in results start at 0
  int max = scoreDocs.length;
  if (i < 0) i = 0;
  else if (i > max) i = 0;
  // loop on docs
  int docs = 0;
  final int gap = 5;
  

  // be careful, if one term, no expression possible, this will loop till the end of corpus
  boolean expression = false;
  if (pars.forms == null) expression = false;
  else expression = pars.expression;

  while (i < max) {
    final int docId = scoreDocs[i].doc;
    i++; // loop now
    final Doc doc = new Doc(alix, docId);
    String type = doc.doc().get(Alix.TYPE);
    // TODO Enenum
    if (type.equals(DocType.book.name())) continue;
    if (doc.doc().get(pars.fieldName) == null) continue;
    String href = pars.href + "&amp;q=" + JspTools.escUrl(pars.q) + "&amp;id=" + doc.id() + "&amp;start=" + i + "&amp;sort=" + pars.sort.name();
    
    // show simple metadata
    out.println("<!-- docId=" + docId + " -->");
    if (pars.forms == null || pars.forms.length == 0) {
      out.println("<article class=\"kwic\">");
      out.println("<header>");
      out.println("<small>"+(i)+".</small> ");
      out.print("<a href=\"" + href + "\">");
      String year = doc.get("year");
      if (year != null) {
        out.print(doc.get("year"));
        out.print(", ");
      }
      out.print(doc.get("title"));
      out.print(". ");
      out.print(doc.get("analytic"));
      out.print("</a>");
      out.println("</header>");
      out.println("</article>");
      if (++docs >= pars.hpp) break;
      continue;
    }
    
    String[] lines = null;
    lines = doc.kwic(pars.fieldName, include, href.toString(), 200, pars.left, pars.right, gap, expression, repetitions);
    if (lines == null || lines.length < 1) continue;
    // doc.kwic(field, include, 50, 50, 100);
    out.println("<article class=\"kwic\">");
    out.println("<header>");
    out.println("<small>"+(i)+"</small> ");

    out.print("<a href=\""+href+"\">");
    String year = doc.get("year");
    if (year != null) {
      out.print(doc.get("year"));
      out.print(", ");
    }
    out.print(doc.get("title"));
    out.print(". ");
    out.print(doc.get("analytic"));
    out.println("</a></header>");
    for (String l: lines) {
      out.println("<div class=\"line\">"+l+"</div>");
    }
    out.println("</article>");
    if (++docs >= pars.hpp) break;
  }

}
%>