<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="prelude.jsp" %>
<%!
private String options(int[] values, int value) {
  StringBuilder sb = new StringBuilder();
  for (int i = 0, lim = values.length; i < lim; i++) {
    sb.append("<option");
    if (value == values[i]) sb.append(" selected=\"selected\"");
    sb.append(">");
    sb.append(values[i]);
    sb.append("</option>\n");
  }
  return sb.toString();
}

%>
<%
final String q = tools.getString("q", null);
WordClass cat = (WordClass)tools.getEnum("cat", WordClass.NOSTOP);
final int count = tools.getInt("count", 500);
int left = tools.getInt("left", 5);
if (left < 0) left = 0;
else if (left > 10) left = 10;
int right = tools.getInt("right", 5);
if (right < 0) right = 0;
else if (right > 10) right = 10;

%>
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Nuage de mots</title>
    <link rel="stylesheet" type="text/css" href="static/ddrlab.css"/>
    <script src="static/js/common.js">//</script>
    <script>var count = <%= count %>;</script>
  </head>
  <body class="cloud">
    <form id="filter">
      <%

      if (q == null) {
        // out.println(max+" termes");
      }
      else {
        out.println("&lt;<input style=\"width: 2em;\" name=\"left\" value=\""+left+"\" title=\"Nombre de mots à gauche du pivot repris dans la liste de fréquence\"/>");
        out.print(q);
        out.println("<input style=\"width: 2em;\" name=\"right\" value=\""+right+"\" title=\"Nombre de mots à droite du pivot repris dans la liste de fréquence\"/>&gt;");
      }
      %>
       
       <select name="count" onchange="this.form.submit()">
        <option/>
        <%= options(new int[]{30, 50, 100, 200, 500, 1000}, count) %>
       </select>

       <select name="cat" onchange="this.form.submit()">
          <option/>
          <%= options(cat) %>
       </select>
       
       <input type="hidden" name="q" value="<%=Jsp.escUrl(q)%>"/>
       <button type="submit">▼</button>
    </form>
    <div id="wordcloud2"></div>
    <script src="vendor/wordcloud2.js">//</script>
    <script src="static/cloud.js">//</script>
</body>
</html>
