<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/freqs.jsp" %>
<%
limitMax = 200;
%>
<!DOCTYPE html>
<html>
  <head>
   <%@ include file="ddr_head.jsp" %>
   <title><%=props.get("label")%> [Alix]</title>
  </head>
  <body>
    <header>
    <%@ include file="tabs.jsp" %>
    </header>
    <main>
      <table class="sortable" width="100%">
        <caption>
          <form id="sortForm">
               <%
if (q == null) {
  // out.println(max+" termes");
}
else {
  out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\""+left+"\"/>");
  out.print(q);
  out.println("<input style=\"width: 2em;\" name=\"right\" value=\""+right+"\"/>&gt;");
  out.println("<input type=\"hidden\" name=\"q\" value=\""+Jsp.escape(q)+"\"/>");
}
               %>
             <label>Sélectionner un livre de Rougemont (ou bien tous les livres)
             <br/><select name="book" onchange="this.form.submit()">
                  <option value="">TOUT</option>
                  <%
int[] books = alix.books(bookSort);
for (int docId: books) {
  Document doc = reader.document(docId, BOOK_FIELDS);
  String abid = doc.get(Alix.BOOKID);
  out.print("<option value=\"" + abid + "\"");
  if (abid.equals(bookid)) out.print(" selected=\"selected\"");
  out.print(">");
  out.print(doc.get("year"));
  out.print(", ");
  out.print(doc.get("title"));
  out.println("</option>");
}
                  %>
               </select>
             </label>
             
             <br/><label>Filtrer par catégorie grammaticale
             <br/><select name="cat" onchange="this.form.submit()">
                 <option/>
                 <%= cat.options() %>
              </select>
             </label>
             <br/><label>Algorithme d’ordre
             <br/><select name="ranking" onchange="this.form.submit()">
                 <option/>
                 <%= ranking.options() %>
              </select>
             </label>
             <br/><label>Direction
             <br/><select name="order" onchange="this.form.submit()">
                 <option/>
                 <%= order.options() %>
              </select>
             </label><button type="submit">Lancer la requête</button>
          </form>
        </caption>
        <thead>
          <tr>
            <td/>
            <th title="Forme graphique indexée">Graphie</th>
            <th title="Catégorie grammaticale">Catégorie</th>
            <th title="Nombre d’occurrences" class="num"> Occurrences</th>
            <th title="Nombre de chapitres" class="num"> Chapitres</th>
            <th title="Score selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <td/>
          <tr>
        </thead>
        <tbody>
          <% 
          String href = "books.jsp?ranking="+ranking+"&amp;q=";
          out.println(lines(forms, mime, href));
          
          %>
        </tbody>
      </table>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
