<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="alix.util.IntPair" %>
<%@ page import="alix.util.Top" %>
<%@ page import="alix.lucene.search.FieldRail.Bigram" %>
<%!



%>
<%
JspTools tools = new JspTools(pageContext);
Alix alix = (Alix)tools.getMap("base", Alix.pool, BASE, "alixBase");
int limit = tools.getInt("limit", 500);
String book = tools.getString("book", null);
MI mi = (MI)tools.getEnum("mi", MI.none);

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
      <form class="search">
       <label>Sélectionner un livre
       <br/><select name="book" onchange="this.form.submit()">
            <option value=""></option>
            <%
int[] books = alix.books(sortYear);
for (int docId: books) {
  Document doc = alix.reader().document(docId, BOOK_FIELDS);
  String abid = doc.get(Alix.BOOKID);
  out.print("<option value=\"" + abid + "\"");
  if (abid.equals(book)) out.print(" selected=\"selected\"");
  out.print(">");
  String year = doc.get("year");
  if (year != null) out.print(year + ", ");
  out.print(doc.get("title"));
  out.println("</option>");
}
                  %>
         </select>
       </label>
         <label>Algorithme de score
         <br/><select name="mi" onchange="this.form.submit()">
             <option/>
             <%= mi.options() %>
          </select>
         </label>
      </form>
      <table class="sortable">
        <caption><i>Information mutuelle</i>, où les mots qui vont bien ensemble</caption>
        <thead>
          <tr>
            <td/>
            <th>Couple (ab)</th>
            <th>ab</th>
            <th>a</th>
            <th>b</th>
            <th>Score</th>
            <th width="100%"/>
            <td/>
          <tr>
        </thead>
        <tbody>

<%
final String fieldName = TEXT + "_orth";
FieldText field = alix.fieldText(fieldName);
FieldRail rail = alix.fieldRail(fieldName);


long N = field.occsAll;
long[] formOccs;

BitSet filter = null; // if a corpus is selected, filter results with a bitset
if (book != null) {
  filter = Corpus.bits(alix, Alix.BOOKID, new String[]{book});
  formOccs = field.formOccs(filter);
  N = formOccs[0];
}
else {
  formOccs = field.formAllOccs;
}

Map<IntPair, Bigram> dic = rail.expressions(filter);
Top<Bigram> top= new Top<Bigram>(limit);
final int pun1 = field.formId(",");
final int pun2 = field.formId(".");
final int pun3 = field.formId("§");
for (Bigram bigram: dic.values()) {
  // if (field.isStop(bigram.a) || field.isStop(bigram.b)) continue;
  // if (bigram.a == 0 || bigram.a == pun1 || bigram.a == pun2 || bigram.a == pun3) continue;
  // if (bigram.b == 0 || bigram.b == pun1 || bigram.b == pun2 || bigram.b == pun3) continue;
  int Oab = bigram.count;
  long Oa = formOccs[bigram.a];
  // if (Oa == 0) continue; // strange but observed
  long Ob = formOccs[bigram.b];
  // if (Ob == 0) continue; // strange but observed
  double score = mi.score(Oab, Oa, Ob, N);
  bigram.score = score;
  top.push(score, bigram);
}

int no = 0;
for (Top.Entry<Bigram> entry: top) {
  no++;
  Bigram bigram = entry.value();
  out.println("  <tr>");
  out.println("    <td class=\"no left\">"  + no + "</td>");
  out.print("    <td class=\"form\">");
  out.print(bigram.label);
  /*
  final String a = field.label(entry.value().a);
  final String b = field.label(entry.value().b);
  out.print(a);
  if (!a.endsWith("'")) out.print(" ");
  out.print(b);
  */
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(bigram.count);
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(formOccs[bigram.a]);
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(formOccs[bigram.b]);
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(dfscore.format(bigram.score));
  out.println("</td>");  
  out.println("    <td></td>");
  out.println("    <td class=\"no right\">" + no + "</td>");
  out.println("  </tr>");
}

%>
       </table>
    </main>
  </body>
</html>