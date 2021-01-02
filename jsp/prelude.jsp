<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.FileInputStream" %>
<%@ page import="java.io.FileNotFoundException"%>
<%@ page import="java.io.PrintWriter" %>
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
<%@ page import="alix.lucene.search.*" %>

<%@ page import="alix.lucene.util.Rail" %>
<%@ page import="alix.util.ML" %>
<%@ page import="alix.util.TopArray" %>
<%@ page import="alix.web.*" %>
<%!
static String baseName = "rougemont";

final static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
final static DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);
static final DecimalFormat dfdec3 = new DecimalFormat("0.###", ensyms);
static final DecimalFormat dfdec2 = new DecimalFormat("0.##", ensyms);
static final DecimalFormat dfdec1 = new DecimalFormat("0.0", ensyms);
static final DecimalFormat dfscore = new DecimalFormat("0.00000", ensyms);
/** Fields to retrieve in document for a book */
final static HashSet<String> BOOK_FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, "byline", "year", "title"}));
final static HashSet<String> CHAPTER_FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, Alix.ID, "year", "title", "analytic", "pages"}));


/** Field name containing canonized text */
final static String TEXT = "text";
/** Field Name with int date */
final static String YEAR = "year";
/** Key prefix for current corpus in session */
public static String CORPUS_ = "corpus_";
/** A filter for documents */
final static Query QUERY_CHAPTER = new TermQuery(new Term(Alix.TYPE, DocType.chapter.name()));

/**
 * Options for filters by grammatical types
 */
static public enum Cat implements Option {
  
  ALL("Tout", null),
  NOSTOP("Mots pleins", new TagFilter().setAll().noStop(true)), 
  SUB("Substantifs", new TagFilter().setGroup(Tag.SUB)), 
  NAME("Noms propres", new TagFilter().setGroup(Tag.NAME)),
  VERB("Verbes", new TagFilter().setGroup(Tag.VERB)),
  ADJ("Adjectifs", new TagFilter().setGroup(Tag.ADJ)),
  ADV("Adverbes", new TagFilter().setGroup(Tag.ADV)),
  STOP("Mots vides", new TagFilter().setAll().clearGroup(Tag.SUB).clearGroup(Tag.NAME).clearGroup(Tag.VERB).clearGroup(Tag.ADJ).clear(0)), 
  NULL("Mots inconnus", new TagFilter().set(0)), 
  ;
  final public String label;
  final public TagFilter tags;
  private Cat(final String label, final TagFilter tags) {  
    this.label = label ;
    this.tags = tags;
  }
  public TagFilter tags(){ return tags; }
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
 * Build a text query fron a String and an optional Corpus.
 * Will return null if there is no terms in the query,
 * even if there is a corpus.
 */
public static Query buildQuery(Alix alix, String q, Corpus corpus) throws IOException
{
  Query qFilter = null;
  if (corpus != null) qFilter = new CorpusQuery(corpus.name(), corpus.bits());
  Query qWords = alix.query(TEXT, q);
  if (qWords != null && qFilter != null) {
    return new BooleanQuery.Builder()
      .add(qFilter, Occur.FILTER)
      .add(qWords, Occur.MUST)
      .build();
  }
  if (qWords != null) return qWords;
  if (qFilter != null) return qFilter;
  return QUERY_CHAPTER;
}

/**
 * Get a cached set of results.
 * Ensure to always give something.
 * Seems quite fast (2ms), no cache needed.
 * Cache bug if corpus is changed under same name.
 */
public TopDocs getTopDocs(PageContext page, Alix alix, Corpus corpus, String q, DocSort sorter) throws IOException
{
  Query query = buildQuery(alix, q, corpus);
  Sort sort = sorter.sort();
  TopDocs topDocs = null;
  IndexSearcher searcher = alix.searcher();
  int totalHitsThreshold = Integer.MAX_VALUE;
  final int numHits = alix.reader().maxDoc();
  TopDocsCollector<?> collector;
  SortField sf2 = new SortField(Alix.ID, SortField.Type.STRING);
  Sort sort2 = new Sort(sf2);
  if (sort != null) {
    collector = TopFieldCollector.create(sort, numHits, totalHitsThreshold);
  }
  else {
    collector = TopScoreDocCollector.create(numHits, totalHitsThreshold);
  }
  /*
  if (similarity != null) {
    oldSim = searcher.getSimilarity();
    searcher.setSimilarity(similarity);
    searcher.search(query, collector);
    // will it be fast enough to not affect other results ?
    searcher.setSimilarity(oldSim);
  }
  else {
  }
  */
  searcher.search(query, collector);
  topDocs = collector.topDocs();
  return topDocs;
}




/**
 * Get a bitSet of a query. Seems quite fast (2ms), no cache needed.
 */
public BitSet bits(Alix alix, Corpus corpus, String q) throws IOException
{
  Query query = buildQuery(alix, q, corpus);
  IndexSearcher searcher = alix.searcher();
  CollectorBits collector = new CollectorBits(searcher);
  searcher.search(query, collector);
  return collector.bits();
}

public static Alix alix(final PageContext pageContext) throws IOException
{
  final String baseDir = pageContext.getServletContext().getRealPath("WEB-INF") ;
  final Alix alix = Alix.instance(baseDir + "/bases/" + baseName, new FrAnalyzer());
  return alix;
}

public static Properties props(final PageContext pageContext) throws IOException, FileNotFoundException, InvalidPropertiesFormatException
{
  final String baseDir = pageContext.getServletContext().getRealPath("WEB-INF") ;
  final Properties props = new Properties();
  props.loadFromXML(new FileInputStream(baseDir + "/" + baseName + ".xml"));
  return props;
}

%>
