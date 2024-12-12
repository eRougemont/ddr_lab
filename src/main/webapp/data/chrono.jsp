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
FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();
final String fname = TEXT_CLOUD;
final FieldText ftext = alix.fieldText(fname);


//filter documents 
BooleanQuery.Builder queryBuild = new BooleanQuery.Builder();
// default chrono filter, articles 
// queryBuild.add(new TermQuery(new Term("type", "article")), BooleanClause.Occur.FILTER);
queryBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.FILTER);

BitSet filterDocs = null;
BooleanQuery filterQuery = queryBuild.build();
BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
filterDocs = searcher.search(filterQuery, qbits);

// Build a json object
do {
    JSONObject desc = new JSONObject();
    json.put("desc", desc);
    desc.append("yearRange", yearMin);
    desc.append("yearRange", yearMax);
    
    // use same collector for points to ensure same size
    final int[] points = new int[yearMax - yearMin + 1];
    // global count of occs by year
    for (int docId = 0; docId < reader.maxDoc(); docId++) {
        if (!filterDocs.get(docId)) continue;

        final int year = fint.docId4value(docId);
        if (year == Integer.MIN_VALUE) continue; // no year for this doc
        final int occs = ftext.occsByDoc(docId);
        points[year - yearMin] += occs;
    }
    JSONObject occsJson = new JSONObject();
    json.append("series", occsJson);
    occsJson.put("points", new JSONArray(points));
    
    int occsMin = Integer.MAX_VALUE;
    int occsMax = Integer.MIN_VALUE;
    for (final int occs: points) {
        if (occs < occsMin) occsMin = occs;
        if (occs > occsMax) occsMax = occs;
    }
    desc.append("occsRange", occsMin);
    desc.append("occsRange", occsMax);
    // if no query, exit
    if (request.getParameter(Q) == null) break;
    
    int freqMin = Integer.MAX_VALUE;
    int freqMax = Integer.MIN_VALUE;
    
    
    
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
        Arrays.fill(points, 0);
        TopDocs results = searcher.search(query, 5000, Sort.INDEXORDER);
        ScoreDoc[] hits = results.scoreDocs;
        final int hitsLength = hits.length;
        
        // get docs as a filter
        java.util.BitSet docs = new java.util.BitSet(reader.maxDoc());
        for (int i = 0; i < hitsLength; i++) {
            final int docId = hits[i].doc;
            if (!filterDocs.get(docId)) continue;
            docs.set(docId);
        }
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
                    if (!docs.get(docId)) continue; // document not in the filter
                    final int year = fint.docId4value(docId);
                    if (year == Integer.MIN_VALUE) continue; // no year for this doc
                    final int freq = docsEnum.freq();
                    points[year - yearMin] += freq;
                }
            }
        }
        // get min - max
        for (final int freq: points) {
            if (freq < freqMin) freqMin = freq;
            if (freq > freqMax) freqMax = freq;
        }
        qJson.put("points", new JSONArray(points));
    }
    desc.append("freqRange", freqMin);
    desc.append("freqRange", freqMax);
} while(false);
json.put("time", ((System.nanoTime() - timeStart) / 1000000) + "ms");
out.println(json.toString(2));



%>
