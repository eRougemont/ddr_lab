<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ include file="jsp/prelude.jsp" %>
<!DOCTYPE html>
<html>
  <head>
    <%@ include file="local/head.jsp" %>
    <title>Graphe de texte</title>
    <script src="<%=hrefHome%>vendor/sigma/sigma.min.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.dragNodes.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.exporters.image.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.plugins.animate.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.fruchtermanReingold.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.forceAtlas2.js">//</script>
    <script src="<%=hrefHome%>vendor/sigma/sigma.layout.noverlap.js">//</script>
    <script src="<%=hrefHome%>static/sigmot.js">//</script>
    <script src="<%=hrefHome%>static/alix.js">//</script>
    <script>
    </script>
  </head>
  <body class="wordnet">
    <div id="graphcont">
      <header>
        <jsp:include page="local/tabs.jsp"/>
      </header>

      <form id="form" class="search">
        <%= selectCorpus(alix.name) %>,
        <%= selectBook(alix, pars.book) %>
        <button type="submit">▶</button>
        
        <br/>
        <label for="nodes">Noeuds : </label>
        <input name="nodes" type="text" value="<%= pars.nodes %>" class="num3" size="2"/>
        <select name="cat" onchange="this.form.submit()"  title="Filtrer les mots par catégories grammaticales">
          <option/>
          <%=pars.cat.options()%>
        </select>
        (<select name="f" onchange="this.form.submit()">
          <option/>
          <%=pars.field.options()%>
        </select>),
        <label for="order" title="Sélectionner et ordonner le tableau selon une colonne">rangés par</label>
        <select name="order" onchange="this.form.submit()">
          <option/>
          <%= pars.order.options("score freq")%>
        </select>.
        
        <br/>
        <label for="edges" title="Nombre de de liens">Liens :</label>
        <input type="text" name="edges" value="<%=pars.edges%>" class="num3" size="2"/>,
        <label for="dist" title="Largeur du contexte dont sont extraits les liens, en nombre de mots">contexte</label>
        <input name="dist" value="<%=pars.dist%>" size="1" class="num3"/>
        mots.
      </form>
      <div id="graph" class="graph" oncontextmenu="return false">
      </div>
       <div class="butbar">
         <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
         <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
         <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button>
         <button class="zoomout but" type="button" title="Diminuer">–</button>
         <button class="zoomin but" type="button" title="Grossir">+</button>
         <button class="fontdown but" type="button" title="Diminuer le texte">S↓</button>
         <button class="fontup but" type="button" title="Grossir le texte">S↑</button>
         <button class="shot but" type="button" title="Prendre une photo">📷</button>
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
    <script>
<jsp:include page="jsp/wordnet.jsp" flush="true" />;
var graph = new sigmot('graph', data);
    </script>
    <main>
      <div class="row">
        <div class="text" id="aide">
            <p>Nœuds : les <%= pars.nodes %> <%= pars.field %> en ordre </p>
          <p><strong>Indices de lecture —</strong>
            Les mots sont colorés selon leur fonction, les substantifs sont en blanc, les noms en vert, et les adjectifs en orange.
            Ces types de mots sont généralement les plus significatifs du contenu sémantique d’un texte. 
            La taille d’un mot est représentative de son nombre d’occurrences dans la section de texte sélectionnée.
            L’épaisseur d’un lien entre deux mots est représentative du nombre d’apparitions ensemble.
          </p>
          <p><strong>Placement gravitationnel —</strong>
          Le placement des mots résulte d’un algorithme <i>gravitationnel</i>, qui essaie de rapprocher les mots les plus liés
          (comme des planètes par l’attraction). Il en résulte que le les directions haut ou bas ne sont pas significatives,
          c’est à l’humain de retourner le réseau dans le sens qui est le plus lisible pour lui (avec les boutons 
           <button class="turnleft but" type="button" title="Rotation vers la gauche">↶</button>
           <button class="turnright but" type="button" title="Rotation vers la droite">↷</button>
          ). Dans la mesure du possible, l’algorithme essaie d’éviter que les mots se recouvrent, mais 
          l’arbitrage entre cohérence générale des dsitances et taille des mots peut laisser quelques mots peu lisibles.
          Le bouton <button class="noverlap but" type="button" title="Écarter les étiquettes">↭</button> tente d’écater au mieux les étiquettes.
          L’utilisateur peut aussi zoomer pour entrer dans le détail d’une zone
          (<button class="zoomout but" type="button" title="Diminuer">–</button>
            <button class="zoomin but" type="button" title="Grossir">+</button>), et déplacer le réseau en cliquant tirant l’image globale.
            Le bouton <button class="mix but" type="button" title="Mélanger le graphe">♻</button> permet de tout mélanger,
            
            
          </p>
        </div>
      </div>
    </main>
  </body>
</html>



