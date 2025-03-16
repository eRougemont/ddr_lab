<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!



%>
<%
FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();
final int rolling = tools.getInt("rolling", new int[]{0, 10}, 3, "rolling");


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
        <main>
            <label>
                Moyenne glissante
                <input title="Moyenne glissante" form="formchrono" name="rolling" id="rolling" value="<%=rolling%>" type="number" min="0" max="10" step="1"/>
            </label>
            <label class="toggle">
                <span class="toggleslide"></span>Fréquence relative
                <input id="freqrel" form="formchrono" type="checkbox"/>
            </label>

            <div id="tempolex"></div>
            <form class="search" name="chrono" id="formchrono">
                <ul id="lines" class="lines">
                </ul>
            </form>
        </main>
        <div id="kwic" class="kwic_results"> </div>
        <%@include file="local/footer.jsp" %>
        <script type="module" src="<%=hrefHome%>lib/chrono.js">//</script>
    </body>
</html>
