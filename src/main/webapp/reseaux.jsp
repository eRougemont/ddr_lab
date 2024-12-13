<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="org.apache.lucene.search.highlight.DefaultEncoder"%>
<%@ page import="org.apache.lucene.search.highlight.Encoder"%>
<%@ page import="org.apache.lucene.search.similarities.*" %>
<%@ page import="org.apache.lucene.search.vectorhighlight.FastVectorHighlighter"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.FieldQuery"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.FragListBuilder"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.FragmentsBuilder"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.SimpleFragListBuilder"%>
<%@ page import="org.apache.lucene.search.vectorhighlight.SimpleFragmentsBuilder"%>

<%@ page import="com.github.oeuvres.alix.lucene.search.Doc" %>
<%@ page import="com.github.oeuvres.alix.util.Top" %>
<%!


static final HashSet<String> TEXT_FIELDS = new HashSet<String>(
    Arrays.asList(new String[] { ALIX_ID, ALIX_BOOKID, BIBL})
);



%>
<%
final FieldInt fint = alix.fieldInt(YEAR);
final int[] dates = tools.getIntRange(YEAR, new int[]{fint.min(), fint.max()});
String[] datePar = request.getParameterValues(YEAR);
String from = "" + ((dates==null || datePar==null || datePar.length < 1 || datePar[0] == null || datePar[0].isBlank())?"":dates[0]);
String to = ""+ ((dates==null || datePar==null || datePar.length < 2 || datePar[1] == null || datePar[1].isBlank())?"":dates[1]);



%>
<!DOCTYPE html>
<html class="document">
    <head>
        <%@ include file="local/head.jsp" %>
        <title>Réseau, Rougemont</title>
    </head>
    <body class="labo">
        <header id="header">
            <jsp:include page="local/tabs.jsp"/>
        </header>
        <main>
            <form  id="filter" class="tags">
                <button type="submit" class="icon magnify">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z"></path></svg>
                </button>
                <input form="filter" type="text" value="<%= tools.escape(tools.getString("q", "")) %>" class="q" name="q" id="sugg" src="data/suggest?q="/>
                <a href="?" class="icon cross">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"></path></svg>
                </a>
                <label>Entre 
                    <input class="year" name="year" value="<%=from%>" />
                </label>
                <label>et
                    <input class="year" name="year" value="<%=to%>" />
                </label>
                <label>
                    <select name="book">
                        <option></option>
<%
final String[] books = new String[]{
"ddr19290300mip",
"ddr19320900paysan",
"ddr19341025polpers",
"ddr19361100pm",
"ddr19370600jic",
"ddr19381012ja",
"ddr19390600ao",
"ddr19390815nf",
"ddr19400430mds",
"ddr19400800lg",
"ddr19421200partdia",
"ddr19441100partdia",
"ddr19441210persdram",
"ddr19460615lba1",
"ddr19460701lba2",
"ddr19460900polpers",
"ddr19461206jdm",
"ddr19470307va",
"ddr19470703df",
"ddr19480401sn",
"ddr19480630ej",
"ddr19500813lde",
"ddr19510300lpp",
"ddr19531215ch",
"ddr19560200ao",
"ddr19570200aoh",
"ddr19581200dver",
"ddr19590300oe",
"ddr19610400ctm",
"ddr19611200vhse",
"ddr19620830ce",
"ddr19650600shph",
"ddr19651030fc",
"ddr19680314jde",
"ddr19700900loe",
"ddr19701000cde",
"ddr19701005udce",
"ddr19720400dfso",
"ddr19720600pm",
"ddr19721000mip",
"ddr19721100ao",
"ddr19730100resea",
"ddr19740600jdef",
"ddr19750200cernfec",
"ddr19770721aena",
"ddr19790423rpe",
"ddr19820500partdia",
"ddr19820900paysan",
"ddr19880300in"};
final String book = tools.getString("book", null);
for (final String value: books ) {
    String selected = "";
    if (value.equals(book)) {
        selected = " selected";
    }
    out.println("<option" + selected + ">" + value + "</option>");
}
%>
                    </select>
                </label>
<%
final String tagReq = tools.getString("tag", null);
// A query ?
final String q;
{
    q = null;
}
// list of terms
final FieldInfo info = FieldInfos.getMergedFieldInfos(reader).fieldInfo(TAG);
if (info != null) {
    final FieldFacet tagField = alix.fieldFacet(TAG);
    FormEnum tagEnum = tagField.formEnum();
    tagEnum.sort(FormIterator.Order.DOCS);
    tagEnum.reset();
    String checked = " checked";
    out.println("<label class=\"tag\" title=\"Textes édités : articles et chapitres de livre\"><input type=\"radio\" name=\"tag\" value=\"\"" + ((tagReq==null)?checked:"") + "> Tout<output name=\"ALL\"></output></label>");
    while (tagEnum.hasNext()) {
        tagEnum.next();
        final String tagForm = tagEnum.form();
        final int count;
        if (q != null) {
            count = tagEnum.hits();
        }
        else {
            count = tagEnum.docs();
        }
        out.println("<label class=\"tag\"><input type=\"radio\" name=\"tag\"" + ((tagForm.equals(tagReq))?checked:"") + " value=\"" + tagForm + "\"> " + tagForm + "<output name=\"" + tagForm + "\"></output></label>");
    }
}
%>
                </form>
                <div class="body">
                    <div class="graphcont">
                        <div id="graph" class="sigma" oncontextmenu="return false">
                        </div>
                        <div class="graphbuts">
                            <button class="turnright but" type="button" title="Rotation vers la droite">↻</button>
                            <button class="turnleft but" type="button" title="Rotation vers la gauche">↺</button>
                            <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button>
                            <button class="zoomout but" type="button" title="Diminuer">−</button>
                            <button class="zoomin but" type="button" title="Grossir">+</button>
                            <button class="fontdown but" type="button" title="Diminuer le texte">S↓</button>
                            <button class="fontup but" type="button" title="Grossir le texte">S↑</button>
                            <button class="shot but" type="button" title="Prendre une photo"><svg width="24" viewbox="0 0 240 176" version="1.1" id="camera" xmlns="http://www.w3.org/2000/svg"><circle cx="120" cy="90" id="obj" r="40" style="fill:none"/><circle cx="48" cy="56" r="16" style="stroke:none;"/><path d="M168 24h32c32 0 32 32 32 32v80s0 32-32 32H40c-32 0-32-32-32-32V56s0-32 32-32h32c16-14 48-16 48-16s32 0 48 16z" id="box" style="fill:none"/></svg></button>
                             <!--
                            <button class="colors but" type="button" title="Gris ou couleurs">◐</button>
                            <button class="but restore" type="button" title="Recharger">O</button>
                            <button class="FR but" type="button" title="Spacialisation Fruchterman Reingold">☆</button>
                            -->
                            <button class="mix but" type="button" title="Mélanger le graphe">♻</button>
                            <button class="atlas2 but" type="button" title="Démarrer ou arrêter la gravité atlas 2">▶</button>
                            <!--
                            <span class="resize interface" style="cursor: se-resize; font-size: 1.3em; " title="Redimensionner la feuille">⬊</span>
                            -->
                        </div>
                    </div>
                    <div id="kwic" class="kwic_results"> </div>
                </div>
            </div>
        </main>
        <%@include file="local/footer.jsp" %>
<script src="<%=hrefHome%>lib/sigma/sigma.min.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.plugins.dragNodes.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.exporters.image.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.plugins.animate.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.layout.fruchtermanReingold.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.layout.forceAtlas2.js">//</script>
<script src="<%=hrefHome%>lib/sigma/sigma.layout.noverlap.js">//</script>
<script src="<%=hrefHome%>lib/sigmot.js">//</script>
<script src="<%=hrefHome%>lib/suggest.js">//</script>
        <script>
suggest(document.getElementById("sugg"), ["tag", "year"]);
        </script>
    </body>
</html>
