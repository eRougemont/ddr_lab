<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="alix.util.IntPair" %>
<%@ page import="alix.util.Top" %>
<%!


%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="ddr_head.jsp" %>
    <title>Expressions</title>
  </head>
  <body>
     <header>
      <%@ include file="tabs.jsp" %>
    </header>
    <main>
<%
 /** Data structure to record expression by a pair of ints */
/*
  TagFilter tagfilter = new TagFilter()
	.setGroup(Tag.SUB).setGroup(Tag.ADJ)
	.setGroup(Tag.VERB).clear(Tag.VERBaux).clear(Tag.VERBsup)
	.setGroup(Tag.NAME).set(Tag.NULL)
	;
*/
Alix alix = alix(pageContext);
FieldText field = alix.fieldText(TEXT);
FieldRail rail = alix.fieldRail(TEXT);
Top<IntPair> top = rail.expressions(200);

for (Top.Entry<IntPair> entry: top) {
  IntPair pair = entry.value();
  out.print("<li>");
  out.print(field.term(pair.x()));
  out.print(" ");
  out.print(field.term(pair.y()));
  out.print(" (");
  out.print((int)entry.score());
  out.print(")");
  out.println("</li>");
}


%>
      
    </main>
  </body>
</html>
