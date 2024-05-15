<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="alix.lucene.search.Doc" %>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="alix.util.Top" %>
<%@include file="jsp/prelude.jsp" %>
<%
String id = tools.getString("id", "");
int docId = alix.getDocId(id);
%>
<!DOCTYPE html>
<html class="document">
  <head>
    <link href="<%= hrefHome %>vendor/teinte.css" rel="stylesheet"/>
    <%@ include file="local/head.jsp" %>
    <title>Livres</title>
    <style type="text/css">
body {
    padding: 0.5rem;
    line-height: 100%;
}
    </style>
  </head>
  <body class="document">
    <main>
      <div>
    <%
if (docId >= 0) {
    Document doc = reader.document(docId);
    out.println("<div class=\"heading\">");
    out.println(doc.get("bibl"));
    out.println("</div>");
    out.println(doc.get("text"));
}
    %>
        
      </div>
    </main>
  </body>
</html>
