(function() {
"use strict";

var Dygraph;
if (window.Dygraph) {
  Dygraph = window.Dygraph;
} else if (typeof(module) !== 'undefined') {
  Dygraph = require('../dygraph');
}


    
// Darken a color
function darken(colorStr) {
  // Defined in dygraph-utils.js
  var color = Dygraph.toRGB_(colorStr);
  color.r = Math.floor((255 + color.r) / 2);
  color.g = Math.floor((255 + color.g) / 2);
  color.b = Math.floor((255 + color.b) / 2);
  return 'rgb(' + color.r + ',' + color.g + ',' + color.b + ')';
}


function plotHoles(e)
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
function plotStep(e) {
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
function plotBar(e) {
      
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

function plotHistory(e) {


  var ctx = e.drawingContext;
  var points = e.points;
  ctx.fillStyle = e.color;
  let past = 1;
  let future = 2;

  // Do the actual plotting.
  // ctx.globalAlpha = 0.25;

  for (var i = 0; i < points.length; i++) {
    var p = points[i];
    ctx.beginPath();
    ctx.arc(p.canvasx, p.canvasy, 5, 0, 2 * Math.PI, false);
    ctx.fill();
  }
  ctx.globalAlpha = 1

  // verify points
  for (var i = 0; i < points.length; i++) {
    let p = points[i];
    if (!p || p.canvasy === undefined || isNaN(p.canvasy)) points[i] = null;
  }
  // draw a smoothed line
  ctx.beginPath();
  let max = points.length - 1;
  for (var i = 0; i <= max; i++) {
    let p = points[i];
    if (!p) continue;
    let sum = 0;
    let count = 0;
    let pos = i;
    let from = Math.max(0, i-past);
    while(--pos >= from) {
      let p2 = points[pos];
      if(!p2) break;
      sum += p2.canvasy;
      count++;
    }
    pos = i;
    let to = Math.min(max, i+future);
    while(pos <= to) {
      let p2 = points[pos];
      if(!p2) break;
      sum += p2.canvasy;
      count++;
      pos++;
    }
    let y = sum / count;
    if(i && !points[i-1]) {
      ctx.moveTo(p.canvasx, y);
    }
    else {
      ctx.lineTo(p.canvasx, y);
    }
  }
  ctx.stroke();

}

Dygraph.plotHistory = plotHistory;
Dygraph.plotBar = plotBar;
Dygraph.plotHoles = plotHoles;

})();
