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
<%!/** Not yet used, to resolve relatice paths */
static String hrefHome = "";
/** Load bases from WEB-INF/, one time */
static {
  if (!Webinf.bases) Webinf.bases();
}



final static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
final static DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);

static final DecimalFormat frdec = new DecimalFormat("###,###,###,###", frsyms);

static final DecimalFormat dfdec3 = new DecimalFormat("0.000", ensyms);
static final DecimalFormat dfdec2 = new DecimalFormat("0.00", ensyms);
static final DecimalFormat frdec2 = new DecimalFormat("###,###,###,##0.00", frsyms);
static final DecimalFormat dfdec1 = new DecimalFormat("0.0", ensyms);
static final DecimalFormat dfdec5 = new DecimalFormat("0.0000E0", ensyms);
static final DecimalFormat frdec5 = new DecimalFormat("0.0000E0", frsyms);
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
  return frdec2.format(real);
}

/*
static public enum Direction implements Option {
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
*/

public enum Field implements Option 
{
  text("Lemmes", "Comme dans un dictionnaire : verbes conjugués ⇒ infinitif, noms ou adjectifs accordés ⇒ masculin singulier"),
  text_orth("Orthographies", "Graphies normalisées : majuscule début de phrase, parce que…")
  ;
  private Field(final String label, final String hint) {  
    this.label = label;
    this.hint = hint;
  }
  final public String label;
  final public String hint;
  public String label() { return label; }
  public String hint() { return hint; }
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
  Field field; // field to search
  String book; // restrict to a book
  String q; // word query
  Cat cat; // word categories to filter
  Order order;// order in list of terms and facets
  int limit; // results, limit of result to show
  int nodes; // number of nodes in wordnet
  int context; // coocs, context width in words
  int left; // coocs, left context in words
  int right; // coocs, right context in words
  boolean expression; // kwic, filter multi word expression
  Mime mime; // mime type for output

  // too much scoring algo
  Distrib distrib; // ranking algorithm, tf-idf like
  MI mi; // proba kind of scoring, not tf-idf, [2, 2]

  
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
  
  pars.field = (Field)tools.getEnum("f", Field.text, "alixField");
  pars.q = tools.getString("q", null);
  pars.book = tools.getString("book", null); // limit to a book
  // Words
  pars.cat = (Cat)tools.getEnum("cat", Cat.NOSTOP); // 
  
  // ranking, sort… a bit a mess
  pars.distrib = (Distrib)tools.getEnum("distrib", Distrib.g);
  pars.mi = (MI)tools.getEnum("mi", MI.g);
  // default sort in documents
  pars.sort = (DocSort)tools.getEnum("sort", DocSort.score, "alixSort");
  //final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
  pars.order = (Order)tools.getEnum("order", Order.score, "alixOrder");
  
  
  
  String format = tools.getString("format", null);
  //if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
  pars.mime = (Mime)tools.getEnum("format", Mime.html);
  

  pars.limit = 100;
  pars.limit = tools.getInt("limit", pars.limit);
  // user should know his limits
  
  final int nodesMax = 300;
  final int nodesMid = 50;
  pars.nodes = tools.getInt("nodes", nodesMid);
  if (pars.nodes < 1) pars.nodes = nodesMid;
  if (pars.nodes > nodesMax) pars.nodes = nodesMax;
  
  // coocs
  pars.left = tools.getInt("left", 0);
  pars.right = tools.getInt("right", 0);
  if (pars.left < 0) pars.left = 0;
  if (pars.right < 0) pars.right = 0;
  if (pars.left + pars.right == 0) {
    pars.left = 5;
    pars.right = 5;
  }
  /*
  else if (pars.left > 10) pars.left = 50;
  pars.right = tools.getInt("right", 5);
  else if (pars.right > 10) pars.right = 50;
  */
  
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
 * Corpus selecto
 */
public String selectCorpus(final String corpusid)
{
  return selectCorpus(corpusid, null);
}
 
 public String selectCorpus(final String corpusid, String label)
{
  StringBuilder sb = new StringBuilder();
  if (Alix.pool.size() == 1) {
    for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
      sb.append("<strong>"+entry.getValue().props.get("label")+"</strong>");
    }
  }
  else {
    if (label == null) label="Corpus";
    sb.append("<label for=\"corpus\" title=\"Choisir une base de textes\">" + label + "</label>\n");
    sb.append("<select name=\"corpus\" oninput=\"this.form.submit();\">\n");
    for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
      String value = entry.getKey();
      sb.append("<option value=\"" + value + "\"");
      if (value.equals(corpusid)) sb.append(" selected=\"selected\"");
      sb.append(">" + entry.getValue().props.get("label") + "</option>\n");
    }
    sb.append("</select>\n");
  }
  return sb.toString();
}

/**
 * Book selector 
 */
public String selectBook(final Alix alix, String bookid) throws IOException
{
  StringBuilder sb = new StringBuilder();
  sb.append("<label for=\"book\" title=\"Limiter la sélection à un seul livre\">Livre</label>\n");
  sb.append("<select name=\"book\" onchange=\"this.form.submit()\">\n");
  sb.append("  <option value=\"\"></option>\n");
  int[] books = alix.books(sortYear);
  final int width = 40;
  for (int docId: books) {
    Document doc = alix.reader().document(docId, BOOK_FIELDS);
    String txt = "";
    txt = doc.get("year");
    if (txt != null) txt += ", ";
    txt += doc.get("title");
    String abid = doc.get(Alix.BOOKID);
    sb.append("<option value=\"" + abid + "\" title=\"" + txt + "\"" );
    if (abid.equals(bookid)) {
      sb.append(" selected=\"selected\"");
    }
    sb.append(">");
    if (txt.length() > width) sb.append(txt.substring(0, width));
    else sb.append(txt);
    sb.append("</option>\n");
  }
  sb.append("</select>\n");
  return sb.toString();
}

/**
 *
 */
public FormEnum freqList(Alix alix, Pars pars) throws IOException
{
  Corpus corpus = null;
  BitSet filter = null; // if a corpus is selected, filter results with a bitset
  if (pars.book != null) {
    final int bookid = alix.getDocId(pars.book);
    if (bookid < 0) pars.book = null;
    else filter = Corpus.bits(alix, Alix.BOOKID, new String[]{pars.book});
  }
  

  FieldText fieldText = alix.fieldText(pars.field.name());

  boolean reverse = false;
  // if (pars.order == Order.last) reverse = true;

  FormEnum results = null;
  if (pars.q != null) {
    FieldRail rail = alix.fieldRail(pars.field.name()); // get the tool for cooccurrences
    // prepare a result object to populate with co-occurences
    results = new FormEnum(fieldText); 
    // parames for rail
    results.filter = filter; // book filter
    results.left = pars.left; // left context
    results.right = pars.right; // right context
    results.tags = pars.cat.tags(); // filter word list by tags
    results.search = alix.forms(pars.q, pars.field.name()); // parse query as terms
    // for stats, global freq of searched terms
    int pivotsOccs = 0;
    for (String form: results.search) {
      pivotsOccs += fieldText.formOccs(form);
    }
    long found = rail.coocs(results); // populate the wordlist
    if (found > 0) {
      // parameters for sorting
      results.limit = pars.limit;
      results.mi = MI.g; // hard coded mutual-info algo, seems the best
      results.reverse = reverse;
      rail.score(results, pivotsOccs);
      // throw new IllegalArgumentException("rail.fieldName="+rail.fieldName);
    }
    else {
      // if nothing found, what should be done ?
    }
  }
  else {
    // final int limit, Specif specif, final BitSet filter, final TagFilter tags, final boolean reverse
    // dic = fieldText.iterator(pars.limit, pars.ranking.specif(), filter, pars.cat.tags(), reverse);
    // pars.distrib.scorer()
    results = fieldText.results(pars.cat.tags(), Distrib.bm25.scorer(), filter); // hard coded distribution, seems the best
    results.filter = filter; // keep en handle for later use
    results.tags = pars.cat.tags(); // keep en handle for later use
    
  }
  // is it good to sort freqList here ?
  return results;
}%>
<%
long time = System.nanoTime();
// Common to all pages, get an alix base and other shared data
JspTools tools = new JspTools(pageContext);
//get default parameters from request
Pars pars = pars(pageContext);
//Default base name, first in the pool
String corpusDefault = "alix";
if (Alix.pool.size() > 0) {
  corpusDefault = (String)Alix.pool.keySet().toArray()[0];
}
Alix alix = (Alix)tools.getMap("corpus", Alix.pool, corpusDefault, "alixCorpus");

IndexReader reader = null;
if (alix != null) reader = alix.reader();

%>
