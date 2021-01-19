<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/freqs.jsp" %>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");


long time = System.nanoTime();
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
    <jsp:include page="ddr_head.jsp" flush="true"/>
   <title><%= alix.props.get("label")%> [Alix]</title>
  </head>
  <body>
    <header>
      <% long time2 = System.nanoTime(); %>
       <jsp:include page="tabs.jsp"/>
         <!-- <%= ((System.nanoTime() - time2) / 1000000.0) %> ms  -->
       
    </header>
    <main>
      <table class="sortable" width="100%">
        <caption>
          <form  class="search">
             <label>Sélectionner un livre
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
  String year = doc.get("year");
  if (year != null) out.print(year + ", ");
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
                 <% 
                 if (pars.book == null) out.println (pars.ranking.options("occs bm25 tfidf"));
                 // else out.println (pars.ranking.options("occs bm25 tfidf g chi2"));
                 else out.println (pars.ranking.options()); 
                 %>
              </select>
             </label>
             <br/><label>Direction
             <br/><select name="order" onchange="this.form.submit()">
                 <option/>
                 <%= pars.order.options()  %>
              </select>
             </label>
             <button type="submit">▶</button>
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
          String urlForm = "kwic.jsp?" + tools.url(new String[]{"ranking", "book"}) + "&amp;q=";
          // String urlOccs = "kwic.jsp?" + tools.url(new String[]{"left", "right", "ranking"}) + "&amp;q=";
          int no = 0;
          while (dic.hasNext()) {
            dic.next();
            no++;
            String term = dic.label();
            // .replace('_', ' ') ?
            out.println("  <tr>");
            out.println("    <td class=\"no left\">"  + no + "</td>");
            out.println("    <td class=\"form\">");
            out.print("      <a");
            out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
            out.print(">");
            out.print(term);
            out.print("</a>");
            out.println("</td>");
            
            out.print("    <td>");
            out.print(Tag.label(dic.tag()));
            out.println("</td>");
            
            out.println("    <td class=\"num\">");
            // out.print("      <a href=\"" + urlOccs + JspTools.escUrl(term) + "\">");
            out.print(dic.freq()) ;
            // out.println("</a>");
            out.println("    </td>");
            out.print("    <td class=\"num\">");
            out.print(dic.hits()) ;
            out.println("</td>");
            // fréquence
            // out.println(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
            out.print("    <td class=\"num\">");
            out.print(formatScore.format(dic.score()));
            out.println("</td>");
            out.println("    <td></td>");
            out.println("    <td class=\"no right\">" + no + "</td>");
            out.println("  </tr>");
          }
          %>
        </tbody>
      </table>
      <p> </p>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
  <!-- <%= ((System.nanoTime() - time) / 1000000.0) %> ms  -->
</html>
