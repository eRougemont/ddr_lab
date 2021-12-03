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
// response.setHeader("Content-type", "text/tab-separated-values; charset=UTF-8");
response.setHeader("Content-type", "application/csv; charset=UTF-8");
response.setHeader("Content-Disposition", "attachment; filename=rougemont_freqs.tsv");

pars.limit = -1;
FormEnum results = freqList(alix, pars);

out.println("Mot\tCatégorie\tOccurrences\t/occurrences\tTextes\t/textes\tScore");
results.reset();
while (results.hasNext()) {
   results.next();
   String term = results.form();
   out.print(term);
   out.print("\t");
   out.print(Tag.name(results.tag()));
   out.print("\t");
   out.print(results.freq()) ;
   out.print("\t");
   out.print(results.occs());
   out.print("\t");
   out.print(results.hits()) ;
   out.print("\t");
   out.print(results.docs());
   out.print("\t");
   out.print(format(results.score()));
   out.println("");
 }


%>