<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.uhighlight.UnifiedHighlighter" %>
<%@ page import="org.apache.lucene.search.uhighlight.DefaultPassageFormatter" %>
<%@ page import="alix.lucene.search.FieldText.DocStats" %>
<%@include file="jsp/prelude.jsp"%>
<%!

%>
<%
long time = System.nanoTime(); 
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
IndexReader reader = alix.reader();
// Params for the page
Pars pars = pars(pageContext);
FieldText fstats = alix.fieldText(pars.fieldName);


%>
<!DOCTYPE html>
<html>
  <head>
    <title><%= alix.props.get("label") %>, Chapitres</title>
    <jsp:include page="ddr_head.jsp" flush="true" />
    <script src="vendor/dygraph.min.js">//</script>
    <script src="vendor/dyxtras.js">//</script>
  </head>
  <body class="chapters">
    <header>
       <jsp:include page="tabs.jsp" flush="true" />
    </header>
    <form id="qform"  class="search">
      <label>Rechercher <input id="q" name="q" value="<%=JspTools.escape(pars.q)%>" width="100" autocomplete="off"/>
      </label>
      <label>Ordonner
         <select name="sort" onchange="this.form.submit()">
          <option/>
  <%= pars.sort.options("score year year_inv") %>
          </select>
      </label>
      <button type="submit">▶</button>
    </form>
  
    <main>
      <div id="chartframe">
        <div id="chart" class="dygraph"></div>
      </div>
      
      <script>
const xClick = function(event, x, points) {
  var el = document.getElementById(x);
  el.scrollIntoView();
  window.scrollBy(0, -100);
  el.classList.add("target");
  el.addEventListener('click', event => {
	  el.classList.remove("target");
	});
}
var json = <jsp:include page="jsp/chronojson.jsp" flush="true" />;
var barCount = json.labels.length - 2;
var attrs = {
  title : "Occurrences par années",
  labels: json.labels,
  legend: "always",
  labelsSeparateLines: true,
  ylabel: "occurrences",
  y2label: "Taille des textes",
  // logscale: true,
  // xlabel: "Répartition des années en nombre de mots",
  clickCallback: xClick,
  logscale: true,
  plotter: Dygraph.plotHoles,
  strokeWidth: 0.5,
  drawPoints: true,
  pointSize: 8,
  yRangePad : 8,
  xRangePad : 16,
  series: {
    "Taille des textes": {
       axis: (json.labels.length > 2)?'y2':null,
       plotter: Dygraph.plotBar,
       /*
       drawPoints: false,
       strokeWidth: 3,
       fillGraph: true,
       */
    },
  },
  
  colors:['rgba(255, 255, 255, 0.8)', 'rgba(255, 26, 26, 0.7)', 'rgba(26, 26, 192, 0.7)', 'rgba(26, 128, 26, 0.7)', 'rgba(0, 128, 192, 0.7)', 'rgba(146,137,127, 0.7)', 'rgba(192, 128, 0, 0.7)'],

  // logscale: true,
  axes : {
    x: {
      drawGrid: true,
      gridLineColor: "rgba(160, 160, 160, 0.2)",
      gridLineWidth: 3,
    },
    y:{
      drawGrid: true,
      gridLineColor: "rgba(192, 192, 192, 0.7)",
      gridLineWidth: 1,
    },
    y2:{
      independentTicks: true,
      drawGrid: false,
      labelsKMB: true,
        // gridLineColor: "rgba( 128, 128, 128, 0.1)",
        // gridLineWidth: 1,
    },
  },
};
var div = document.getElementById("chart");
g = new Dygraph(div, json.data, attrs);

      </script>
      
      <div>
        <table class="sortable" width="100%">
          <thead>
            <tr>
              <td/>
              <th>Score</th>
              <th>Année</th>
              <th style="width: 15ex;">Livre</th>
              <th class="q"><% if (pars.q != null) out.print("requête : <i>" + pars.q + "</i>"); %></th>
              <th>page</th>
              <th/>
              <th/>
             </tr>
           </thead>
           <tbody>
        
    
<%

final int len = 2000;
Query query = alix.query(pars.fieldName, pars.q);
if (query == null) {
  query = QUERY_CHAPTER;
}
IndexSearcher searcher = alix.searcher();
// searcher.setSimilarity(sim.similarity()); // test has been done, BM25 is the best
TopDocs topDocs;
if (pars.sort != null && pars.sort.sort() != null) topDocs = searcher.search(query, len, pars.sort.sort());
else topDocs = searcher.search(query, len);
ScoreDoc[] hits = topDocs.scoreDocs;

// get stats by doc
DocStats docStats = null;
double scoreMax = 1;
double scoreMin = 0;
if (pars.q != null) {
  String[] forms = alix.forms(pars.q);
  docStats = fstats.docStats(forms, null, null);
  if (docStats != null) {
    scoreMax = docStats.scoreMax();
    scoreMin = docStats.scoreMin();
  }
}

final String href = "doc.jsp?q=" + pars.q + "&amp;id="; // href link
boolean zero = false;
int no = 1;
int lastYear = Integer.MIN_VALUE;
for (ScoreDoc hit: hits) {
  final int docId = hit.doc;
  Document doc = reader.document(docId, CHAPTER_FIELDS);
  out.println("<tr class=\"snip\">");
  // hits[i].doc
  out.println("<td class=\"no left\">" + no + "</td>");
  if (docStats != null) {
    out.println("<td class=\"stats\">");
    out.println("<span class=\"bar\" style=\"width:" + dfdec1.format(100 * (docStats.score(docId) - scoreMin) / (scoreMax - scoreMin)) + "%\"> </span>");
    out.println(docStats.occs(docId));
    // out.println(" (" + docStats.score(docId) + ")");
    
    out.println("</td>");
  }
  else {
    out.println("<td/>");
  }
  
  String year = doc.get("year");
  if (year != null) {
    out.print("<td class=\"num\"");
    int i=Integer.parseInt(year);
    if (i != lastYear) {
      lastYear = i;
      out.print(" id=\"" + i + "\"");
    }
    out.print(">");
    out.print(year);
    out.println("</td>");
  }
  else {
    out.println("<td/>");
  }
  out.print("<td class=\"title\" title=\"" + doc.get("title") + "\">");
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
  String pages = doc.get("pages");
  if (pages != null) out.print(pages);
  out.println("</td>");
  out.println("<td/>");
  out.println("<td/>\n<td class=\"no right\">" + no + "</td>");
  out.println("</tr>");
  no++;
}
%>
          </tbody>
        </table>
        <p> </p>
        <p> </p>
      </div>
    </main>
    <script src="<%= hrefHome %>vendor/sortable.js">//</script>
    <% out.println("<!-- duration\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\" -->"); %>
  </body>
</html>
