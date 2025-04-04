<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.similarities.*" %>

<%@ page import="com.github.oeuvres.alix.util.Top" %>
<%!

static final HashSet<String> DOC_FIELDS = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, ALIX_TYPE, BIBL, "cert", TOC, TEXT })
);
static final HashSet<String> SHORT_FIELDS = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_BOOKID, ALIX_ID, BIBL })
);
static final HashSet<String> TOC_FIELDS = new HashSet<String>(
    Arrays.asList(new String[] { TOC })
);

%>
<%
// pars
final String alixId = tools.getString("id", ""); // the alix id for the doc
final String q = tools.getString(Q, null); // words to query
final String qtype = tools.getString(QTYPE, ""); // where to search full text

final StringBuilder sb = new StringBuilder();

String bibl = "";
String title = "Piaget, 404, \"" + alixId + "\", texte introuvable";
String toc = "Pas de texte pour l’identifiant :\"" + alixId + "\"";
int docId = tools.getInt("docId", -1);
Document document = null;
boolean first;

final StoredFields storedFields = reader.storedFields();

if (docId < 0) {
    Query docQuery = new TermQuery(new Term(ALIX_ID, alixId));
    TopDocs docResults = searcher.search(docQuery, 10); // should be one only
    ScoreDoc[] docHits = docResults.scoreDocs;
    if (docHits.length < 1) { // send 404
        response.setStatus(404);
    }
    else {
        if (docHits.length > 1) {/* say something ? */}
        docId = docHits[0].doc;
    }
}
if (docId >= 0) {
    document = storedFields.document(docId, DOC_FIELDS);
    bibl = document.get(BIBL).replaceAll("<a [^>]+>", "").replaceAll("</a>", "");
    title = ML.detag(bibl);
    toc = document.get(TOC); // get a local toc even for chapter
}

%>
<!DOCTYPE html>
<html class="document">
    <head>
        <%@ include file="local/head.jsp" %>
        <title><%= title %></title>
    </head>
    <body class="document">
        <header id="header" class="header">
            <%@ include file="local/tabs.jsp" %>
        </header>
        <div class="reader">
            <aside id="toc" class="toc">
                <div class="toclocal"><%= toc %></div>
            </aside>
            <div id="main">
                <main>
                <%
String cert = document.get("cert");
cert = (cert == null)?"":" cert-low";
 %>
                <div id="doc" class="text<%=cert%>">
                    <div class="watermark">Texte non relu</div>
        <%

// build a query 
Query query = null;
final StringBuilder ruloccs = new StringBuilder();
String fieldName = TEXT_CLOUD;
if (document == null) {
    // no hilite needed if no doc
}
else if (q != null && WILD.equals(qtype)) {
    fieldName = TEXT;
    // to lower
    String myq = Char.toASCII(q).toLowerCase();
    // split terms
    String[] terms = alix.tokenize(myq, "search");
    BooleanQuery.Builder bqText = new BooleanQuery.Builder();
    for (String t: terms) {
        if (t.length() < 1) continue;
        bqText.add(new WildcardQuery(new Term(fieldName, t + '*')), BooleanClause.Occur.MUST);
        // if enough letters, search in middle of words
        if (t.length() >= 3) {
            bqText.add(new WildcardQuery(new Term(fieldName, '*' + t + '*')), BooleanClause.Occur.MUST);
        }
    }
    query = bqText.build();
}
else if (q != null) {
    query = qText(alix.analyzer(), fieldName, q, BooleanClause.Occur.SHOULD);
}


if (document == null) {
    out.println("<h1 class=\"error\">" + title + "</h1>");
}
// query, hilite occurencies
else if (query != null) {
    final String text = document.get(TEXT);
    int pointer = 0;
    final int length = text.length();
    ruloccs.append("<nav class=\"ruloccs\" id=\"" + alixId + "_ruloccs\">\n");
    final DecimalFormat dfdec1 = new DecimalFormat("0.#", ensyms);
    
    
    FieldQuery fieldQuery = new FieldQuery(query, reader, true, true);
    // get occurencies
    FieldTermStack fieldTermStack = new FieldTermStack(alix.reader(), docId, fieldName, fieldQuery);
    // merge them as phrases
    FieldPhraseList phrases = new FieldPhraseList(fieldTermStack, fieldQuery);
    for (FieldPhraseList.WeightedPhraseInfo phrase: phrases.getPhraseList()) {
        final int start = phrase.getStartOffset();
        final int end = phrase.getEndOffset();
        final String form = text.substring(start, end);
        
        final FieldTermStack.TermInfo tinfo = phrase.getTermsInfos().get(0);
        final int position = tinfo.getPosition();
        final String idPos = "pos" + position;

        out.print(text.substring(pointer, start));
        out.print("<mark id=\"pos" + position + "\">");
        out.print(form);
        out.print("</mark>");
        ruloccs.append("<a title=\"" + ML.detag(form) + "\" class=\"occ\" href=\"#pos" + position + "\" style=\"top: " + dfdec1.format(100.0 * start / length)
        + "%\"> </a>\n");
        pointer = end;
    }
    
    ruloccs.append("</nav>\n");
    out.print(text.substring(pointer)); // do not forget last span.
}
// display doc
else {
    String text = document.get(TEXT);
    out.print(text);
}
        %>
                    </div>
                <%=ruloccs%>
                </main>
                <div id="seealso">
            <%
Query mlt = null;
first = true;
if (document != null) {
    out.println("<p class=\"terms\">");
    out.println("   <label>Mots clés : </label>");
    BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
    FormEnum forms = Doc.formEnum(alix, docId, TEXT_CLOUD, Distrib.G, TagFilter.NOSTOP);
    forms.sort(FormEnum.Order.SCORE, 50, false);
    int no = 1;
    forms.reset();
    while (forms.hasNext()) {
        forms.next();
        String form = forms.form();
        if (form.trim().isEmpty()) continue;
        // out.print("<a title=\"score : " + formatScore(forms.score()) + "\" href=\"?id=" + alixId + "&amp;q=" + JspTools.escape(form) + "\" class=\"form\">");
        // out.print(dfscore.format(forms.score()) + " ");
        if (no <= 20) {
            if (first) first = false;
            else out.print(", ");
            out.print(forms.form());
            out.print(" <small>(" + forms.freq() + ")</small>");
            if (no == 20) {
                out.print("…");
            }
        }
        // out.println("</a>");
        if (no < 30) {
          Query tq = new TermQuery(new Term(TEXT_CLOUD, forms.form()));
          qBuilder.add(tq, BooleanClause.Occur.SHOULD);
        }
        no++;
    }
    mlt = qBuilder.build();
}

    %>
                    <nav class="seealso">
                    <%
if (mlt != null) {
    out.println("<h5>Sur les mêmes sujets…</h5>");
    //test has been done, BM25 seems the best
    // Similarity oldSim = searcher.getSimilarity();
    // searcher.setSimilarity(new LMDirichletSimilarity());
    // searcher.setSimilarity(sim.similarity()); 
    TopDocs topDocs;
    topDocs = searcher.search(mlt, 7);
    // searcher.setSimilarity(oldSim);
    ScoreDoc[] hits = topDocs.scoreDocs;
    
    // snipets for long texts
    FieldQuery fieldQuery = new FieldQuery(mlt, reader, true, true);
    FastVectorHighlighter fvh = new FastVectorHighlighter();
    FragListBuilder fragListBuilder = new SimpleFragListBuilder();
    FragmentsBuilder fragmentsBuilder = new SimpleFragmentsBuilder();
    Encoder encoder = new DefaultEncoder();
    Set<String> matchedFields = new HashSet<>(Arrays.asList(TEXT_CLOUD));
    
    for (ScoreDoc hit: hits) {
        if (hit.doc == docId) continue;
        Document docsee = storedFields.document(hit.doc, SHORT_FIELDS);
        final String seeBibl = docsee.get("bibl").replaceAll("<a [^>]+>", "").replaceAll("</a>", "");

        out.print("<a class=\"seealso\" href=\"" + docsee.get(ALIX_ID) +"\">");
        out.print("<h4>" + seeBibl + "</h4>");
        
        String[] fragments = fvh.getBestFragments(
            fieldQuery,
            reader,
            hit.doc,
            TEXT, // stored field
            matchedFields, // search field
            100,
            5,
            fragListBuilder,
            fragmentsBuilder,
            new String[]{"[mark]"},
            new String[]{"[/mark]"}, 
            encoder
        );
        // no fragment found ?
        if (fragments == null) continue;
        out.println("<p class=\"frag\">");
        first = true;
        for (String frag: fragments) {
            if (frag == null) continue;
            if (first) first = false;
            else out.print(" […] ");
            // replace is an inefficent hack, detag should allow include or exclude
            out.print(ML.detag(frag).replace("[mark]", "<mark>").replace("[/mark]", "</mark>"));
        }
        out.println("</p>");
        out.print("</a>");
    }
}
                    %>
                    </nav>

                </div>
            </div>
            <aside class="notes">
                <header class="bibl"><%= bibl %></header>
                <a href="#seealso">Textes similaires</a>
            </aside>
        </div>
        <%@include file="local/footer.jsp" %>
        <% out.println("<!-- time\" : \"" + (System.nanoTime() - timeStart) / 1000000.0 + "ms\" -->"); %>
    </body>
</html>
