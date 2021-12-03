<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="jsp/prelude.jsp"%>
<%
//global variables
FieldFacet facet = alix.fieldFacet(Alix.BOOKID, pars.field.name());
String[] search = alix.forms(pars.q, pars.field.name());
FormEnum results = facet.results(search, null, pars.distrib.scorer());
results.sort(FormEnum.Sorter.score, -1, false);

%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="local/head.jsp" flush="true"/>
    <title>Livres <%= alix.props.get("label") %> [Alix]</title>
  </head>
  <body>
    <header>
      <jsp:include page="local/tabs.jsp" flush="true" />
      <form  class="search">
        <%= selectCorpus(alix.name) %>,
        <label for="q" title="Classer les livres selon un ou plusieurs mots">Chercher</label>
        <input name="q" class="q" onclick="this.select()" type="text" value="<%=tools.escape(pars.q)%>" size="40" />
        <select name="f" onchange="this.form.submit()">
          <option/>
          <%=pars.field.options()%>
        </select>
        <label for="distrib" title="Algorithme d’ordre">Score</label>
        <select name="distrib" onchange="this.form.submit()">
          <option/>
          <%= pars.distrib.options() %>
        </select>
        
        <button type="submit">▶</button>
      </form>
    </header>
    <main>
      <table class="sortable" width="100%">
        <caption><%
        if (pars.q == null) {
          out.print("Livres du corpus, cherchez un ou plusieurs mots, les titres seront ordonnée selon leur «pertinence» pour la recherche.");
        }
        else {
          int rank = 1;
          out.print("Lecture :");
          out.println(" pour la recherche <strong>"+pars.q+"</strong>");
          out.println("<br/>— au rang "+(rank + 1)+" dans <em>"+results.formByRank(rank)+"</em> ");
          out.println("<br/>— " + frdec.format(results.freqByRank(rank)) + " occurrences (sur les " + frdec.format(results.occsByRank(rank)) + " du livre)");
          out.println("<br/>— " + frdec.format(results.hitsByRank(rank)) +" textes trouvés (sur les " + frdec.format(results.docsByRank(rank)) +" du livre)");
          out.println("<br/>— Le score de pertinence est calculé relativement à la taille du livre, et à la présence du mot ailleurs dans le corpus");
        }
        // : <a href="?q=aimer">chercher le verbe aimer</a>.
        // <br/>— Dans <i>Comme toi-même</i>, 198 occurrences trouvées (/ ~70 000 mots), dans 14 chapitres (/ 20).
        // <br/>— Le score de pertinence est calculé relativement à la taille du livre, et à la présence du mot ailleurs dans le corpus
        %> 
        </caption>
        <thead>
          <tr>
            <td/>
            <th>Livre</th>
            <th title="Nombre d’occurrences trouvées" class="num"> occurrences</th>
            <th title="Taille du livre en mots" class="all">/mots</td>
            <th title="Nombre de chapitres-articles contenant les mots cherchés" class="num"> résultats</th>
            <th title="Taille du livre-compilation en chapitres-articles" class="all">/textes</th>
            <th title="Score selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <td/>
          <tr>
        </thead>
        <tbody>
        
    
<%
            // if no word searched, sort by date, not well optimized here
            if (search == null || search.length < 1) {
              // get docIds of books sorted by a query
              int[] books = alix.books(sortYear);
              // take a facteId for these books to set a sorter
              for (int i = 0, length = books.length; i < length; i++) books[i] = facet.facetId(books[i]);
              results.sorter(books);
            }
            /* 
            // Hack to use facet as a navigator in results, cache results in the facet order
            TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, DocSort.author);
            int[] nos = facet.nos(topDocs);
            results.setNos(nos);
            */
            // build a resizable href link
            final String href = "conc.jsp?q=" + JspTools.escape(pars.q)+ "&amp;book=";
            // resend a query somewhere ?
            boolean zero = false;
            int no = 1;
            while (results.hasNext()) {
              results.next();
              // n = results.n();
              //in alpha order, do something if no match ?
              if (results.hits() < 1) {
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
              if (!zero && results.score() <= 0) {
                out.println("<hr/>");
                zero = true;
              }
              */
              String id = results.form();
              out.println("  <tr>");
              out.println("    <td class=\"no left\">" + no + "</td>");
              out.print("    <td class=\"form\">");
              out.print("<a href=\""+href+id+"\">");
              // out.print(results.label());
              int docId = alix.getDocId(id);
              Document doc = reader.document(docId, BOOK_FIELDS);
              out.print(doc.get("year"));
              out.print(", ");
              out.print(doc.get("title"));
              out.print("</a>");
              out.println("</td>");
              
              out.print("    <td class=\"num\">");
              if (results.freq() > 0) {
                out.print(results.freq());
              }
              out.println("</td>");

              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(results.occs()));
              out.println("</td>");

              out.print("    <td class=\"num\">");
              if (results.hits() > 0) out.print(results.hits());
              out.println("</td>");
              
              out.print("    <td class=\"all\">");
              out.print("/ "+results.docs());
              out.println("</td>");

              // fréquence
              // sb.append(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
              out.print("    <td class=\"num\">");
              if (results.score() != 0) out.print(formatScore(results.score()));
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
      <p> </p>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
    <% out.println("<!-- time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
  </body>
</html>
