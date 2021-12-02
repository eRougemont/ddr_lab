<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");

long time = System.nanoTime();
IndexReader reader = alix.reader();

// get default parameters from request
Pars pars = pars(pageContext);
/*
Corpus corpus = null;
BitSet filter = null; // if a corpus is selected, filter results with a bitset
if (pars.book != null) filter = Corpus.bits(alix, Alix.BOOKID, new String[]{pars.book});
*/

FieldText ftext = alix.fieldText(pars.fieldName);
FieldMatrix fmat = new FieldMatrix(alix, pars.fieldName);
FormEnum results = new FormEnum(ftext);
boolean first;
Distrib distrib = (Distrib)tools.getEnum("distrib", Distrib.occs); // 
final int formMax = ftext.formMax;
TagFilter tags = pars.cat.tags();
boolean noStop = (tags != null && tags.noStop());
boolean hasTags = (tags != null);
double[] scores = fmat.test(distrib.scorer(), null);
for (int formId = 0; formId < formMax; formId++) {
  if (noStop && ftext.isStop(formId)) scores[formId] = 0;
  else if (hasTags && !tags.accept(ftext.formTag[formId])) scores[formId] = 0;
}
final boolean reverse = pars.order.equals(Order.last);
results.scores(scores, pars.limit, reverse);
%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="ddr_head.jsp" flush="true"/>
    <title><%=alix.props.get("label")%> [Alix]</title>
  </head>
  <body>
    <header>
      <jsp:include page="tabs.jsp"/>
    </header>
    <form  class="search">
      <input type="hidden" name="f" value="<%=JspTools.escape(pars.fieldName)%>"/>
      <input type="hidden" name="order" value="<%=pars.order%>"/>
      <label for="limit" title="Nombre de mots à l’écran">Mots</label>
      <input name="limit" type="text" value="<%= pars.limit %>" class="num3" size="2"/>
      <label title="Filtrer les mots par catégories grammaticales" for="cat">Catégories</label>
      <select name="cat" onchange="this.form.submit()">
        <option/>
        <%=pars.cat.options()%>
      </select>
      <label for="distrib" title="Algorithme d’ordre des mots sélectionné">Score</label>
      <select name="distrib" onchange="this.form.submit()">
           <option/>
           <%= distrib.options() %>
      </select>
       <button type="submit">▶</button>
    </form>
    <main>
      <script src="vendor/d3.layout.cloud.js">//</script>
      <script src="vendor/d3-dispatch.min.js">//</script>
      <script src="vendor/d3.layout.cloud.js">//</script>
      <script src="vendor/d3-dispatch.min.js">//</script>
      
      <div style="text-align: center;">
        <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="700" class="d3cloud" id="svgcloud">
        </svg>
      </div>
      <script>
var j3words = [
<%
// {text: "salut", size: 15, test: "haha"}
first = true;
results.first();
double scoreMax = Math.sqrt(results.score());
results.last();
double scoreMin = Math.sqrt(results.score());
double fontMin = 14;
double factor = 90d / (scoreMax - scoreMin) ;


results.reset();
while (results.hasNext()) {
  results.next();
  if (first) first = false;
  else out.print(",\n");
  double score = Math.sqrt(results.score());
  // if (distrib.equals(Distrib.g) || distrib.equals(Distrib.tfidf)) score = Math.sqrt(score);
  // else if (distrib.equals(Distrib.tfidf)) score = Math.sqrt(score) ;
  // else if (distrib.equals(Distrib.bm25)) score = score;
  out.print("  {text: '" + results.form().replace("'", "\\'") + "', size: " + dfdec1.format(fontMin + factor * (score - scoreMin)) + ", tag: '" + Tag.label(Tag.group(results.tag())) +"'}");
}
%>
];
      </script>
          <script>
const width = 1200;
const height = 700;
var cloud = d3.layout.cloud()
  .size([width, height])
  .words(j3words)
  .padding(1)
  .rotate(function() { return ~~(Math.random() * 6) * (120/5) - 60; })
  .font("sans-serif")
  .fontWeight(400)
  .spiral("rectangular")
  .fontSize(function(d) { return d.size; })
  .on("end", draw)
;

function draw(words) {
  var svgns = "http://www.w3.org/2000/svg";  
  var svg = document.getElementById("svgcloud");
  for (var i = 0, len = words.length; i < len; i++) {
    var w = words[i];
    var el = document.createElementNS(svgns, "text");
    el.append(words[i].text);
    // el.setAttribute("text-anchor", "middle");
    el.setAttribute("font-size", w.size + "px");
    el.setAttribute("class", w.tag);
    el.setAttribute("transform", "translate(" + [w.x + width/2, w.y + height/2] + ") rotate(" + w.rotate + ")");
    svg.append(el);
  }
  // console.log(words);
}
window.addEventListener("load", function(event) {
  cloud.start();
}); 
     </script>
      <table class="sortable" width="100%">
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
                                  results.reset();
                                  while (results.hasNext()) {
                                    results.next();
                                    no++;
                                    String term = results.form();
                                    // .replace('_', ' ') ?
                                    out.println("  <tr>");
                                    out.println("    <td class=\"no left\">"  + no + "</td>");
                                    out.println("    <td class=\"form\">");
                                    out.print("      <a");
                                    out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
                                    out.print(">");
                                    out.print(term);
                                    out.print("</a>");
                                    out.println("    </td>");
                                    
                                    out.print("    <td>");
                                    out.print(Tag.label(results.tag()));
                                    out.println("</td>");
                                    
                                    out.print("    <td class=\"num\">");
                                    // out.print("      <a href=\"" + urlOccs + JspTools.escUrl(term) + "\">");
                                    out.print(results.occs()) ;
                                    // out.println("</a>");
                                    out.println("    </td>");
                                    out.print("    <td class=\"num\">");
                                    out.print(results.docs()) ;
                                    out.println("</td>");
                                    // fréquence
                                    // out.println(dfdec1.format((double)forms.occsMatching() * 1000000 / forms.occsPart())) ;
                                    out.print("    <td class=\"num\">");
                                    out.print(formatScore(results.score()));
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
