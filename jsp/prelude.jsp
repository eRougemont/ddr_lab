<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.FileInputStream" %>
<%@ page import="java.io.FileNotFoundException"%>
<%@ page import="java.io.PrintWriter" %>
<%@ page import="java.lang.invoke.MethodHandles" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.Collections" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.InvalidPropertiesFormatException" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.util.Set" %>

<%@ page import="org.apache.lucene.analysis.Analyzer" %>
<%@ page import="org.apache.lucene.document.Document" %>
<%@ page import="org.apache.lucene.index.IndexReader" %>
<%@ page import="org.apache.lucene.index.Term" %>
<%@ page import="org.apache.lucene.search.*" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="org.apache.lucene.search.BooleanClause.*" %>
<%@ page import="org.apache.lucene.util.BitSet" %>
<%@ page import="alix.fr.Tag" %>
<%@ page import="alix.fr.Tag.TagFilter" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.Alix.FSDirectoryType" %>
<%@ page import="alix.lucene.DocType" %>
<%@ page import="alix.lucene.analysis.FrAnalyzer" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.search.*" %>

<%@ page import="alix.lucene.search.FieldRail" %>
<%@ page import="alix.util.ML" %>
<%@ page import="alix.util.TopArray" %>
<%@ page import="alix.web.*" %>
<%!



// do it one time
static {
  if (!Webinf.bases) Webinf.bases();
}
static final String COOKIE_BASE = "alixBase";



final static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
final static DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);
static final DecimalFormat dfdec3 = new DecimalFormat("0.000", ensyms);
static final DecimalFormat dfdec2 = new DecimalFormat("0.00", ensyms);
static final DecimalFormat dfdec1 = new DecimalFormat("0.0", ensyms);
static final DecimalFormat dfdec5 = new DecimalFormat("0.0000E0", ensyms);
static final DecimalFormat dfScore = new DecimalFormat( "0.00000", ensyms);
/** Fields to retrieve in document for a book */
final static HashSet<String> BOOK_FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, "byline", "year", "title"}));
final static HashSet<String> CHAPTER_FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, Alix.ID, "year", "title", "analytic", "pages"}));

final static Sort sortYear = new Sort(
  new SortField[] {
    new SortField("year", SortField.Type.INT),
    new SortField(Alix.ID, SortField.Type.STRING),
  }
);


/** Field name containing canonized text */
final static String TEXT = "text";
/** Field Name with int date */
final static String YEAR = "year";
/** Key prefix for current corpus in session */
final static String CORPUS_ = "corpus_";
/** A filter for documents */
final static Query QUERY_CHAPTER = new TermQuery(new Term(Alix.TYPE, DocType.chapter.name()));

static String formatScore(double real)
{
  if (real == 0) return "0";
  if (real == (int)real) return ""+(int)real;
  int offset = (int)Math.log10(real);
  if (offset < -3) return dfdec5.format(real);
  if (offset > 4) return ""+(int)real;
  
  // return String.format("%,." + (digits - offset) + "f", real)+" "+offset;
  return dfdec2.format(real);
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


/**
 * Build a filtering query with a corpus
 */
public static Query corpusQuery(Corpus corpus, Query query) throws IOException
{
  if (corpus == null) return query;
  BitSet filter= corpus.bits();
  if (filter == null) return query;
  if (query == null) return new CorpusQuery(corpus.name(), filter);
  return new BooleanQuery.Builder()
    .add(new CorpusQuery(corpus.name(), filter), Occur.FILTER)
    .add(query, Occur.MUST)
  .build();
}

/** 
 * All pars for all page 
 */
public class Pars {
  String fieldName; // field to search
  String book; // restrict to a book
  String q; // word query
  Cat cat; // word categories to filter
  Ranking ranking; // ranking algorithm, tf-idf like
  MI mi; // proba kind of scoring, not tf-idf
  Sim sim; // ?? TODO, better logic
  Mime mime; // mime type for output
  int limit; // results, limit of result to show
  int nodes; // number of nodes in wordnet
  Order order;// results, reverse
  int context; // coocs, context width in words
  int left; // coocs, left context in words
  int right; // coocs, right context in words
  boolean expression; // kwic, filter multi word expression
  
  int start; // start record in search results
  int hpp; // hits per page
  String href;
  String[] forms;
  DocSort sort;
  

}

public Pars pars(final PageContext page)
{
  Pars pars = new Pars();
  JspTools tools = new JspTools(page);
  
  pars.fieldName = tools.getString("f", TEXT);
  pars.q = tools.getString("q", null);
  pars.book = tools.getString("book", null); // limit to a book
  // Words
  pars.cat = (Cat)tools.getEnum("cat", Cat.NOSTOP); // 
  
  // ranking, sort… TODO unify
  pars.ranking = (Ranking)tools.getEnum("ranking", Ranking.bm25);
  pars.sim = (Sim)tools.getEnum("sim", Sim.g);
  pars.sort = (DocSort)tools.getEnum("sort", DocSort.year);
  pars.mi = (MI)tools.getEnum("mi", MI.g);
  //final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
  pars.order = (Order)tools.getEnum("order", Order.top);
  
  
  
  String format = tools.getString("format", null);
  //if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
  pars.mime = (Mime)tools.getEnum("format", Mime.html);
  

  final int limitMax = 500;
  pars.limit = tools.getInt("limit", limitMax);
  if (pars.limit < 1) pars.limit = limitMax;
  
  final int nodesMax = 300;
  final int nodesMid = 100;
  pars.nodes = tools.getInt("nodes", nodesMid);
  if (pars.nodes < 1) pars.nodes = nodesMid;
  if (pars.nodes > nodesMax) pars.nodes = nodesMax;
  
  // limit a bit if not csv
  if (pars.mime == Mime.csv);
  else if (pars.limit < 1 || pars.limit > limitMax) pars.limit = limitMax;
  
  // coocs
  pars.left = tools.getInt("left", -1);
  pars.right = tools.getInt("right", -1);
  /*
  if (pars.left < 0) pars.left = 0;
  else if (pars.left > 10) pars.left = 50;
  pars.right = tools.getInt("right", 5);
  if (pars.right < 0) pars.right = 0;
  else if (pars.right > 10) pars.right = 50;
  */
  pars.context = tools.getInt("context", -1);
  if (pars.context > 0 ) {
    if (pars.context < 3) pars.context = 3;
    pars.left = pars.context / 2;
    pars.right = pars.context / 2;
  }
  else if (pars.left > 1 || pars.right > 1) {
    pars.context = 1 + pars.left + pars.right;
  }
  else {
    pars.context = 50;
    pars.left = 5;
    pars.right = 5;
  }
  
  // paging
  final int hppDefault = 100;
  final int hppMax = 1000;
  pars.expression = tools.getBoolean("expression", false);
  pars.hpp = tools.getInt("hpp", hppDefault);
  if (pars.hpp > hppMax || pars.hpp < 1) pars.hpp = hppDefault;
  pars.sort = (DocSort)tools.getEnum("sort", DocSort.year);
  pars.start = tools.getInt("start", 1);
  if (pars.start < 1) pars.start = 1;
  


  return pars;
}

/**
 * Get default pars 
 */



/**
 * Get a bitSet of a query. Seems quite fast (2ms), no cache needed.
 */
/*
 public BitSet bits(Alix alix, Corpus corpus, String q) throws IOException
{
  Query query = buildQuery(alix, q, corpus);
  IndexSearcher searcher = alix.searcher();
  CollectorBits collector = new CollectorBits(searcher);
  searcher.search(query, collector);
  return collector.bits();
}
*/


public static final String BASE = "rougemont";
static String hrefHome = "";

%>
