<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@include file="jsp/prelude.jsp"%>

<%
long time = System.nanoTime();
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
Pars pars = pars(pageContext);

IndexReader reader = alix.reader();

%>
<!DOCTYPE html>
<html>
  <head>
   <jsp:include page="ddr_head.jsp" flush="true" />
    <title>Livres</title>
  </head>
  <body>
    <header>
       <jsp:include page="tabs.jsp" flush="true" />
    </header>
    <form  class="search">
      <input type="hidden" name="f" value="<%=JspTools.escape(pars.fieldName)%>"/>
     <label for="q" title="Classer les livres selon un ou plusieurs mots">Chercher</label>
      <input name="q" onclick="this.select()" type="text" value="<%=tools.escape(pars.q)%>" size="40" />
      
      <label for="distrib" title="Algorithme d’ordre">Score</label>
      <select name="distrib" onchange="this.form.submit()">
        <option/>
        <%= pars.distrib.options() %>
      </select>
      
      <button type="submit">▶</button>
    </form>
    <main>
      <table class="sortable" width="100%">
        <caption>Lecture : <a href="?q=aimer">chercher le verbe aimer</a>.
<br/>— Dans <i>Comme toi-même</i>, 198 occurrences trouvées (/ ~70 000 mots), dans 14 chapitres (/ 20).
<br/>— Le score de pertinence est calculé relativement à la taille du livre, et à la présence du mot ailleurs dans le corpus</caption>
        <thead>
          <tr>
            <td/>
            <th>Livre</th>
            <th title="Nombre d’occurrences trouvées" class="num"> Occurrences</th>
            <td title="Taille du livre-compilation en mots" class="all">/mots</td>
            <th title="Nombre de chapitres-articles contenant les mots cherchés" class="num"> Résultats</th>
            <td title="Taille du livre-compilation en chapitres-articles" class="all">/chapitres</th>
            <th title="Score selon l’algorithme" class="num"> Score</th>
            <th width="100%"/>
            <td/>
          <tr>
        </thead>
        <tbody>
        
    
<%
          //global variables
          FieldFacet facet = alix.fieldFacet(Alix.BOOKID, TEXT);
            String[] search = alix.forms(pars.q);
            FormEnum dic = facet.iterator(search, null, pars.distrib.scorer(), -1);
            // if no word searched, sort by date, not well optimized here
            if (search == null || search.length < 1) {
              // get docIds of books sorted by a query
              int[] books = alix.books(sortYear);
              // take a facteId for these books to set a sorter
              for (int i = 0, length = books.length; i < length; i++) books[i] = facet.facetId(books[i]);
              dic.sorter(books);
            }
            /* 
            // Hack to use facet as a navigator in results, cache results in the facet order
            TopDocs topDocs = getTopDocs(pageContext, alix, corpus, q, DocSort.author);
            int[] nos = facet.nos(topDocs);
            dic.setNos(nos);
            */
            // build a resizable href link
            final String href = "conc.jsp?q=" + JspTools.escape(pars.q)+ "&amp;book=";
            // resend a query somewhere ?
            boolean zero = false;
            int no = 1;
            while (dic.hasNext()) {
              dic.next();
              // n = dic.n();
              //in alpha order, do something if no match ?
              if (dic.hits() < 1) {
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
              String id = dic.form();
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
              if (dic.freq() > 0) {
                out.print(dic.freq());
              }
              out.println("</td>");

              out.print("    <td class=\"all\">");
              out.print("/ "+frdec.format(dic.occs()));
              out.println("</td>");

              out.print("    <td class=\"num\">");
              if (dic.hits() > 0) out.print(dic.hits());
              out.println("</td>");
              
              out.print("    <td class=\"all\">");
              out.print("/ "+dic.docs());
              out.println("</td>");

              // fréquence
              // sb.append(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
              out.print("    <td class=\"num\">");
              if (dic.score() != 0) out.print(formatScore(dic.score()));
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
