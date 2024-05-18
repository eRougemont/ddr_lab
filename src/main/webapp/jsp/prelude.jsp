<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.IOException"%>
<%@ page import="java.io.File"%>
<%@ page import="java.io.FileInputStream"%>
<%@ page import="java.io.FileNotFoundException"%>
<%@ page import="java.io.PrintWriter"%>
<%@ page import="java.nio.file.Path"%>
<%@ page import="java.lang.invoke.MethodHandles"%>
<%@ page import="java.text.DecimalFormat"%>
<%@ page import="java.text.DecimalFormatSymbols"%>
<%@ page import="java.util.*"%>

<%@ page import="org.apache.lucene.analysis.Analyzer"%>
<%@ page import="org.apache.lucene.document.Document"%>
<%@ page import="org.apache.lucene.index.IndexReader"%>
<%@ page import="org.apache.lucene.index.Term"%>
<%@ page import="org.apache.lucene.search.*"%>
<%@ page import="org.apache.lucene.search.similarities.*"%>
<%@ page import="org.apache.lucene.search.BooleanClause.*"%>
<%@ page import="org.apache.lucene.util.BitSet"%>
<%@ page import="static com.github.oeuvres.alix.Names.*"%>
<%@ page import="com.github.oeuvres.alix.fr.Tag"%>
<%@ page import="com.github.oeuvres.alix.fr.Tag.TagFilter"%>
<%@ page import="com.github.oeuvres.alix.lucene.Alix"%>
<%@ page import="com.github.oeuvres.alix.lucene.Alix.FSDirectoryType"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.FrAnalyzer"%>
<%@ page import="com.github.oeuvres.alix.lucene.analysis.FrDics"%>
<%@ page import="com.github.oeuvres.alix.lucene.search.*"%>

<%@ page import="com.github.oeuvres.alix.lucene.search.FieldRail"%>
<%@ page import="com.github.oeuvres.alix.util.ML"%>
<%@ page import="com.github.oeuvres.alix.util.TopArray"%>
<%@ page import="com.github.oeuvres.alix.web.*"%>
<%!/** Not yet used, to resolve relatice paths */
    static String hrefHome = "";
    static final String ALIX_LUCENEDIR = "alix.lucenedir";
    static final String ALIX_BASENAME = "rougemont";
    static final DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
    static final DecimalFormatSymbols ensyms = DecimalFormatSymbols.getInstance(Locale.ENGLISH);
    static final DecimalFormat frdec = new DecimalFormat("###,###,###,###", frsyms);
    static final DecimalFormat dfdec3 = new DecimalFormat("0.000", ensyms);
    static final DecimalFormat dfdec2 = new DecimalFormat("0.00", ensyms);
    static final DecimalFormat frdec2 = new DecimalFormat("###,###,###,##0.00", frsyms);
    static final DecimalFormat dfdec1 = new DecimalFormat("0.0", ensyms);
    static final DecimalFormat dfdec5 = new DecimalFormat("0.0000E0", ensyms);
    static final DecimalFormat frdec5 = new DecimalFormat("0.0000E0", frsyms);
    static final DecimalFormat dfScore = new DecimalFormat("0.00000", ensyms);
    /** Fields to retrieve in document for a book */
    static final HashSet<String> BOOK_FIELDS = new HashSet<String>(
            Arrays.asList(new String[] { ALIX_BOOKID, "byline", "year", "title" }));
    static final HashSet<String> CHAPTER_FIELDS = new HashSet<String>(
            Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, "year", "title", "analytic", "pages" }));
    static final Sort sortYear = new Sort(new SortField[] { new SortField("year", SortField.Type.INT),
            new SortField(ALIX_ID, SortField.Type.STRING), });
    /** Field Name with int date */
    static final String YEAR = "year";
    /** Key prefix for current corpus in session */
    static final String CORPUS_ = "corpus_";
    /** A filter for documents */
    static final Query QUERY_CHAPTER = new TermQuery(new Term(ALIX_TYPE, CHAPTER));
    /** File path for a lucene index */
    Path lucenepath;
    /** error message */
    String initErr;
    /**
     * Get basedir to write
     * 
     * @return
     * @throws ServletException
     */
    public void jspInit() {
        ServletContext context = getServletContext();
        String value = context.getInitParameter(ALIX_LUCENEDIR);
        lucenepath = Path.of(value);
        if (!lucenepath.isAbsolute()) {
            initErr = "Init param datadir is not an absolute file path: <Parameter name=\"datadir\" value=\"" + value
                            + "\" override=\"false\"/>";
            return;
        }
        if (!lucenepath.toFile().exists()) {
            initErr = "Init param datadir, impossible to create: <Parameter name=\"datadir\" value=\""
                    + value + "\" override=\"false\"/>";
            return;
        }
        if (!lucenepath.toFile().isDirectory()) {
            initErr = "Init param datadir, exists but is not a directory: <Parameter name=\"datadir\" value=\"" + value
                            + "\" override=\"false\"/>";
            return;
        }
    }

    static String formatScore(double real) {
        if (real == 0)
            return "0";
        if (real == (int) real)
            return "" + (int) real;
        int offset = (int) Math.log10(real);
        if (offset < -3)
            return dfdec5.format(real);
        if (offset > 4)
            return "" + (int) real;

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
    


    

    public enum Field implements Option {
        text("Lemmes",
                "Comme dans un dictionnaire : verbes conjugués ⇒ infinitif, noms ou adjectifs accordés ⇒ masculin singulier"),
        text_orth("Orthographies", "Graphies normalisées : majuscule début de phrase, parce que…");

        private Field(final String label, final String hint) {
            this.label = label;
            this.hint = hint;
        }

        final public String label;
        final public String hint;

        public String label() {
            return label;
        }

        public String hint() {
            return hint;
        }
    }

    /**
     * Build a filtering query with a corpus
     */
    public static Query corpusQuery(Corpus corpus, Query query) throws IOException {
        if (corpus == null)
            return query;
        BitSet filter = corpus.bits();
        if (filter == null)
            return query;
        if (query == null)
            return new CorpusQuery(corpus.name(), filter);
        return new BooleanQuery.Builder().add(new CorpusQuery(corpus.name(), filter), Occur.FILTER)
                .add(query, Occur.MUST).build();
    }

    /** 
     * All pars for all page 
     */
    public class Pars {
        Field field; // field to search
        String book; // restrict to a book
        String q; // word query
        OptionCat cat; // word categories to filter
        OptionOrder order;// order in list of terms and facets
        int limit; // results, limit of result to show
        int dist; // wordnet, context width in words
        int nodes; // number of nodes in wordnet
        int left; // coocs, left context in words
        int right; // coocs, right context in words
        boolean expression; // kwic, filter multi word expression
        OptionMime mime; // mime type for output
        int edges; // used to transmit an info to freqList
        int compac; // a compacity index for wordnet
        // too much scoring algo
        OptionDistrib distrib; // ranking algorithm, tf-idf like
        OptionMI mi; // proba kind of scoring, not tf-idf, [2, 2]

        int start; // start record in search results
        int hpp; // hits per page
        String href;
        String[] forms;
        OptionSort sort;

    }

    public Pars pars(final PageContext page) {
        Pars pars = new Pars();
        JspTools tools = new JspTools(page);

        pars.field = (Field) tools.getEnum("f", Field.text, "alixField");
        pars.q = tools.getString("q", null);
        pars.book = tools.getString("book", null); // limit to a book
        // Words
        pars.cat = (OptionCat) tools.getEnum("cat", OptionCat.NOSTOP); // 

        // ranking, sort… a bit a mess
        pars.distrib = (OptionDistrib) tools.getEnum("distrib", OptionDistrib.G);
        pars.mi = (OptionMI) tools.getEnum("mi", OptionMI.G);
        // default sort in documents
        pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.score, "alixSort");
        //final FacetSort sort = (FacetSort)tools.getEnum("sort", FacetSort.freq, Cookies.freqsSort);
        pars.order = (OptionOrder) tools.getEnum("order", OptionOrder.SCORE, "alixOrder");

        String format = tools.getString("format", null);
        //if (format == null) format = (String)request.getAttribute(Dispatch.EXT);
        pars.mime = (OptionMime) tools.getEnum("format", OptionMime.html);

        pars.limit = 100;
        pars.limit = tools.getInt("limit", pars.limit);
        pars.nodes = 40;
        pars.nodes = tools.getInt("nodes", pars.nodes);
        if (pars.nodes < 0) {
        	pars.nodes = 3;
        }
        if (pars.nodes > 250) {
            pars.nodes = 250;
        }
        pars.edges = tools.getInt("edges", pars.nodes*2);
        if (pars.edges < 0 ) pars.edges = 0;
        if (pars.edges > 500 ) pars.edges = 500;

        pars.dist = tools.getInt("dist", 50);
        if (pars.dist < 0) {
        	pars.dist = 1;
        }
        if (pars.dist > 250) {
        	pars.dist = 250;
        }

        // coocs
        pars.left = tools.getInt("left", 0);
        pars.right = tools.getInt("right", 0);
        if (pars.left < 0)
            pars.left = 0;
        if (pars.right < 0)
            pars.right = 0;
        if (pars.left + pars.right == 0) {
            pars.left = 5;
            pars.right = 5;
        }
        // against out of memory
        if (pars.left > 30) pars.left = 30;
        if (pars.right > 30) pars.right = 30;


        // paging
        final int hppDefault = 100;
        final int hppMax = 1000;
        pars.expression = tools.getBoolean("expression", false);
        pars.hpp = tools.getInt("hpp", hppDefault);
        if (pars.hpp > hppMax || pars.hpp < 1)
            pars.hpp = hppDefault;
        pars.sort = (OptionSort) tools.getEnum("sort", OptionSort.year);
        pars.start = tools.getInt("start", 1);
        if (pars.start < 1)
            pars.start = 1;

        return pars;
    }

    /**
     * Corpus selector
     */
    public String selectCorpus(final String corpusid) {
        return selectCorpus(corpusid, null);
    }

    public String selectCorpus(final String corpusid, String label) {
        StringBuilder sb = new StringBuilder();
        if (Alix.pool.size() == 1) {
            for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
                sb.append("<strong>" + entry.getValue().props.get("label") + "</strong>");
            }
        } 
        else {
            if (label == null)
                label = "Corpus";
            sb.append("<label for=\"corpus\" title=\"Choisir une base de textes\">" + label + "</label>\n");
            sb.append("<select name=\"corpus\" oninput=\"this.form.submit();\">\n");
            for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
                String value = entry.getKey();
                sb.append("<option value=\"" + value + "\"");
                if (value.equals(corpusid))
                    sb.append(" selected=\"selected\"");
                sb.append(">" + entry.getValue().props.get("label") + "</option>\n");
            }
            sb.append("</select>\n");
        }
        return sb.toString();
    }

    /**
     * Book selector
     */
    public String selectBook(final Alix alix, String bookid) throws IOException {
        StringBuilder sb = new StringBuilder();
        sb.append("<label for=\"book\" title=\"Limiter la sélection à un seul livre\">Livre</label>\n");
        sb.append("<select name=\"book\" onchange=\"this.form.submit()\">\n");
        sb.append("  <option value=\"\"></option>\n");
        int[] books = alix.books(sortYear);
        final int width = 40;
        for (int docId : books) {
            Document doc = alix.reader().document(docId, BOOK_FIELDS);
            String txt = "";
            txt = doc.get("year");
            if (txt != null)
                txt += ", ";
            txt += doc.get("title");
            String abid = doc.get(ALIX_BOOKID);
            sb.append("<option value=\"" + abid + "\" title=\"" + txt + "\"");
            if (abid.equals(bookid)) {
                sb.append(" selected=\"selected\"");
            }
            sb.append(">");
            if (txt.length() > width)
                sb.append(txt.substring(0, width));
            else
                sb.append(txt);
            sb.append("</option>\n");
        }
        sb.append("</select>\n");
        return sb.toString();
    }

    /**
     *
     */
    public FormEnum freqList(Alix alix, Pars pars) throws IOException {
        Corpus corpus = null;
        BitSet filter = null; // if a corpus is selected, filter results with a bitset
        if (pars.book != null) {
            final int bookid = alix.getDocId(pars.book);
            if (bookid < 0)
                pars.book = null;
            else
                filter = Corpus.bits(alix, ALIX_BOOKID, new String[] { pars.book });
        }

        FieldText ftext = alix.fieldText(pars.field.name());

        boolean reverse = false;
        // if (pars.order == Order.last) reverse = true;

        FormEnum results = null;
        int[] pivotIds = null;
        if (pars.q != null) {
            // get the pivots
            String[] words = alix.tokenize(pars.q, pars.field.name());
            pivotIds = ftext.formIds(words, filter);
            // no word found, what shall we do here ?
        }
        if (pivotIds == null) {
            // final int limit, Specif specif, final BitSet filter, final TagFilter tags, final boolean reverse
            // dic = fieldText.iterator(pars.limit, pars.ranking.specif(), filter, pars.cat.tags(), reverse);
            // pars.distrib.scorer()
            results = ftext.forms(filter, pars.cat.tags(), OptionDistrib.BM25); // hard coded distribution, seems the best
            results.filter = filter; // keep an handle for later use
            results.tags = pars.cat.tags(); // keep an handle for later use
        }
        else {
            // prepare a result object to populate with co-occurences
            FieldRail frail = alix.fieldRail(pars.field.name()); // get the tool for cooccurrences
            results = ftext.forms();
            results.filter = filter; // book filter
            results.left = pars.left; // left context
            results.right = pars.right; // right context
            results.tags = pars.cat.tags(); // filter word list by tags
            results.limit = pars.limit;
            if (pars.edges > 0) { // record edges
                results.edges();
            }
            // coocs(final FormEnum results, final int[] pivotIds, final int left, final int right, OptionMI mi)
            long found = frail.coocs(results, pivotIds, pars.left, pars.right, OptionMI.G); // populate the wordlist
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
Alix alix = Alix.instance("rougemont", lucenepath, null, null);

IndexReader reader = null;
if (alix != null) {
    reader = alix.reader();
}
%>
