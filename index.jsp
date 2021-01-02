<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/freqs.jsp" %>
<%
long time = System.nanoTime();
Alix alix = alix(pageContext);
JspTools tools = new JspTools(pageContext);
Properties props = props(pageContext);
IndexReader reader = alix.reader();

// get default parameters from request
Pars pars = pars(pageContext);
Corpus corpus = null;
BitSet filter = null; // if a corpus is selected, filter results with a bitset
if (pars.book != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{pars.book});

final String field = TEXT; // the field to process

FieldText fstats = alix.fieldText(field);

boolean reverse = false;
if (pars.order == Order.last) reverse = true;

FormEnum forms = fstats.iterator(pars.limit, filter, pars.ranking.specif(), pars.cat.tags(), reverse);

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
if (pars.q == null) {
  // out.println(max+" termes");
}
else {
  out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\""+pars.left+"\"/>");
  out.print(pars.q);
  out.println("<input style=\"width: 2em;\" name=\"right\" value=\""+pars.right+"\"/>&gt;");
  out.println("<input type=\"hidden\" name=\"q\" value=\""+JspTools.escape(pars.q)+"\"/>");
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
             
             <br/><label>Filtrer par catégorie grammaticale
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
             <br/><label>Direction
             <br/><select name="order" onchange="this.form.submit()">
                 <option/>
                 <%= pars.order.options() %>
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
          // todo, book selector
          String href = "kwic.jsp?" + ((pars.book != null)?"book="+pars.book+"&amp;":"") + "q=";
          out.println(lines(forms, pars.mime, href));
          
          %>
        </tbody>
      </table>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
