<%@ page language="java"  pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="alix.lucene.analysis.FrDics" %>
<%@ page import="alix.lucene.analysis.FrDics.LexEntry" %>
<%@ page import="alix.util.IntPair" %>
<%@ page import="alix.util.Top" %>
<%@ page import="alix.lucene.search.FieldRail.Bigram" %>
<%!

%>
<%@ include file="jsp/prelude.jsp" %>
<%
int limit = tools.getInt("limit", 500);
int floor = tools.getInt("floor", 0);
boolean parceque = tools.getBoolean("parceque", false);
boolean locs = tools.getBoolean("locs", false);
String book = tools.getString("book", null);
MI mi = (MI)tools.getEnum("mi", MI.g);
final String fieldName = "text" + "_orth";

FieldText ftext = alix.fieldText(fieldName);
FieldRail frail = alix.fieldRail(fieldName);

%>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="local/head.jsp"%>
    <title>Expressions</title>
  </head>
  <body>
     <header>
      <%@ include file="local/tabs.jsp"%>
      <form class="search">
        <%= selectCorpus(alix.name) %>
        <%= selectBook(alix, book) %>
        <br/>
        <label>Score</label>
        <select name="mi" onchange="this.form.submit()">
             <option/>
             <%= mi.options() %>
          </select>
       <label for="locs" title="Montrer les locutions connues du dictionnaire d’indexation">Locutions</label>
       <input name="locs" type="checkbox" <%= (locs)?"checked":"" %> onchange="this.form.submit()"/>
       <label for="floor">Fréquence minimale</label>
       <input name="floor" size="1" class="num3" value="<%= (floor > 0)?floor:"" %>"/>
       <label for="parceque">Mots vides</label>
       <input name="parceque" type="checkbox" <%= (parceque)?"checked":"" %> onchange="this.form.submit()"/>
      </form>
    </header>
    <main>
      <table class="sortable">
        <caption>
      <details>
        <summary>Expressions fréquentes</summary>
        <p>
        Ce tableau montre les expressions fréquentes. 
        Il est produit à partir d’un index des mots fléchis (sans lemmatisation, sans dictionnaire de locutions).
        
        </p>
      </details>
        </caption>
        <thead>
          <tr>
            <th/>
            <th align="right">ab</th>
            <th title="occurrences">occs</th>
            <th class="num">score</th>
            <th align="right">a</th>
            <th title="occurrences">occs</th>
            <th align="right">b</th>
            <th title="occurrences">occs</th>
            <th width="100%"/>
            <th/>
          <tr>
        </thead>
        <tbody>

<%


final long N = ftext.occsAll;
final long[] formOccs = ftext.formOccsAll;;

BitSet filter = null; // if a corpus is selected, filter results with a bitset
if (book != null) {
  filter = Corpus.bits(alix, Alix.BOOKID, new String[]{book});
  // formOccs = field.formOccs(filter);
  // N = formOccs[0];
}
TagFilter tags = new TagFilter().setAll().noStop(true).clear(Tag.SUB).clear(Tag.VERB); // .clearGroup(Tag.SUB).clearGroup(Tag.VERB);
BitSet rule = ftext.formRule(tags);
Map<IntPair, Bigram> dic = frail.expressions(filter, tags);


Top<Bigram> top= new Top<Bigram>(limit);
final int pun1 = ftext.formId(",");
final int pun2 = ftext.formId(".");
final int pun3 = ftext.formId("§");
for (Bigram bigram: dic.values()) {
  if (bigram.count <= floor) continue;
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
  String css = "";
  LexEntry lex = FrDics.name(bigram.label);
  if (lex != null) {
    css += " NAME";
  }
  else {
    lex = FrDics.word(bigram.label);
    if (lex != null) css += " LOC";
  }
  if (!locs && lex != null) continue;
  out.println("  <tr>");
  out.println("    <td class=\"no left\">"  + no + "</td>");
  out.print("    <td class=\"form " + css + "\">");
  out.print(bigram.label);
  /*
  final String a = field.label(entry.value().a);
  final String b = field.label(entry.value().b);
  out.print(a);
  if (!a.endsWith("'")) out.print(" ");
  out.print(b);
  */
  out.println("</td>");
  /*
  out.print("    <td>");
  if (lex != null) out.print(Tag.label(lex.tag));
  out.println("</td>");
  */
  out.print("    <td class=\"num\">");
  out.print(bigram.count);
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(formatScore(bigram.score));
  out.println("</td>");
  out.print("    <td align=\"right\">");
  out.print(ftext.form(bigram.a));
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(formOccs[bigram.a]);
  out.println("</td>");
  out.print("    <td align=\"right\">");
  out.print(ftext.form(bigram.b));
  out.println("</td>");
  out.print("    <td class=\"num\">");
  out.print(formOccs[bigram.b]);
  out.println("</td>");
  out.println("    <td></td>");
  out.println("    <td class=\"no right\">" + no + "</td>");
  out.println("  </tr>");
}
%>
       </table>
    </main>
  <script src="<%= hrefHome %>vendor/sortable.js">//</script>
  </body>
</html>