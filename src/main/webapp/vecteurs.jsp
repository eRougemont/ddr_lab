<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="com.github.oeuvres.jword2vec.util.Edge"%>
<%@ page import="com.github.oeuvres.jword2vec.VecSearch"%>
<%@ page import="com.github.oeuvres.jword2vec.VecModel"%>
<%!
VecSearch vecSearch =  null;


%>
<%
if (vecSearch == null) {
    String fileName = getServletContext().getRealPath("/rougemont.bin");
    File modelFile = new File(fileName);
    VecModel model = VecModel.fromBinFile(modelFile);
    vecSearch =  model.forSearch();   
}
String q = tools.getString("q", "personne");
FieldText ftext = alix.fieldText(TEXT_CLOUD);
final DecimalFormat frdec = new DecimalFormat("###,###,###,##0.00000", frsyms);
%>
<!DOCTYPE html>
<html>
    <head>
        <%@ include file="local/head.jsp" %>
        <title>Vecteurs de mots</title>
    </head>
    <body class="chrono">
        <header id="header">
            <%@ include file="local/tabs.jsp" %>
        </header>
        <div class="row">
            <aside id="aside" class="form">
            </aside>
            <main>
                <form action="" style="padding: 5px 1rem; background-color: #ccc;">
                    <label>Chercher des mots similaires à un ou plusieurs mots</label>
                    <br/>
                    <input name="q" type="text" value="<%=q.replace('_', ' ')%>" style="width: 100%; "/>
                </form>
<%
boolean ok = false;
String[] tokens = alix.tokenize(q, TEXT_CLOUD);
List<String> wordList = new ArrayList<String>();
for (int i = 0; i < tokens.length; i++) {
    String word = tokens[i].replace(' ', '_');
    if (!vecSearch.contains(word)) {
        out.println(String.format("<li>“%s”, mot absent</li>", tokens[i]));
        continue;
    }
    wordList.add(word);
    ok = true;
}
String[] words = wordList.toArray(new String[wordList.size()]);
if (ok) {
    Edge[] edges = vecSearch.sims(words, 20);
    out.println(((System.nanoTime() - timeStart) / 1000000) + "ms");
    out.println("<table>");
    out.println("<tr>");
    out.println("<th>Mot</th>");
    out.println("<th>Fréquence</th>");
    out.println("<th>Distance</th>");
    out.println("</tr>");
    for (final Edge edge: edges) {
        out.println("<tr>");
        String w = JspTools.escUrl(edge.targetLabel());
        String form = w.replace('_', ' ');
        out.println(String.format("<td><a href=\"?q=%s\">%s</a></td>", w, form));
        out.println("<td>" + ftext.occs(form) + "</td>");
        out.println("<td>" + frdec.format(edge.score()) + "</td>");
        out.println("</tr>");
    }
    out.println("</table>");
}

%>
                <p>
                </p>
            </main>
        </div>
        <%@include file="local/footer.jsp" %>
    </body>
</html>
