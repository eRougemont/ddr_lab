<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="com.github.oeuvres.jword2vec.Searcher"%>
<%@ page import="com.github.oeuvres.jword2vec.Searcher.Match"%>
<%@ page import="com.github.oeuvres.jword2vec.Word2VecModel"%>
<%!
com.github.oeuvres.jword2vec.Searcher modelSearch =  null;


%>
<%
if (modelSearch == null) {
    String fileName = getServletContext().getRealPath("/rougemont.bin");
    File modelFile = new File(fileName);
    Word2VecModel model = Word2VecModel.fromBinFile(modelFile);
    modelSearch =  model.forSearch();   
}
String q = tools.getString("q", "personne");
FieldText ftext = alix.fieldText(TEXT_CLOUD);
final DecimalFormat frdec = new DecimalFormat("###,###,###,##0.0000", frsyms);
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
    if (!modelSearch.contains(word)) {
        out.println(String.format("<li>“%s”, mot absent</li>", tokens[i]));
        continue;
    }
    wordList.add(word);
    ok = true;
}
String[] words = wordList.toArray(new String[wordList.size()]);
if (ok) {
    List<Match> matches = modelSearch.getMatches(words, 50);
    out.println("<table>");
    out.println("<tr>");
    out.println("<th>Mot</th>");
    out.println("<th>Fréquence</th>");
    out.println("<th>Distance</th>");
    out.println("</tr>");
    for (final Match match: matches) {
        out.println("<tr>");
        String w = JspTools.escUrl(match.match());
        String form = w.replace('_', ' ');
        out.println(String.format("<td><a href=\"?q=%s\">%s</a></td>", w, form));
        out.println("<td>" + ftext.occs(form) + "</td>");
        out.println("<td>" + frdec.format(match.distance()) + "</td>");
        out.println("</tr>");
    }
    out.println("</table>");
}

%>
                <p>
                <%= ((System.nanoTime() - timeStart) / 1000000) + "ms" %>
                </p>
            </main>
        </div>
        <%@include file="local/footer.jsp" %>
    </body>
</html>
