<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="jsp/prelude.jsp" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.DecimalFormatSymbols" %>
<%@ page import="java.util.Locale" %>
<%!final static DecimalFormat dfScoreFr = new DecimalFormat("0.00000", frsyms);
final static DecimalFormat dfint = new DecimalFormat("###,###,##0", frsyms);
final static HashSet<String> FIELDS = new HashSet<String>(Arrays.asList(new String[] {Alix.BOOKID, "byline", "year", "title"}));
static Sort SORT = new Sort(new SortField("year", SortField.Type.INT));%>
<%
  // params for this page
String q = tools.getString("q", null);

    
String[] books = request.getParameterValues("book");
Corpus corpus;
if (books != null) {
  corpus = new Corpus(alix, books);
  session.setAttribute(corpusKey, corpus);
}
else {
  corpus = (Corpus)session.getAttribute(corpusKey);
}

Set<String> bookSet = null;
if (corpus != null) bookSet = corpus.books();
FieldFacet facet = alix.facet(Alix.BOOKID, TEXT);
/*
IntSeries years = alix.intSeries(YEAR); // to get min() max() year
TermList qTerms = alix.qTermList(TEXT, q);
boolean score = (qTerms != null && qTerms.size() > 0);
BitSet bits = bits(alix, corpus, q);
boolean author = (alix.info("author") != null);
*/
// get the dictionnary of terms, with no request nor filter
boolean score = false;
FormEnum terms = facet.iterator();
%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Rougemont 2.0, laboratoire</title>
    <link rel="stylesheet" type="text/css" href="static/ddrlab.css"/>
    <style type="text/css">
div.book {
  color: #999;
  white-space: nowrap;
}
label {
  cursor: pointer;
  white-space: nowrap;
}
:checked,
:checked + label {
  background: #FFF;
  color: #000;
}
button.save {
  display: block;
}
main {
  display: flex;
  positon:relative;
  height: 100%;
}
main form {
  width: 400px;
  max-width: 20%;
  height: 100%;
  overflow: auto;
  padding: 0.5rem;
}
main iframe {
  height: 100%;
}
    </style>
  </head>
  <body class="corpus">
    
    <main>
      <form>
        <label>
          <input id="checkall" type="checkbox" title="Sélectionner/déselectionner tout"/>
          Tout, sélectionner / déselectionner
        </label>
        <button class="save" type="submit">Enregistrer</button>
    <%
      // sorting

     
      // Hack to use facet as a navigator in results
      // get and cache results in facet order, find a index 
      // TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, DocSort.author);
      // int[] nos = facet.nos(topDocs);
      // dic.setNos(nos);
      while (terms.hasNext()) {
        terms.next();
        String bookid = terms.label();
        // String bookid = doc.get(Alix.BOOKID);
        Document doc = reader.document(alix.getDocId(bookid), FIELDS);
        // for results, do not diplay not relevant results
        // if (score && terms.occs() == 0) continue;

        out.println("<div class=\"book\">");
        out.print("    <input type=\"checkbox\" name=\"book\" id=\""+bookid+"\" value=\""+bookid+"\"");
        if (bookSet != null && bookSet.contains(bookid)) out.print(" checked=\"checked\"");
        out.println(" />");
        out.println("  <label for=\"" + bookid + "\">");
        out.println("    <span class=\"year\">"+doc.get("year")+",</span>");
        out.print("    <em class=\"title\">");
        // out.println("<a href=\"kwic?sort="+facetField+"&amp;q="+q+"&start="+(n+1)+"&amp;hpp="+hits+"\">");
        out.print(doc.get("title"));
        out.println("</em>");
        out.println("  </label>");
        out.println("</div>");
      }
    //  <a href="#" id="gotop">▲</a>
    %>
        <button type="submit">Enregistrer</button>
      </form>
      <iframe src="jsp/net.jsp"> </iframe>
    </main>
    <script src="static/ddrlab.js">//</script>
  </body>
</html>
