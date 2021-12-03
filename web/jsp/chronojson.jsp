<%@ page language="java" contentType="text/javascript; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.lucene.Alix" %>
<%@ page import="alix.lucene.search.*" %>
<%@ page import="alix.lucene.search.FieldInt.IntEnum" %>
<%@ page import="alix.web.*" %>

<%!
%>
<%@ include file="prelude.jsp" %>
<%
final String YEAR = "year";
FieldInt fint = alix.fieldInt(YEAR, pars.field.name());
IntEnum iterator = fint.iterator();

out.println("{");
// get a query
String formsLabel = "";
String[] forms = null;
int formsLenght = 0;
if (pars.q != null) {
  out.print( "  \"q\": \"" + pars.q.replace("\"", "\\\"")+"\",\n");
  // get words in the query
  forms = alix.forms(pars.q, pars.field.name());
  // get the count of occurrences found by year
  for (String form: forms) {
    fint.form(iterator, form);
    formsLabel += ", \"" + form.replace("\"", "\\\"") + "\"";
  }
  formsLenght = forms.length;
}

out.println("  labels: [\"Date\", \"Taille des textes\"" + formsLabel + "],");

out.println("  \"data\": [");
boolean first = true;
while (iterator.hasNext()) {
  iterator.next();
  if (first) first = false;
  else out.print(",\n");
  out.print("    [" + iterator.value() + ", " + iterator.occs());
  for (int i = 0; i < formsLenght; i++) {
    final String form = forms[i];
    long occs = iterator.occs(form);
    if (occs > 0)  out.print(", " + occs);
    else out.print(", null");
  }
  out.print("]");
}
out.println();
out.println("  ]"); // data end
out.print("}");




/*
// display ticks
long partial = System.nanoTime();
out.print( "  \"ticks\": "+ticks(scale)+",\n");
out.println("  \"time\" : \"" + (System.nanoTime() - partial) / 1000000.0 + "ms\",");


if (terms.size() > 0) {
  terms.sortByRowFreq(); // sort query lines by freq
  out.print("  \"labels\": [\"\"");
  boolean first = true;
  for(Term t: terms) {
    if (t == null) continue;
    out.print(", \"");
    out.print(t.text().replace("\"", ""));
    out.print("\"");
  }
  out.println("],");
  // get dots by curve
  long[][] data = scale.curves(terms, dots);
  long step = data[0][1];
  // 
  int rows = data[0].length;
  int cols = data.length;
  
  first = true;
  for (int row = 0; row < rows; row++) {
    // do not print empty rows (easier for curve display)
    long sum = 0;
    for (int col = 1; col < cols; col++) sum += data[col][row];
    if (sum == 0) continue;
    
    if (first) first = false;
    else out.print(",\n");
    
    out.print("    [");
    out.print(data[0][row]);
    for (int col = 1; col < cols; col++) {
      out.print(", ");
      long count = data[col][row];
      if (count < 2) {
        out.print("null");
        continue;
      }
      double ppm = Math.round(10.0 * 100000.0 * count / step) / 10.0;
      out.print(ppm);
    }
    out.print("]");
  }
  out.println("\n  ],");
  // labels for points
  out.println("  \"legend\": {");
  data = scale.legend(dots);
  first = true;
  long[] cumul = data[0];
  long[] year = data[1];
  long[] start = data[2];
  for (int row = 0; row < rows; row++) {
    if (first) first = false;
    else out.print(",\n");
    out.print("    \"");
    out.print(cumul[row]);
    out.print("\": {");
    out.print("\"year\":");
    out.print(year[row]);
    out.print(", \"start\":");
    out.print(start[row]);
    out.print("}");
  }
  out.println("\n  },");
}
out.println("  \"time\" : \"" + (System.nanoTime() - time) / 1000000.0 + "ms\"");
out.println("\n}");
*/
%>