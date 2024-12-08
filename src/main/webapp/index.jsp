<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<!DOCTYPE html>
<html>
  <head>
    <jsp:include page="local/head.jsp" flush="true"/>
    <title>Rougemont 2.0, labo [Alix]</title>
  </head>
  <body>
    <header id="header" class="top accueil">
      <jsp:include page="local/tabs.jsp"/>
      <div id="header_ban">
        <a id="portrait" href="https://www.unige.ch/rougemont">
         <img id="ddrtete" src="https://www.unige.ch/rougemont/packages/rougemont/themes/rougemont//img/ddr_portrait.png"/>
         <img class="signature" src="https://www.unige.ch/rougemont/packages/rougemont/themes/rougemont/img/ddr-signature.svg" alt="Denis de Rougemont, signature"/>
         <div id="moto">
           Denis de Rougemont,
           <br/>l’intégrale en ligne
          </div>
        </a>
      </div>
    </header>
    <main>
      <div class="row">
        <div class="text" id="aide">
          <h1><a href="https://www.unige.ch/rougemont/">Rougemont 2.0</a>, Labo</h1>
          <p>Cette interface permet d’explorer l’édition complète de <a href="https://www.unige.ch/rougemont/">Denis de Rougemont</a> développée par des chercheurs du <a href="https://www.unige.ch/gsi/fr/">GSI de l’université de Genève</a>. L’application est en développement actif pour régler les algorithmes les plus utiles aux spécialistes de l’œuvre, les fonctionnalités évoluent. Chaque onglet de la barre du haut propose un outil autonome pour explorer les mots du corpus, avec son formulaire, selon des approches plus ou moins globales ou analytiques. On trouvera :</p>
          <ul>
            <li><a href="graphe.jsp">Graphe</a> : une vue de mots en réseau, reliés à leurs co-occurrents les plus fréquents, sur tout ou parties du corpus, ou autour de mots recherchés.</li>
            <li><a href="table.jsp">Table</a> : une table de mots en ordre de fréquence, sur tout ou partie du corpus, ou autour de mots recherchés.</li>
            <li><a href="nuage.jsp">Nuage</a> : une nuage de mots, sur tout ou partie du corpus, ou autour de mots recherchés.</li>
            <li><a href="livres.jsp">Livres</a> : répartition sur le corpus, par livre/compilation, d’un ou plusieurs mots recherchés</li>
            <li><a href="chapitres.jsp">Chapitres</a> : répartition sur le corpus, par chapitre/article, d’un ou plusieurs mots recherchés</li>
            <li><a href="conc.jsp">Concordance</a> : occurences avec extraits, d’un ou plusieurs mots recherchés</li>
            <li><a href="doc.jsp">Liseuse</a> : occurences dans le contexte d’un chapitre/article, d’un ou plusieurs mots recherchés</li>
          </ul>
          <p><a href="#" onmouseover="if(this.ok)return; this.href='mai'+'lt'+'o:rougemont'+'\u0040'+'unige.ch'; this.ok=true">Renseignements</a></p>
        </div>
      </div>
    </main>
  </body>
</html>