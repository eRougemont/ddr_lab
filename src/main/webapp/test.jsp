<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%
// get default parameters from request
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Dev, tests</title>
  </head>
  <body>
    <form class="base">Corpus
      <select  name="base" oninput="this.form.submit();">
      <%
      JspTools retools = new JspTools(pageContext);
      String base = retools.getString("base", "rougemont", "alixBase");
      for (Map.Entry<String, Alix> entry : Alix.pool.entrySet()) {
        String value = entry.getKey();
        out.print("<option value=\"" + value + "\"");
        if (value.equals(base)) out.print(" selected=\"selected\"");
        out.println(">" + entry.getValue().props.get("label") + "</option>");
      }
      %>
      </select>
    </form>
    <%
    FieldText ftext = alix.fieldText("text_orth");
    %>
    <%= FrDics.isStop(",") %>
    <%= ftext.isStop(ftext.formId(",")) %>
  </body>
</html>
