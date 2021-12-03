<%@ page language="java" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%!

static String format(double real)
{
  if (real == 0) return "0";
  if (real == (int)real) return ""+(int)real;
  int offset = (int)Math.log10(real);
  if (offset < -3) return frdec5.format(real);
  if (offset > 4) return ""+(int)real;
  
  // return String.format("%,." + (digits - offset) + "f", real)+" "+offset;
  return frdec2.format(real);
}


%>
<%
// response.setHeader("Content-Type", "application/vnd.ms-excel");
response.setHeader("Content-type", "application/xls");
response.setHeader("Content-Disposition", "attachment; filename=rougemont_freqs.xls");

boolean first;
FormEnum results = freqList(alix, pars);

/*

*/

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html xmlns:x="urn:schemas-microsoft-com:office:excel">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <meta name="generator" content="LibreOffice 7.1.6.2 (Linux)"/>
    <title>Rougemont 2.0</title>
    <style type="text/css">
<!--table
{mso-displayed-decimal-separator:"\,"; mso-displayed-thousand-separator:" ";}
-->
a {text-decoration: none; font-family:"Arial", sans-serif; font-size:16pt;}
body, div, table, thead, tbody, tfoot, tr, td { font-family:"Arial", sans-serif; font-size:16pt; }
a.comment-indicator:hover + comment { background:#ffd; position:absolute; display:block; border:1px solid black; padding:0.5em;  } 
a.comment-indicator { background:red; display:inline-block; border:1px solid black; width:0.5em; height:0.5em;  } 
comment { display:none;  } 
    </style>
    <!--[if gte mso 9]>
    <xml>
      <x:ExcelWorkbook>
        <x:ExcelWorksheets>
          <x:ExcelWorksheet>
            <x:Name>Rougemont 2.0</x:Name>
            <x:WorksheetOptions>
              <x:DisplayGridlines/>
              <x:Print>
                <x:ValidPrinterInfo/>
              </x:Print>
            </x:WorksheetOptions>
          </x:ExcelWorksheet>
        </x:ExcelWorksheets>
      </x:ExcelWorkbook>
    </xml>
    <![endif]-->
  </head>
  <body>
    <table>
       <tr bgcolor="#EEEEEE">
         <th>Mot</th>
         <th>Catégorie</th>
         <th>Occurrences</th>
         <th>/occurrences</th>
         <th>Textes</th>
         <th>/textes</th>
         <th>Score</th>
       </tr>
       <%
       String urlForm = "https://oeuvres.unige.ch/ddrlab/conc.jsp?" + tools.url(new String[]{"book"}) + "&amp;q=";
       results.reset();
       while (results.hasNext()) {
          results.next();
          String term = results.form();
          // .replace('_', ' ') ?
          out.println("<tr>");
          out.println("<td>");
          out.print("<a class=\"mot\"");
          out.print(" href=\"" + urlForm + JspTools.escUrl(term) + "\"");
          out.print(">");
          out.print(term);
          out.print("</a>");
          out.println("</td>");
          
          out.print("<td>");
          out.print(Tag.name(results.tag()));
          out.println("</td>");
          
          out.print("<td>");
          out.print(results.freq()) ;
          out.println("</td>");

          out.print("<td>");
          out.print(results.occs());
          out.println("</td>");

          out.print("<td>");
          out.print(results.hits()) ;
          out.println("</td>");

          out.print("<td>");
          out.print(results.docs());
          out.println("</td>");

          
          out.print("    <td class=\"num\">");
          out.print(format(results.score()));
          out.println("</td>");
          out.println("  </tr>");
        }
       %>
    </table>
  </body>
</html>