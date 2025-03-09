<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File"%>
<%@ page import="org.deeplearning4j.models.embeddings.loader.WordVectorSerializer"%>
<%@ page import="org.deeplearning4j.models.word2vec.Word2Vec"%>
<%!
File vexFile = new File("C:/code/word2vec/rougemont.bin");
Word2Vec vex = WordVectorSerializer.readWord2VecModel(vexFile);


%>
<%
String q = tools.getString("q", "personne");
String[] words = alix.tokenize(q, TEXT_CLOUD);
%>
<!DOCTYPE html>
<html>
    <head>
        <%@ include file="local/head.jsp" %>
        <title>Chronologies</title>
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
                    <input name="q" type="text" value="<%=q%>" style="width: 100%; "/>
                </form>
                <p>Mots similaires à : <%=q%><p>
<%
Collection<String> lines = vex.wordsNearest(Arrays.asList(words), Arrays.asList(), 20);
for (String word: lines) {
    out.println("<li>" + word + "</li>");
}
%>
                </p>
                <p>
                <%= ((System.nanoTime() - timeStart) / 1000000) + "ms" %>
                </p>
            </main>
        </div>
        <%@include file="local/footer.jsp" %>
    </body>
</html>
