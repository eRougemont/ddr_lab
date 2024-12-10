<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!

%>
<%
// set response header according to extension requested
response.setHeader("Access-Control-Allow-Origin", "*"); // cross domain fo browsers
String ext = tools.getString("ext", ".json", Set.of(".json", ".js", ".txt"));
String mime = pageContext.getServletContext().getMimeType("a" + ext);
if (mime != null) {
    response.setContentType(mime);
}

JSONObject json = new JSONObject();
JSONObject desc = new JSONObject();
json.put("desc", desc);

final String fieldName = tools.getString(F, "text_cloud");
final FieldText ftext = alix.fieldText(fieldName);
final FieldInt fint = alix.fieldInt(YEAR);
final int[] dates = tools.getIntRange(YEAR, new int[]{fint.min(), fint.max()});
desc.put("dates", dates);
final String[] tags = tools.getStringSet(TAG);
desc.put("tags", tags);

final int total = searcher.count(new TermQuery(new Term(ALIX_TYPE, TEXT)));


BooleanQuery.Builder filterBuild = new BooleanQuery.Builder();
if (dates == null || dates.length == 0) {
    // if book, no dates
}
else if (dates.length == 1) {
    filterBuild.add(IntField.newExactQuery(YEAR, dates[0]), BooleanClause.Occur.MUST);
}
else if (dates.length == 2) {
    filterBuild.add(IntField.newRangeQuery(YEAR, dates[0], dates[1]), BooleanClause.Occur.MUST);
}

if (tags == null || tags.length == 0) {
    // if book, no tags
}
else if (tags.length == 1) {
    filterBuild.add(new TermQuery(new Term(TAG, tags[0])), BooleanClause.Occur.MUST);
}
else if (tags.length > 1) {
    BooleanQuery.Builder tagBuild = new BooleanQuery.Builder();
    for (final String tag: tags) {
        tagBuild.add(new TermQuery(new Term(TAG, tag)), BooleanClause.Occur.SHOULD);
    }
    filterBuild.add(tagBuild.build(), BooleanClause.Occur.MUST);
}
filterBuild.add(new TermQuery(new Term(ALIX_TYPE, TEXT)), BooleanClause.Occur.MUST);
Query filterQuery = filterBuild.build();
BitsCollectorManager qbits = new BitsCollectorManager(reader.maxDoc());
BitSet docFilter = searcher.search(filterQuery, qbits);

BytesRef[] formsBytes = null;
do {
    String[] textPars = request.getParameterValues(Q);
    desc.put(Q, textPars);
    if (textPars == null) break;
    BooleanQuery.Builder textBuild = new BooleanQuery.Builder();
    for (final String q: textPars) {
        if (q == null || q.isBlank()) continue;
        Query query = qText(alix.analyzer(), fieldName, q);
        if (query == null) continue;
        textBuild.add(query, BooleanClause.Occur.SHOULD);
    }
    Query textQuery = textBuild.build();
    desc.put("query", textQuery);
    if (textQuery == null) break;
    // filter query here ?
    final FieldQuery fieldQuery = new FieldQuery(
        new BooleanQuery.Builder()
            .add(filterQuery, FILTER)
            .add(textQuery, MUST)
        .build()
    , reader, true, true);
    Set<String> set = docStats.terms(TEXT_CLOUD, fieldQuery);
    if (set == null) break;
    String[] forms = set.toArray(new String[0]);
    Arrays.sort(forms);
    desc.put("forms", forms);
    formsBytes = ftext.bytesSorted(forms);
} while (false);

desc.put("filter", filterQuery);
desc.put("q", formsBytes);
desc.put("docsAll", ftext.docsAll());
desc.put("occsAll", ftext.occsAll());


//get the stats from the tag field
final FieldInfo info = FieldInfos.getMergedFieldInfos(reader).fieldInfo(TAG);
if (info != null) {
    final FieldFacet tagField = alix.fieldFacet(TAG);
    FormEnum tagEnum = tagField.formEnum(ftext, docFilter, formsBytes, Distrib.G);
    desc.put("hitsAll", tagEnum.hitsAll());
    desc.put("freqAll", tagEnum.freqAll());
    
    final JSONObject data = new JSONObject();
    json.put("data", data);


    // maybe use in loop, even if same info is in desc
    data.put("ALL", new JSONObject()
        .put("docs", ftext.docsAll())
        .put("hits", tagEnum.hitsAll())
        .put("occs", ftext.occsAll())
        .put("freq", tagEnum.freqAll())
    );

    // if nothing found, no Freq for sort
    // tagEnum.sort(FormIterator.Order.FREQ);
    tagEnum.reset();
    while (tagEnum.hasNext()) {
        tagEnum.next();
        data.put(tagEnum.form(), new JSONObject()
            .put("docs", tagEnum.docs())
            .put("hits", tagEnum.hits())
            .put("occs", tagEnum.occs())
            .put("freq", tagEnum.freq())
        );
    }

}

desc.put("time", ((System.nanoTime() - timeStart) / 1000000) + "ms");
out.println(json.toString(2));



%>