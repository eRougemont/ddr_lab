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

final String fieldName = TEXT; // the field to process

FieldText fieldText = alix.fieldText(fieldName);

boolean reverse = false;
if (pars.order == Order.last) reverse = true;

FormEnum dic = null;
if (pars.q != null) {
  FieldRail rail = alix.fieldRail(fieldName); // get the tool for cooccurrences
  // parameters and population of dic.freqs and dic.hits with the rail co-occurrents
  dic = new FormEnum(fieldText); // build a wrapper to have results
  dic.search = alix.forms(pars.q); // parse query as terms
  dic.left = pars.left; // left context
  dic.right = pars.right; // right context
  dic.filter = filter; // limit to some documents
  dic.tags = pars.cat.tags(); // limit word list by tags
  long found = rail.coocs(dic);
  if (found > 0) { // nothing found, what should I do here ?
    // parameters for sorting
    dic.limit = pars.limit;
    dic.specif = pars.ranking.specif();
    dic.reverse = reverse;
    rail.score(dic);
  }
}
else {
  // final int limit, Specif specif, final BitSet filter, final TagFilter tags, final boolean reverse
  dic = fieldText.iterator(pars.limit, pars.ranking.specif(), filter, pars.cat.tags(), reverse);
}
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
            <br/><label>Cooccurrents fréquents autour d’un ou plusieurs mots
            <br/><input name="q" value="<%= JspTools.escape(pars.q) %>"/>
            </label>
            <label><input name="left" value="<%= pars.left %>" size="1" class="num3"/> mots à gauche</label>
            <label><input name="right" value="<%= pars.right %>" size="1" class="num3"/> mots à droite</label>
            
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
          out.println(lines(dic, pars.mime, href));
          
          %>
        </tbody>
      </table>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
