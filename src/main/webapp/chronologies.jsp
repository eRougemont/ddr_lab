<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!



%>
<%
FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();



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
                <form name="search">
                    <ul id="lines" class="lines">
                    </ul>
                </form>
            </aside>
            <main>
                <div id="tempolex"></div>
            </main>
        </div>
        
        <%@include file="local/footer.jsp" %>
        <script type="module" src="<%=hrefHome%>local/chrono.js">//</script>
    </body>
</html>
