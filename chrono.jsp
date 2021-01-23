<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%@ page import="alix.web.JspTools" %>
<%
long time = System.nanoTime(); 
JspTools tools = new JspTools(pageContext);
String q = tools.getString("q", null);
%>
<!DOCTYPE html>
<html>
  <head>
   <jsp:include page="ddr_head.jsp" flush="true" />    
    <title>Chronologie</title>
    <script src="vendor/dygraph.min.js">//</script>
    <script src="vendor/plotHistory.js">//</script>
    <style type="text/css">
#chart {
  font-family: sans-serif;
  width: 100%;
  height: 600px;
  cursor: pointer;
  padding-bottom: 10px;
}
#chartframe {
  background: #eee;
  padding: 20px;
}

.dygraph-legend {
  background: rgba(200, 200, 200, 0.5) !important;
}

    </style>
  </head>
  <body>
    <header>
       <jsp:include page="tabs.jsp" flush="true" />
    </header>
  
    <main>
            <form id="qform"  class="search">
              <label>Chronologie
              <br/><input id="q" name="q" value="<%=JspTools.escape(q)%>" width="100" autocomplete="off"/>
              </label>
              <button type="submit">▶</button>
            </form>
    <div id="chartframe">
      <div id="chart" class="dygraph"></div>
    </div>
    <script>
var json = <jsp:include page="jsp/chronojson.jsp" flush="true" />;

    
// Darken a color
function darken(colorStr) {
  // Defined in dygraph-utils.js
  var color = Dygraph.toRGB_(colorStr);
  color.r = Math.floor((255 + color.r) / 2);
  color.g = Math.floor((255 + color.g) / 2);
  color.b = Math.floor((255 + color.b) / 2);
  return 'rgb(' + color.r + ',' + color.g + ',' + color.b + ')';
}

var barCount = json.labels.length - 2;


function plotterHoles(e)
{
  var barNo = e.seriesIndex - (e.seriesCount - barCount); // start 0
  var stroke = true;
  // global variables handlers
  var points = e.points;
  var ctx = e.drawingContext;
  // suppose positive only value
  var zero = 0;
  if(e.axis.ylogscale) zero = 1;
  var bottom = e.dygraph.toDomYCoord(zero);
  // find a supposed step between values
  var step = Infinity;
  for (var i = 1; i < points.length; i++) {
    var dif = points[i].canvasx - points[i - 1].canvasx;
    if (dif < step) step = dif;
  }
  // build a polygon
  var stepTol = 1.01; // tolerance on step before connecting points
  ctx.fillStyle = e.color;
  ctx.globalAlpha = 0.1;
  ctx.lineWidth = 25;
  ctx.setLineDash([]);
  ctx.lineJoin = "round";
  var pathOn = false;
  if (stroke) {
    for (var i = 0; i < points.length; i++) {
        var p = points[i];
        if (pathOn) ctx.lineTo(p.canvasx, p.canvasy);
        if (i == points.length - 1) continue;
        // connect to next point ?
        var pNext = points[i+1];
        if (isNaN(pNext.canvasy) || (pNext.canvasx - p.canvasx) > (stepTol * step)) {
          // hole
          if (!pathOn) continue;
          // end of connection
          ctx.stroke();
          ctx.closePath();
          pathOn = false;
          continue;
        }
        // continue conection
        if (pathOn) continue;
        // start connection
        ctx.beginPath();
        ctx.moveTo(p.canvasx, p.canvasy);
        pathOn = true;
      }
      if (pathOn) {
        ctx.stroke();
        ctx.closePath();
      }
  }
  // Dots
  ctx.globalAlpha = 1;
  ctx.setLineDash([]);
  ctx.lineWidth = 1.5;
  ctx.strokeStyle = '#fff';
  for (var i = 0; i < points.length; i++) {
    var p = points[i];
    if (isNaN(p.canvasy)) continue;
    ctx.beginPath();
    ctx.arc(p.canvasx, p.canvasy, 8, 0, 2 * Math.PI, false);
    ctx.fill();
    ctx.stroke();
    ctx.closePath();
    /*
    ctx.beginPath();
    ctx.arc(p.canvasx, p.canvasy, 7, 0, 2 * Math.PI, false);
    ctx.stroke();
    ctx.closePath()
    */
  }
}

/**
 * Not yet complete
 */
function plotterStep(e) {
  console.log("  e.seriesIndex=" +  e.seriesIndex + " e.seriesCount=" + e.seriesCount); // allSeriesPoints

  var zero = 0;
  if(e.axis.ylogscale) zero = 1;
  var bottom = e.dygraph.toDomYCoord(zero);
  var points = e.points;
  var ctx = e.drawingContext;

  // find the step between values
  var step = Infinity;
  for (var i = 1; i < points.length; i++) {
    var dif = points[i].canvasx - points[i - 1].canvasx;
    if (dif < step) step = dif;
  }
  var barWidth = step;

  ctx.globalAlpha = 1;
  for (var i = 0; i < points.length; i++) {
    var p = points[i];
    var yLow = bottom;
    if (i > 0) {
      var pLast = points[i-1];
      if (p.canvasx - pLast.canvasx < 1.1 * step) yLow = pLast.canvasy;
    }
    
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(p.canvasx - (barWidth / 2), yLow);
    ctx.lineTo(p.canvasx - (barWidth / 2), p.canvasy);
    ctx.lineTo(p.canvasx + (barWidth / 2), p.canvasy);
    ctx.stroke();
  }
}
// 
function plotterBar(e) {
      
  var barNo = e.seriesIndex - (e.seriesCount - barCount); // start 0
  
  var ctx = e.drawingContext;
  var points = e.points;
  var zero = 0;
  if(e.axis.ylogscale) zero = 1;
  var yBottom = e.dygraph.toDomYCoord(zero);

  // find the step between values
  var step = Infinity;
  for (var i = 1; i < points.length; i++) {
    var dif = points[i].canvasx - points[i - 1].canvasx;
    if (dif < step) step = dif;
  }

  var barWidth = step - 2; // some spacing
  // var barWidth = Math.floor(2.0 / 3 * min_sep);  // spacing ?

  var zeCount = 1; // barCount
  // Do the actual plotting.
  ctx.fillStyle = e.color;
  // ctx.globalAlpha = 0.3;
  for (var i = 0; i < points.length; i++) {
    var p = points[i];
    ctx.fillRect(p.canvasx - barWidth/2, p.canvasy, barWidth, yBottom - p.canvasy);
    /* a round on a bar ?
    ctx.beginPath();
    ctx.arc(xLeft + (barWidth / (2 * zeCount)), p.canvasy, (0.3 * barWidth / zeCount), 0, 2 * Math.PI, false);
    ctx.fill();
    */
    // ctx.fillRect(xCenter - (barWidth / 2), p.canvasy, barWidth, 3);
    /*
    ctx.lineWidth = 3;
    ctx.stroke();
    */
  }
}

var attrs = {
  title : "Occurrences par années",
  labels: json.labels,
  legend: "always",
  labelsSeparateLines: true,
  ylabel: "occurrences",
  y2label: "Taille des textes",
  // logscale: true,
  // xlabel: "Répartition des années en nombre de mots",
  // clickCallback: xClick,
  logscale: true,
  plotter: plotterHoles,
  strokeWidth: 0.5,
  drawPoints: true,
  pointSize: 8,
  series: {
     "Taille des textes": {
       axis: (json.labels.length > 2)?'y2':null,
       plotter: plotterBar,
       /*
       drawPoints: false,
       strokeWidth: 3,
       fillGraph: true,
       */
     },
  },
  // plotter: Dygraph.plotHistory,
  
  colors:['rgba(255, 255, 255, 0.8)', 'rgba(255, 26, 26, 0.7)', 'rgba(26, 26, 192, 0.7)', 'rgba(26, 128, 26, 0.7)', 'rgba(0, 128, 192, 0.7)', 'rgba(146,137,127, 0.7)', 'rgba(192, 128, 0, 0.7)'],

  // logscale: true,
  axes : {
    x: {
      drawGrid: true,
      gridLineColor: "rgba(160, 160, 160, 0.2)",
      gridLineWidth: 3,
    },
    y:{
      drawGrid: true,
      gridLineColor: "rgba(192, 192, 192, 0.7)",
      gridLineWidth: 1,
    },
    y2:{
      independentTicks: true,
      drawGrid: false,
      labelsKMB: true,
        // gridLineColor: "rgba( 128, 128, 128, 0.1)",
        // gridLineWidth: 1,
    },
  },
};
var div = document.getElementById("chart");
g = new Dygraph(div, json.data, attrs);

      </script>
    </main>
  </body>
</html>
