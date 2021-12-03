<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="alix.util.Top" %>
<%@include file="jsp/prelude.jsp" %>
<%
// params for the page
int max = 100;
pars.limit = tools.getInt("limit", 50);
if (pars.limit > max) pars.limit = max;
// best words for query, no names
pars.cat = (Cat)tools.getEnum("cat", Cat.STRONG);

int docId = tools.getInt("docid", -1); // get doc by lucene internal docId or persistant String id
String id = tools.getString("id", "");
String q = tools.getString("q", null); // if no doc, get params to navigate in a results series

String field = "text";

Doc doc = null;
try { // load full document
  if (!id.isEmpty()) {
    doc = new Doc(alix, id);
    docId = doc.docId();
  }
  else if (docId >= 0) {
    doc = new Doc(alix, docId);
    id = doc.id();
  }
}
catch (IllegalArgumentException e) { // doc not found
  id = "";
}



// bibl ref with no tags
String title = "";
if (doc != null) title = ML.detag(doc.doc().get("scope"));

SortField sf2 = new SortField(Alix.ID, SortField.Type.STRING);
%>
<!DOCTYPE html>
<html class="document">
  <head>
    <link href="<%= hrefHome %>vendor/teinte.css" rel="stylesheet"/>
    <%@ include file="local/head.jsp" %>
    <title>Livres</title>
    <script>
<%
if (doc != null) { // document id is verified, give it to javascript
  out.println("var docLength = " + doc.length(field) + ";");
  out.println("var docId = \""+doc.id()+"\";");
}
%>
    </script>
  </head>
  <body class="document">
    <header>
      <%@ include file="local/tabs.jsp" %>
      <form class="search" id="search" autocomplete="off" action="#" role="search">
      <!-- 
        <button name="magnify" type="button">
          <svg viewBox="0 0 24 24"  width="24px" height="24px">
            <path d="M15.5 14h-.79l-.28-.27C15.41 12.59 16 11.11 16 9.5 16 5.91 13.09 3 9.5 3S3 5.91 3 9.5 5.91 16 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"/>
          </svg>
        </button>
        <button name="reset" class="reset" type="reset">
          <svg viewBox="0 0 24 24"  width="24px" height="24px">
            <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
          </svg>
        </button>
       -->
        <%= selectCorpus(alix.name) %>,
        <label for="titles">Chercher un titre</label>
        <input id="titles" name="titles" aria-describedby="titles-hint" placeholder="am… dia… eu… fed…" size="50"/>
        <div class="progress"><div></div></div>
        <div class="suggest"></div>
        <input type="hidden" id="id" name="id" value="<%=id%>" autocomplete="off" size="13"/>
        <label>Mots clés :</label>
         <label for="cat">Filtrer</label>
         <select name="cat" onchange="this.form.submit()">
            <option></option>
            <%= pars.cat.options() %>
         </select>
        <label for="distrib">Score</label>
        <select name="distrib" onchange="this.form.submit()">
           <option></option>
           <%= pars.distrib.options() %>
        </select>
        <label for="q">Surligner</label>
         <input id="q" name="q" value="<%=JspTools.escape(q)%>" autocomplete="off"/>
        <button type="submit">▶</button>
        
        <%
        /*
        if (topDocs != null && start > 1) {
          out.println("<button name=\"prev\" type=\"submit\" onclick=\"this.form['start'].value="+(start - 1)+"\">◀</button>");
        }
        */
        %>
               <%
               /*
        if (topDocs != null) {
          long max = topDocs.totalHits.value;
          out.println("<span class=\"hits\"> / "+ max  + "</span>");
          if (start < max) {
            out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+(start + 1)+"\">▶</button>");
          }
        }
               */
        %>
      </form>
    </header>
    <main>
      <div class="row">
        <nav class="terms" id="sidebar">
        <%
          Query mlt = null;
        if (doc != null) {
          out.println(" <h5>Mots clés</h5>");
          BooleanQuery.Builder qBuilder = new BooleanQuery.Builder();
          FormEnum forms = doc.results(field, pars.distrib.scorer(), pars.cat.tags());
          forms.sort(FormEnum.Sorter.score, pars.limit, false);
          int no = 1;
          forms.reset();
          while (forms.hasNext()) {
            forms.next();
            String form = forms.form();
            if (form.trim().isEmpty()) continue;
            out.print("<a title=\"score : " + formatScore(forms.score()) + "\" href=\"?id=" + id + "&amp;q=" + JspTools.escape(form) + "\" class=\"form\">");
            // out.print(dfscore.format(forms.score()) + " ");
            out.print(forms.form());
            out.print(" <small>(" + forms.freq() + ")</small>");
            out.println("</a>");
            if (no < 30) {
              Query tq = new TermQuery(new Term(field, forms.form()));
              qBuilder.add(tq, BooleanClause.Occur.SHOULD);
            }
            no++;
          }
          mlt = qBuilder.build();
        }
        %>
        </nav>
        <div class="text">
    <%
    if (doc != null) {
      out.println("<div class=\"heading\">");
      out.println(doc.doc().get("bibl"));
      out.println("</div>");
      // mlt
      
      
      // hilite
      if (!"".equals(q)) {
        String[] terms = alix.forms(q, field);
        out.print(doc.hilite(field, terms));
      }
      else {
        out.print(doc.doc().get(field));
      }
        }
    %>
        
        </div>
        <nav class="seealso">
          <%
if (mlt != null) {
  out.println("<h5>Sur les mêmes sujets…</h5>");
  IndexSearcher searcher = alix.searcher();
  //test has been done, BM25 seems the best
  // Similarity oldSim = searcher.getSimilarity();
  // searcher.setSimilarity(new LMDirichletSimilarity());
  // searcher.setSimilarity(sim.similarity()); 
  TopDocs topDocs;
  topDocs = searcher.search(mlt, 20);
  // searcher.setSimilarity(oldSim);
  ScoreDoc[] hits = topDocs.scoreDocs;
  final String href = "?id=";
  final HashSet<String> DOC_SHORT = new HashSet<String>(Arrays.asList(new String[] {Alix.ID, Alix.BOOKID, "bibl"}));
  for (ScoreDoc hit: hits) {
    if (hit.doc == docId) continue;
    Document aDoc = reader.document(hit.doc, DOC_SHORT);
    out.print("<div class=\"bibl\">");
    out.print("<a href=\"" + href + aDoc.get(Alix.ID) +"\">");
    out.print(aDoc.get("bibl"));
    out.print("</a>");
    out.print("</div>");
  }
}
          %>
          
        </nav>
      </div>
    </main>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
    <script src="<%= hrefHome %>static/alix.js">//</script>
  </body>
</html>
