<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.FileInputStream" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.util.Set" %>

<%@ page import="org.apache.lucene.analysis.Analyzer" %>
<%@ page import="org.apache.lucene.document.Document" %>
<%@ page import="org.apache.lucene.index.IndexReader" %>
<%@ page import="org.apache.lucene.index.Term" %>
<%@ page import="org.apache.lucene.search.BooleanClause.Occur" %>
<%@ page import="org.apache.lucene.search.BooleanQuery" %>
<%@ page import="org.apache.lucene.search.Collector" %>
<%@ page import="org.apache.lucene.search.IndexSearcher" %>
<%@ page import="org.apache.lucene.search.Query" %>
<%@ page import="org.apache.lucene.search.ScoreDoc" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="org.apache.lucene.search.Sort" %>
<%@ page import="org.apache.lucene.search.SortField" %>
<%@ page import="org.apache.lucene.search.TermQuery" %>
<%@ page import="org.apache.lucene.search.TopDocs" %>
<%@ page import="org.apache.lucene.search.TopDocsCollector" %>
<%@ page import="org.apache.lucene.search.TopFieldCollector" %>
<%@ page import="org.apache.lucene.search.TopScoreDocCollector" %>
<%@ page import="org.apache.lucene.util.BitSet" %>
<%@ page import="alix.web.Jsp" %>
<%@ page import="alix.web.Mime" %>
<%@ page import="alix.web.WordClass" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.Alix.FSDirectoryType" %>
<%@ page import="alix.lucene.DocType" %>
<%@ page import="alix.lucene.analysis.FrAnalyzer" %>
<%@ page import="alix.lucene.search.CollectorBits" %>
<%@ page import="alix.lucene.search.Corpus" %>
<%@ page import="alix.lucene.search.CorpusQuery" %>
<%@ page import="alix.lucene.search.FieldStats" %>
<%@ page import="alix.lucene.search.SimilarityOccs" %>
<%@ page import="alix.lucene.search.SimilarityTheme" %>
<%@ page import="alix.lucene.search.TermList" %>
<%@ page import="alix.lucene.search.TopTerms" %>
<%@ page import="alix.lucene.util.Rail" %>
<%@ page import="alix.web.Distance" %>
<%@ page import="alix.web.DocSort" %>
<%@ page import="alix.web.Select" %>
<%@ page import="alix.util.ML" %>
<%@ page import="alix.util.TopArray" %>
<%!
static String baseName = "rougemont";
static String hrefHome = "../";


final static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
final static DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);
static final DecimalFormat dfdec3 = new DecimalFormat("0.###", ensyms);
static final DecimalFormat dfdec2 = new DecimalFormat("0.##", ensyms);

/** Field name containing canonized text */
final static String TEXT = "text";
/** Field Name with int date */
final static String YEAR = "year";
/** Key prefix for current corpus in session */
public static String CORPUS_ = "corpus_";
/** A filter for documents */
final static Query QUERY_CHAPTER = new TermQuery(new Term(Alix.TYPE, DocType.chapter.name()));

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
  Query qWords = alix.qParse(TEXT, q);
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


/**
 * Was used for testing the similarities.
 */
public static Similarity getSimilarity(final String sortSpec)
{
  Similarity similarity = null;
  if ("dfi_chi2".equals(sortSpec)) similarity = new DFISimilarity(new IndependenceChiSquared());
  else if ("dfi_std".equals(sortSpec)) similarity = new DFISimilarity(new IndependenceStandardized());
  else if ("dfi_sat".equals(sortSpec)) similarity = new DFISimilarity(new IndependenceSaturated());
  else if ("tfidf".equals(sortSpec)) similarity = new ClassicSimilarity();
  else if ("lmd".equals(sortSpec)) similarity = new LMDirichletSimilarity();
  else if ("lmd0.1".equals(sortSpec)) similarity = new LMJelinekMercerSimilarity(0.1f);
  else if ("lmd0.7".equals(sortSpec)) similarity = new LMJelinekMercerSimilarity(0.7f);
  else if ("dfr".equals(sortSpec)) similarity = new DFRSimilarity(new BasicModelG(), new AfterEffectB(), new NormalizationH1());
  else if ("ib".equals(sortSpec)) similarity = new IBSimilarity(new DistributionLL(), new LambdaDF(), new NormalizationH3());
  else if ("theme".equals(sortSpec)) similarity = new SimilarityTheme();
  else if ("occs".equals(sortSpec)) similarity = new SimilarityOccs();
  return similarity;
}

%>
<%
response.setHeader("X-Frame-Options", "SAMEORIGIN");
final long time = System.nanoTime();
final Jsp tools = new Jsp(request, response, pageContext);

final String baseDir = getServletContext().getRealPath("WEB-INF") ;
final Properties props = new Properties();
props.loadFromXML(new FileInputStream(baseDir + "/" + baseName + ".xml"));
final Alix alix = Alix.instance(baseDir + "/bases/" + baseName, new FrAnalyzer());
final IndexSearcher searcher = alix.searcher();
final IndexReader reader = alix.reader();
final String corpusKey = "CORPUS_"+baseName;
%>