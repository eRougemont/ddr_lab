<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.uhighlight.UnifiedHighlighter" %>
<%@ page import="org.apache.lucene.search.uhighlight.DefaultPassageFormatter" %>
<%@ page import="alix.lucene.search.HiliteFormatter" %>
<%@include file="jsp/prelude.jsp"%>
<%!
public enum Sim implements Option {
  chi2("Chi2") {
    @Override
    public Similarity similarity() {
      return new SimilarityChi2();
    }
  },
  bm25("BM25") {
    @Override
    public Similarity similarity() {
      return new BM25Similarity();
    }
  },
  



  
  ;

  abstract public Similarity similarity();

  
  private Sim(final String label) {  
    this.label = label ;
  }

  // Repeating myself
  final public String label;
  public String label() { return label; }
  public String hint() { return null; }
}

%>
<%
long time = System.nanoTime();
Alix alix = alix(pageContext);
JspTools tools = new JspTools(pageContext);
IndexReader reader = alix.reader();

// Params for the page
final String fieldName = TEXT;
String q = tools.getString("q", null);
Sim sim = (Sim)tools.getEnum("sim", Sim.chi2);

//global variables
FieldFacet facet = alix.fieldFacet(Alix.BOOKID, fieldName);
String[] forms = alix.forms(q);
%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="ddr_head.jsp" %>
    
    <title>Livres</title>
  </head>
  <body>
    <header>
      <%@ include file="tabs.jsp" %>
    </header>
  
    <main>
      <div>
        <table class="sortable" width="100%">
          <caption>
            <form id="qform" target="_self">
              <input type="submit" style="position: absolute; left: -9999px; width: 1px; height: 1px;"  tabindex="-1" />
              <label>Trouver un chapitre (selon un ou plusieurs mots)
              <br/><input id="q" name="q" value="<%=JspTools.escape(q)%>" width="100" autocomplete="off"/>
              </label>
              <br/><label>Algorithme d’ordre
              <br/><select name="sim" onchange="this.form.submit()">
                  <option/>
                  <%= sim.options() %>
               </select>
              </label>
            </form>
          </caption>
          <thead>
            <tr>
              <td/>
              <th/>
              <th style="width: 15ex;">Titre</th>
              <th>Chapitre</th>
              <th>page</th>
              <th>score</th>
              <th/>
              <th/>
             </tr>
           </thead>
           <tbody>
        
    
<%
int len = 100;
Query query = alix.query("text", q);
if (query == null) query = new MatchAllDocsQuery();
IndexSearcher searcher = alix.searcher();
searcher.setSimilarity(sim.similarity());
TopDocs topDocs = searcher.search(query, len);
ScoreDoc[] hits = topDocs.scoreDocs;

/*
UnifiedHighlighter uHiliter = new UnifiedHighlighter(searcher, alix.analyzer());
uHiliter.setMaxLength(500000); // biggest text size to process
uHiliter.setFormatter(new  HiliteFormatter());
int docIds[] = new int[len];
for (int i = 0; i < len; i++) {
  docIds[i] = hits[i].doc;
}
Map<String, String[]> res = uHiliter.highlightFields(new String[]{fieldName}, query, docIds, new int[]{3});
String[] fragments = res.get(fieldName);
*/


final String href = "doc.jsp?q=" + q + "&amp;id="; // href link
boolean zero = false;
int no = 1;
for (ScoreDoc hit: hits) {
  // System.out.println(doc.score +" — " + alix.reader().document(doc.doc));
  final int docId = hit.doc;
  // n = dic.n();
  // a link should here send a query by book, isnt t ?
  // rebuild link from href prefix
  /*
   // could help to send a query according to this cursor
   href.append("&amp;start=" + (n+1)); // parenthesis for addition!
   href.append("&amp;hpp=");
   if (filtered || queried) href.append(hits);
   else href.append(docs);
  */
  /*
  if (!zero && dic.score() <= 0) {
    out.println("<hr/>");
    zero = true;
  }
  */
  Document doc = reader.document(docId, CHAPTER_FIELDS);
  out.println("<tr class=\"snip\">");
  // hits[i].doc
  out.println("<td class=\"no left\">" + no + "</td>");
  
  out.print("<td class=\"num\">");
  out.print(doc.get("year"));
  out.println("</td> ");
  out.print("<td class=\"title\">");
  out.print("<em class=\"title\">");
  out.print(doc.get("title"));
  out.println("</em>");
  out.println("</td>");

  out.print("<td class=\"scope\">");
  out.print("<a href=\"" + href + doc.get(Alix.ID) +"\">");
  out.print(doc.get("analytic"));
  out.print("</a>");
  out.println("</td>");
  out.print("<td>");
  out.print(doc.get("pages"));
  out.println("</td>");
  out.print("<td class=\"num\">");
  out.println(dfscore.format(hit.score));
  out.println("</td>");
  /*
  if (fragments[no - 1] != null) {
    out.print("<p class=\"frags\">");
    out.println(fragments[no - 1]);
    out.println("</p>");
  }
  */
  out.println("<td/><td class=\"no right\">" + no + "</td>");
  out.println("</tr>");
  no++;
}
%>
          </tbody>
        </table>
      </div>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
  </body>
</html>
