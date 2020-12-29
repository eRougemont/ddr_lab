<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="jsp/prelude.jsp"%>

<%
// Params for the page
String q = tools.getString("q", null);
Ranking ranking = (Ranking)tools.getEnum("ranking", Ranking.alpha);

//global variables
FieldFacet facet = alix.fieldFacet(Alix.BOOKID, TEXT);
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
      <table class="sortable" width="100%">
        <caption>
          <form id="qform" target="_self">
            <input type="submit" style="position: absolute; left: -9999px; width: 1px; height: 1px;"  tabindex="-1" />
            <label>Classer les livres selon un ou plusieurs mots
            <br/><input id="q" name="q" value="<%=JspTools.escape(q)%>" width="100" autocomplete="off"/>
            </label>
            <br/><label>Algorithme d’ordre
            <br/><select name="ranking" onchange="this.form.submit()">
                <option/>
                <%= ranking.options() %>
             </select>
            </label>
          </form>
        </caption>
        <thead>
          <tr>
            <td/>
            <th>Livre</th>
            <th title="Nombre d’occurrences" class="num"> Occurrences</th>
            <th title="Nombre de chapitres" class="num"> Chapitres</th>
            <th title="Score selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <td/>
          <tr>
        </thead>
        <tbody>
        
    
<%
FormEnum dic = facet.iterator(-1, null, forms, ranking.specif());
/* 
// Hack to use facet as a navigator in results, cache results in the facet order
TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, DocSort.author);
int[] nos = facet.nos(topDocs);
dic.setNos(nos);
*/  
// build a resizable href link
final String href = "kwic.jsp?q=" + q + "&amp;book=";
// resend a query somewhere ?
boolean zero = false;
int no = 1;
while (dic.hasNext()) {
  dic.next();
  // n = dic.n();
  final int docs = dic.docsMatching();
  final long occs = dic.occsMatching();
  //in alpha order, do something if no match ?
  if (docs < 1) {
    // continue;
  }
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
  String id = dic.label();
  out.println("  <tr>");
  out.println("    <td class=\"no left\">" + no + "</td>");
  out.print("    <td class=\"form\">");
  out.print("<a href=\""+href+id+"\">");
  // out.print(dic.label());
  int docId = alix.getDocId(id);
  Document doc = reader.document(docId, BOOK_FIELDS);
  out.print(doc.get("year"));
  out.print(", ");
  out.print(doc.get("title"));

  out.print("</a>");
  out.println("</td>");
  out.print("    <td class=\"num\">");
  if (occs > 0) out.print(occs);
  out.println("</td>");
  out.print("    <td class=\"num\">");
  if (docs > 0) out.print(docs);
  out.println("</td>");
  // fréquence
  // sb.append(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
  out.print("    <td class=\"num\">");
  out.print(dfscore.format(dic.score()));
  out.println("</td>");
  out.println("    <td></td>");
/*
    if (filtered || queried) out.print(" <span class=\"docs\">("+hits+" / "+docs+")</span>    ");
    else out.print(" <span class=\"docs\">("+docs+")</span>    ");
    out.println("</div>");
  */
  out.println("    <td class=\"no right\">" + no + "</td>");
  out.println("</tr>");
  no++;
}
%>
        </tbody>
      </table>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
  </body>
</html>
