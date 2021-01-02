<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@include file="jsp/prelude.jsp" %>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="alix.util.Top" %>

<%!
/**
 * Specific pars for this display
 */
class Pars {
  String fieldName;
  Cat cat;
  Ranking ranking;
  Order order;
  int limit;
  String q;
}

%>
<%
long time = System.nanoTime();
Alix alix = alix(pageContext);
JspTools tools = new JspTools(pageContext);
IndexReader reader = alix.reader();

// params for the page
Pars pars = new Pars();
pars.fieldName = TEXT;
pars.ranking = (Ranking)tools.getEnum("ranking", Ranking.chi2);
pars.cat = (Cat)tools.getEnum("cat", Cat.ALL);
pars.limit = tools.getInt("docid", 100);

int docId = tools.getInt("docid", -1); // get doc by lucene internal docId or persistant String id
String id = tools.getString("id", null);
String q = tools.getString("q", null); // if no doc, get params to navigate in a results series

Doc doc = null;
try { // load full document
  if (id != null) doc = new Doc(alix, id);
  else if (docId >= 0) {
    doc = new Doc(alix, docId);
    id = doc.id();
  }
}
catch (IllegalArgumentException e) { // doc not found
  id = null;
}

/*
// global variables
Corpus corpus = (Corpus)session.getAttribute(corpusKey);
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, sort);
ScoreDoc[] hits = topDocs.scoreDocs;
if (hits.length == 0) {
  topDocs = null;
  start = 0;
}
if (start < 1 || start >= hits.length) start = 1;
//if a query, or a sort specification, provide navigation in documents
if (doc == null && start > 0) {
docId = hits[start - 1].doc;
doc = new Doc(alix, docId);
id = doc.id();
}

*/






// bibl ref with no tags
String title = "";
if (doc != null) title = ML.detag(doc.doc().get("scope"));

SortField sf2 = new SortField(Alix.ID, SortField.Type.STRING);
%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="ddr_head.jsp" %>
    <title>Livres</title>
    <link href="<%= hrefHome %>vendor/teinte.css" rel="stylesheet"/>
    <script>
<%
if (doc != null) { // document id is verified, give it to javascript
  out.println("var docLength = "+doc.length(TEXT)+";");
  out.println("var docId = \""+doc.id()+"\";");
}
%>
    </script>
  </head>
  <body>
    <header>
      <%@ include file="tabs.jsp" %>
    </header>
    <main>
      <form class="search" id="search" autocomplete="off" onsubmit="return false;" action="#" role="search">
        <input type="submit" style="position: absolute; left: -9999px; width: 1px; height: 1px;" tabindex="-1" />
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
        <label>Chercher un titre
          <br/><input id="id" name="id" value="<%=id%>" autocomplete="off" size="13"/>
          <input id="titles" name="titles" aria-describedby="titles-hint" placeholder="am… dia… eu… fed…" size="50"/>
          <div class="progress"><div></div></div>
          <div class="suggest"></div>
        </label>
        <!-- 
        
        <input id="q" name="q" value="<%=JspTools.escape(q)%>" autocomplete="off"/>
         -->
        <label>Filtrer par catégorie grammaticale
        <br/><select name="cat" onchange="this.form.submit()">
            <option/>
            <%= pars.cat.options() %>
         </select>
        </label>
        <br/><label>Algorithme d’ordre
        <br/><select name="ranking" onchange="this.form.submit()">
            <option/>
            <%= pars.ranking.options() %>
         </select>
        </label>
        
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
      <div class="row">
        <nav class="terms" id="sidebar">
        <%
if (doc != null) {
  FormEnum forms = doc.iterator(TEXT, pars.limit, pars.ranking.specif(), pars.cat.tags(), false);
  int no = 1;
  while (forms.hasNext()) {
    forms.next();
    out.print("<div>");
    // out.print(dfscore.format(forms.score()) + " ");
    out.print(forms.label());
    out.println("</div>");
  }
}
        
        %>
        </nav>
        <div class="text">
    <%
      if (doc != null) {
      out.println("<div class=\"heading\">");
      out.println(doc.doc().get("bibl"));
      out.println("</div>");
      // hilite
      if (!"".equals(q)) {
        String[] terms = alix.forms(q);
        out.print(doc.hilite(TEXT, terms));
      }
      else {
        out.print(doc.doc().get(TEXT));
      }
        }
    %>
        
        </div>
      </div>
    </main>
    <a href="#" id="gotop">▲</a>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
    <script src="<%= hrefHome %>static/alix.js">//</script>
  </body>
</html>