<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.io.File" %>
<%@ page import="java.util.List" %>
<%@ page import="java.nio.file.Path" %>
<%@ page import="java.util.Map" %>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.Alix.FSDirectoryType" %>
<%@ page import="alix.lucene.analysis.FrAnalyzer" %>
<%@ page import="alix.util.Dir" %>
<%@ page import="alix.web.Webinf" %>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">
  <head>
    <meta charset="UTF-8"/>
    <link href="../static/obvie.css" rel="stylesheet"/>
    <title>Status, Ddrlab</title>
  </head>
  <body class="document">
    <article class="chapter">
      <h1>Dddrlab, status</h1>
      <%
final String baseDir = getServletContext().getRealPath("WEB-INF") + "/";
      %>
      <ul>
          <li>path=<%=request.getAttribute("path")%></li>
          <li>RequestUri=<%=request.getRequestURI()%></li>
          <li>ContexPath=<%=request.getContextPath()%></li>
          <li>baseDir=<%=baseDir%></li>
        <% 
for (String s: new String[] {
  AsyncContext.ASYNC_CONTEXT_PATH, AsyncContext.ASYNC_PATH_INFO, AsyncContext.ASYNC_REQUEST_URI, AsyncContext.ASYNC_SERVLET_PATH,
  RequestDispatcher.FORWARD_CONTEXT_PATH, RequestDispatcher.FORWARD_PATH_INFO, RequestDispatcher.FORWARD_QUERY_STRING, RequestDispatcher.FORWARD_REQUEST_URI, RequestDispatcher.FORWARD_SERVLET_PATH
}) {
  out.println("<li>"+s+"="+request.getAttribute(s)+"</li>");
}
        out.println("</ul>");
        out.println("<p>Webinf.bases =" + Webinf.bases + "</p>");
        Webinf.bases();
        out.println("<pre>" + Alix.pool + "</pre>");
        out.println("<dl>");
        List<File> ls = Dir.ls(baseDir+"*.xml");
        for (File file : ls) {
          String name = file.getName();
          if (name.equals("web.xml")) continue;
          String base = name.replaceFirst("[.][^.]+$", "");
          out.println("<dt>"+base+"</dt>");
          out.println("<dd><pre>");
          try {
            Alix alix = Alix.instance(base);
            out.println(alix);
          } catch (Exception e) {
            out.println(e);
          }
          out.println("</pre></dd>");
        }
        out.println("</dl>");
        %>
      <h5>Paramètres</h5>
      <dl>
      <%
      Map<String, String[]> parameters = request.getParameterMap();
      for(String key : parameters.keySet()) {
        out.println("<dt>"+key+"</dt>");
        String[] values = parameters.get(key);
        if (values == null);
        else if (values.length < 1);
        else {
          out.println("<dd>");
          boolean first = true;
          for(String v: values) {
            if (first) first = false;
            else out.print("<br/>");
            out.println(v);
          }
          out.println("</dd>");
        }
      }
      %>
      
    </article>
  </body>
</html>

