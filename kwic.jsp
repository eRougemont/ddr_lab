<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/kwic.jsp" %>
<%@ include file="jsp/prelude.jsp" %>
<%

long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
IndexReader reader = alix.reader();


Pars pars = pars(pageContext);
pars.forms = alix.forms(pars.q);
pars.fieldName = tools.getString("f", TEXT); 

// build query and get results
long nanos = System.nanoTime();
Query query = null;
Query qWords = null;
Query qFilter = null;
if (pars.q != null) {
  qWords = alix.query(pars.fieldName, pars.q);
}
if (pars.book != null) {
  qFilter = new TermQuery(new Term(Alix.BOOKID, pars.book));
}
if (qWords != null && qFilter != null) {
  query = new BooleanQuery.Builder()
    .add(qFilter, Occur.FILTER)
    .add(qWords, Occur.MUST)
    .build();
}
else if (qWords != null) query = qWords;
else if (qFilter != null) query = qFilter;
else query = QUERY_CHAPTER;

TopDocs topDocs = null;
IndexSearcher searcher = alix.searcher();
int totalHitsThreshold = Integer.MAX_VALUE;
final int numHits = alix.reader().maxDoc();
TopDocsCollector<?> collector = null;

if (pars.sort != null && pars.sort.sort() != null) {
  collector = TopFieldCollector.create(pars.sort.sort(), numHits, totalHitsThreshold);
}
else {
  collector = TopScoreDocCollector.create(numHits, totalHitsThreshold);
}


searcher.search(query, collector);
topDocs = collector.topDocs();

out.println("<!-- get topDocs "+(System.nanoTime() - nanos) / 1000000.0 + "ms\" -->");

%>
<!DOCTYPE html>
<html>
  <head>
   <jsp:include page="ddr_head.jsp" flush="true" />
   <title><%= alix.props.get("label")%> [Alix]</title>
   <style>
span.left {display: inline-block; text-align: right; width: <%= Math.round(pars.left * 1.0)%>ex; padding-right: 1ex;}
    </style>
  </head>
  <body>
    <header>
     <jsp:include page="tabs.jsp" flush="true" />
    </header>
    <main>
      <form  class="search">
        <input type="hidden" name="f" value="<%= JspTools.escape(pars.fieldName) %>"/>
        <label>Chercher un ou plusieurs mots
        <button style="position: absolute; left: -9999px" type="submit">▶</button>
        <br/><input id="q" name="q" value="<%=JspTools.escape(pars.q)%>" autocomplete="off" size="60" autofocus="autofocus" 
          onfocus="this.setSelectionRange(this.value.length,this.value.length);"
          oninput="this.form['start'].value='';"
        />
        </label>
        <label>Filtrer les expressions <input type="checkbox" name="expression" value="true" <%= (pars.expression)?"checked=\"checked\"":"" %>/></label>
        <br/><label>Filtrer par livre
        <br/><select name="book" onchange="this.form.submit()">
             <option value=""></option>
             <%
int[] books = alix.books(sortYear);
for (int docId: books) {
  Document doc = reader.document(docId, BOOK_FIELDS);
  String abid = doc.get(Alix.BOOKID);
  out.print("<option value=\"" + abid + "\"");
  if (abid.equals(pars.book)) out.print(" selected=\"selected\"");
  out.print(">");
  out.print(doc.get("year"));
  out.print(", ");
  out.print(doc.get("title"));
  out.println("</option>");
}
                  %>
          </select>
        </label>
        <br/><select name="sort" onchange="this.form['start'].value=''; this.form.submit()" title="Ordre">
          <option/>
          <%= pars.sort.options() %>
        </select>
        <% // prev / next nav
        if (pars.start > 1 && pars.q != null) {
          int n = Math.max(1, pars.start-hppDefault);
          out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">◀</button>");
        }
        if (topDocs != null) {
          long max = topDocs.totalHits.value;
          out.println("<input  name=\"start\" value=\""+ pars.start+"\" autocomplete=\"off\" class=\"start num3\"/>");
          out.println("<span class=\"hits\"> / "+ max  + "</span>");
          int n = pars.start + pars.hpp;
          if (n < max) out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">▶</button>");
        }
        /*
        if (forms == null || forms.length < 2 );
        else if (expression) {
          out.println("<button title=\"Cliquer pour dégrouper les locutions\" type=\"submit\" name=\"expression\" value=\"false\">✔ Locutions</button>");
        }
        else {
          out.println("<button title=\"Cliquer pour grouper les locutions\" type=\"submit\" name=\"expression\" value=\"true\">☐ Locutions</button>");
        }
        */

        %>
        
       </form> 
       <pre><%= query %></pre>
       <% 
       pars.href = "doc.jsp?";
       kwic(pageContext, alix, topDocs, pars); 
       %>

    <% 
    /*
if (start > 1 && q != null) {
  int n = Math.max(1, start-hppDefault);
  out.println("<button name=\"prev\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">◀</button>");
}
    
    //  <input type="hidden" id="q" name="q" 
if (topDocs != null) {
  long max = topDocs.totalHits.value;
  out.println("<input  name=\"start\" value=\""+start+"\" autocomplete=\"off\" class=\"start\"/>");
  out.println("<span class=\"hits\"> / "+ max  + "</span>");
  int n = start + hpp;
  if (n < max) out.println("<button name=\"next\" type=\"submit\" onclick=\"this.form['start'].value="+n+"\">▶</button>");
}
    */
        %>
      <p> </p>
    </main>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
