<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>


<%@ page import="org.apache.lucene.index.LeafReader"%>
<%@ page import="org.apache.lucene.index.LeafReaderContext"%>
<%@ page import="org.apache.lucene.index.PostingsEnum"%>
<%@ page import="org.apache.lucene.index.Terms"%>
<%@ page import="org.apache.lucene.index.TermsEnum"%>

<%!

%>
<%
//set response header according to extension requested
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", ".json", Set.of(".json", ".js", ".txt"));
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}

JSONObject json = new JSONObject();

// Build the filter
final String fname = TEXT_CLOUD;
final FieldText ftext = alix.fieldText(fname);


final String[] tags = tools.getStringSet(TAG);
final FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();
final int[] dates = tools.getIntRange(YEAR, new int[]{yearMin, yearMax});

//filter documents on query
BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
int clauses = 0;
if (dates == null || dates.length == 0) {
    // no dates
}
else if (dates.length == 1) {
    clauses++;
    queryBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.FILTER);
}
else if (dates.length == 2) {
    clauses++;
    queryBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.FILTER);
}
if (tags == null || tags.length == 0) {
    // no tags
}
else if (tags.length == 1) {
    clauses++;
    queryBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.FILTER);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    clauses++;
    queryBuild.add(tagBuild.build(), BooleanClause.Occur.FILTER);
}

// get docs as a filter

/*
*/
BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
BitSet docAll = searcher.search(new TermQuery(new Term("type", "article")), qbits);
// heere filter by article or book
queryBuild.add(new TermQuery(new Term("type", "article")), BooleanClause.Occur.FILTER);
BooleanQuery filterQuery = queryBuild.build();
BitSet docFilter = searcher.search(filterQuery, qbits);

// Build a json object
do {
    JSONObject desc = new JSONObject();
    json.put("desc", desc);
    desc.append("yearRange", yearMin);
    desc.append("yearRange", yearMax);
    
    // use same collector for points to ensure same size
    // global count of occs by year
    final int[] occs = new int[yearMax - yearMin + 1];
    final int[] freqs = new int[yearMax - yearMin + 1];
    for (int docId = 0; docId < reader.maxDoc(); docId++) {
        final int year = fint.docId4value(docId);
        if (year == Integer.MIN_VALUE) continue; // no year for this doc
        final int occsDoc = ftext.occsByDoc(docId);
        if (!docAll.get(docId)) continue;
        occs[year - yearMin] += occsDoc;
        if (!docFilter.get(docId)) continue;
        freqs[year - yearMin] += occsDoc;
    }
    JSONObject occsJson = new JSONObject();
    json.append("series", occsJson);
    occsJson.put("freqs", new JSONArray(freqs));
    occsJson.put("occs", new JSONArray(occs));
    
    int occsMin = Integer.MAX_VALUE;
    int occsMax = Integer.MIN_VALUE;
    long occsAll = alix.fieldText(TEXT).occsAll();
    for (final int o: occs) {
        if (o < occsMin) occsMin = o;
        if (o > occsMax) occsMax = o;
    }
    desc.append("occsRange", occsMin);
    desc.append("occsRange", occsMax);
    desc.put("occsAll", occsAll);
    // if no query, exit
    if (request.getParameter(Q) == null) break;

    // series
    final double[] freqrels = new double[yearMax - yearMin + 1];

    int series = 0;
    int freqMin = Integer.MAX_VALUE;
    int freqMax = Integer.MIN_VALUE;
    double freqrelMin = Double.MAX_VALUE;
    double freqrelMax = Double.MIN_VALUE;
    for (final String q: request.getParameterValues(Q)) {
        JSONObject qJson = new JSONObject();
        json.append("series", qJson);
        qJson.put("q", q);
        if (q == null || q.isBlank()) continue;
        Query query = qText(alix.analyzer(), fname, q);
        if (query == null) continue;
        qJson.put("query", query.toString());
        final FieldQuery fieldQuery = new FieldQuery(query, reader, true, true);
        Set<String> set = docStats.terms(TEXT_CLOUD, fieldQuery);
        if (set.size() <= 0 ) continue;
        String[] forms = set.toArray(new String[0]);
        qJson.put("forms", forms);
        // get occs by date, loop on all docs
        BytesRef[] formsBytes = ftext.bytesSorted(forms);
        if (formsBytes == null) continue;
        series++;
        
        Arrays.fill(freqs, 0);
        Arrays.fill(freqrels, 0.0);
        TopDocs results = searcher.search(query, 5000, Sort.INDEXORDER);
        ScoreDoc[] hits = results.scoreDocs;
        final int hitsLength = hits.length;
        // low level but efficient
        PostingsEnum docsEnum = null; // reuse
        for (LeafReaderContext context : reader.leaves()) {
            LeafReader leaf = context.reader();
            final int docBase = context.docBase;
            Terms terms = leaf.terms(fname);
            if (terms == null) continue;
            TermsEnum tenum = terms.iterator();
            for (int i = 0; i < formsBytes.length; i++) {
                final BytesRef bytes = formsBytes[i];
                if (bytes == null) continue;
                if (!tenum.seekExact(bytes)) {
                    continue;
                }
                docsEnum = tenum.postings(docsEnum, PostingsEnum.FREQS);
                int docLeaf;
                while ((docLeaf = docsEnum.nextDoc()) != DocIdSetIterator.NO_MORE_DOCS) {
                    final int docId = docBase + docLeaf;
                    if (!docFilter.get(docId)) continue; // document not in the filter
                    final int year = fint.docId4value(docId);
                    if (year == Integer.MIN_VALUE) continue; // no year for this doc
                    final int freq = docsEnum.freq();
                    freqs[year - yearMin] += freq;
                }
            }
        }
        // get min - max
        for (int i= 0; i < freqs.length; i++) {
            final int freq = freqs[i];
            if (freq < freqMin) freqMin = freq;
            if (freq > freqMax) freqMax = freq;
            double freqrel = 100.0 * freq / occs[i];
            if (occs[i] == 0) freqrel = 0;
            freqrels[i] = freqrel;
            if (freqrel < freqrelMin) freqrelMin = freqrel;
            if (freqrel > freqrelMax) freqrelMax = freqrel;
        }
        qJson.put("freqs", new JSONArray(freqs));
        qJson.put("freqrels", new JSONArray(freqrels));
    }
    if (series > 0) {
        desc.append("freqRange", freqMin);
        desc.append("freqRange", freqMax);
        desc.append("freqrelRange", freqrelMin);
        desc.append("freqrelRange", freqrelMax);
    }
} while(false);
json.put("time", ((System.nanoTime() - timeStart) / 1000000) + "ms");
out.println(json.toString(2));



%>
