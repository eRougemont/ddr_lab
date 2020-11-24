;(function(undefined) {
  'use strict';


  sigma.utils.pkg('sigma.canvas.labels');

  /**
   * This label renderer will just display the label on the center of the node.
   *
   * @param  {object}                   node     The node object.
   * @param  {CanvasRenderingContext2D} context  The canvas context.
   * @param  {configurable}             settings The settings function.
   */
  sigma.canvas.labels.def = function(node, context, settings) {
    var fontSize,
        prefix = settings('prefix') || '',
        labelWidth = 0,
        labelPlacementX,
        labelPlacementY,
        alignment,
        size = node[prefix + 'size']
    ;

    if (size < settings('labelThreshold'))
      return;

    if (!node.label || typeof node.label !== 'string')
      return;

    if (settings('labelAlignment') === undefined){
      alignment = settings('defaultLabelAlignment');
    } else {
      alignment = settings('labelAlignment');
    }


    /*
    fontSize = (settings('labelSize') === 'fixed') ?
      settings('defaultLabelSize') :
      settings('labelSizeRatio') * size;
    */
    
      
    var fontSize = (settings('labelSize') === 'fixed') ?
      settings('defaultLabelSize') :
      settings('defaultLabelSize') + settings('labelSizeRatio') * (size - settings('minNodeSize'));
    // if (['respirer', 'vivre'].includes(node.label)) console.log(node.label+" size="+size+" fontSize="+fontSize+" defaultLabelSize="+settings('defaultLabelSize'));


    context.font = (settings('fontStyle') ? settings('fontStyle') + ' ' : '') +
      fontSize + 'px ' + settings('font');

    labelWidth = context.measureText(node.label).width;
    labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
    labelPlacementY = Math.round(node[prefix + 'y'] + fontSize / 3);

    switch (alignment) {
      case 'inside':
        if (labelWidth <= size * 2){
          labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2 );
        }
        break;
      case 'center':
        labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2 );
        break;
      case 'left':
        labelPlacementX = Math.round(node[prefix + 'x'] - size - labelWidth - 3 );
        break;
      case 'right':
        labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
        break;
      case 'top':
        labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2 );
        labelPlacementY = labelPlacementY - size - fontSize;
        break;
      case 'bottom':
        labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2 );
        labelPlacementY = labelPlacementY + size + fontSize;
        break;
      default:
        // Default is aligned 'right'
        labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
        break;
    }
    // Node border:
    if (node.type == 'hub') {
      context.strokeStyle = 'rgba(128, 128, 128, 0.3)';
      context.lineWidth = 0.5 + 0.05 * fontSize;
      var padx = -4;
      var pady = 1;
      var x = labelPlacementX - padx;
      var y = Math.round(labelPlacementY + 2 + pady - fontSize);
      var w =labelWidth + 2 * padx;
      var h = Math.round(fontSize + 2 * pady);
      var e = Math.round(h / 2);

      context.fillStyle = 'rgba(192, 0, 0, 0.3)';
      context.beginPath();
      context.moveTo(x, y);
      // context.arcTo(x, y, x + e, y, e);
      context.lineTo(x + w, y);
      context.quadraticCurveTo(x+w+e, y, x+w+e, y+e);
      context.quadraticCurveTo(x+w+e, y+h, x+w, y+h);

      context.lineTo(x, y + h);
      context.quadraticCurveTo(x-e, y+h, x-e, y+e);
      context.quadraticCurveTo(x-e, y, x, y);

      context.closePath();

      context.stroke();
      // context.fill();

    }
    context.fillStyle = (settings('labelColor') === 'node') ?
      (node.color || settings('defaultNodeColor')) :
      settings('defaultLabelColor');

    context.fillText(
      node.label,
      labelPlacementX,
      labelPlacementY
    );

  };

  /**
   * Override the node over for centered labels
   *
   * @param  {object}                   node     The node object.
   * @param  {CanvasRenderingContext2D} context  The canvas context.
   * @param  {configurable}             settings The settings function.
   */
  sigma.canvas.hovers.def = function(node, context, settings) {
    var x,
        y,
        w,
        h,
        e,
        fontStyle = settings('hoverFontStyle') || settings('fontStyle'),
        prefix = settings('prefix') || '',
        size = node[prefix + 'size'],
        fontSize = (settings('labelSize') === 'fixed') ?
          settings('defaultLabelSize') :
          settings('labelSizeRatio') * size;

    // Label background:
    context.font = (fontStyle ? fontStyle + ' ' : '') +
      fontSize + 'px ' + (settings('hoverFont') || settings('font'));

    context.beginPath();
    context.fillStyle = settings('labelHoverBGColor') === 'node' ?
      (node.color || settings('defaultNodeColor')) :
      settings('defaultHoverLabelBGColor');

    if (node.label && settings('labelHoverShadow')) {
      context.shadowOffsetX = 0;
      context.shadowOffsetY = 0;
      context.shadowBlur = 8;
      context.shadowColor = settings('labelHoverShadowColor');
    }

    /*
    if (node.label && typeof node.label === 'string') {
      x = Math.round(node[prefix + 'x'] - fontSize / 2 - 2);
      y = Math.round(node[prefix + 'y'] - fontSize / 2 - 2);
      w = Math.round(
        context.measureText(node.label).width + fontSize / 2 + size + 7
      );
      h = Math.round(fontSize + 4);
      e = Math.round(fontSize / 2 + 2);

      context.moveTo(x, y + e);
      context.arcTo(x, y, x + e, y, e);
      context.lineTo(x + w, y);
      context.lineTo(x + w, y + h);
      context.lineTo(x + e, y + h);
      context.arcTo(x, y + h, x, y + h - e, e);
      context.lineTo(x, y + e);

      context.closePath();
      context.fill();

      context.shadowOffsetX = 0;
      context.shadowOffsetY = 0;
      context.shadowBlur = 0;
    }
    */

    /*
    // Node border:
    if (settings('borderSize') > 0) {
      context.beginPath();
      context.fillStyle = settings('nodeBorderColor') === 'node' ?
        (node.color || settings('defaultNodeColor')) :
        settings('defaultNodeBorderColor');
      context.arc(
        node[prefix + 'x'],
        node[prefix + 'y'],
        size + settings('borderSize'),
        0,
        Math.PI * 2,
        true
      );
      context.closePath();
      context.fill();
    }
    */

    // Node:
    var nodeRenderer = sigma.canvas.nodes[node.type] || sigma.canvas.nodes.def;
    // nodeRenderer(node, context, settings);

    /*
    // Display the label:
    if (node.label && typeof node.label === 'string') {
      context.fillStyle = (settings('labelHoverColor') === 'node') ?
        (node.color || settings('defaultNodeColor')) :
        settings('defaultLabelHoverColor');

      context.fillText(
        node.label,
        Math.round(node[prefix + 'x'] + size + 3),
        Math.round(node[prefix + 'y'] + fontSize / 3)
      );
    }
    */
  };

  /**
   * This label renderer will just display the label on the center of the node.
   *
   * @param  {object}                   node     The node object.
   * @param  {CanvasRenderingContext2D} context  The canvas context.
   * @param  {configurable}             settings The settings function.
   */
  sigma.canvas.labels.term = function(node, context, settings) {
  
    
    if (!node.label || typeof node.label !== 'string')
      return;
    var prefix = settings('prefix') || '';
    // no labels for little nodes
    if (node[prefix + 'size'] < settings('labelThreshold'))
      return;
    context.save();
    var scale = (settings('scale'))?settings('scale'):1;
    // node size relative to global size
    var nodeSize = node[prefix + 'size'] * scale * 0.7;
    // fontSize relative to nodeSize
    var fontSize = (settings('labelSize') === 'fixed') ?
      settings('defaultLabelSize') :
      settings('defaultLabelSize') + settings('labelSizeRatio') * (nodeSize - settings('minNodeSize'));
    // default font ?

    var height = parseInt(fontSize);
    var y = Math.round(node[prefix + 'y'] + nodeSize * 0.6);

    var small = 25;
    context.lineWidth = 1;
    // bg color
    if ( fontSize <= small) {
      context.font = fontSize+'px '+settings('font');
      var width = Math.round(context.measureText(node.label).width);
      var x = Math.round(node[prefix + 'x'] - (width / 2) );
      context.fillStyle = 'rgba(255, 255, 255, 0.6)';
      context.fillRect(x-fontSize*0.2, y - fontSize + fontSize/10, width+fontSize*0.4, height);
    }
    else {
      context.font = settings('fontStyle')+' '+fontSize+'px '+settings('font');
      var width = Math.round(context.measureText(node.label).width);
      var x = Math.round(node[prefix + 'x'] - (width / 2) );
      context.fillStyle = 'rgba(255, 255, 255, 0.2)';
      context.fillRect(x-fontSize*0.2, y - fontSize + fontSize/10, width+fontSize*0.4, height);
    }
    // text color
    if (settings('labelColor') === 'node') {
      context.fillStyle = (node.color || settings('defaultNodeColor'));
    }
    else {
      context.fillStyle = settings('defaultLabelColor');
    }

    context.fillText( node.label, x, y);

    /* border text ?
    if (settings('labelStrokeStyle') && fontSize > small) {
      context.strokeStyle = settings('labelStrokeStyle');
      context.strokeText(node.label, x, y);
    }
    */
    context.restore();
  };




  window.sigmot = function (id, data, maxNodeSize)
  {
    var asigmot = this;

  
    var canvas = document.getElementById( id );
    this.canvas = canvas;
    //
    var height = canvas.offsetHeight;
    // adjust maxnode size to screen height
    // var scale = Math.max( height, 150) / 700;
    if ( !maxNodeSize ) maxNodeSize = height/40;
    else maxNodeSize = maxNodeSize * scale;
    var width = canvas.offsetWidth;
    
    console.log(maxNodeSize);

    
    var s = new sigma({
      id: id,
      graph: data,
      renderer: {
        container: canvas,
        type: 'canvas'
      },
      settings: {
        // autoRescale: false, // non
        // scalingMode: "outside", // non
        autoResize: false,
        // height: height,
        // width: width,
        // scale : 0.9, // effect of global size on graph objects
        // sideMargin: 1,
        
        defaultNodeColor: "rgba(255, 255, 255, 0.5)",
        defaultEdgeColor: 'rgba(255, 255, 255, 0.6)',
        edgeColor: "default",
        drawLabels: true,
        defaultLabelSize: 10,
        defaultLabelColor: "rgba( 0, 0, 0, 0.8)",
        // labelStrokeStyle: "rgba(255, 255, 255, 0.7)",
        labelThreshold: 0,
        labelSize:"proportional",
        labelSizeRatio: 1.5,
        labelAlignment: 'center', // specific
        labelColor: "node",
        font: ' Tahoma, Geneva, sans-serif', // after fontSize
        fontStyle: ' ', // before fontSize

        minNodeSize: 8,
        maxNodeSize: maxNodeSize,
        minEdgeSize: 0.4,
        maxEdgeSize: maxNodeSize*1.5,

        // minArrowSize: 15,
        // maxArrowSize: 20,
        borderSize: 1,
        outerBorderSize: 3, // stroke size of active nodes
        defaultNodeBorderColor: '#000000',
        defaultNodeOuterBorderColor: 'rgb(236, 81, 72)', // stroke color of active nodes
        drawNodes: false,
        zoomingRatio: 1.1,
        mouseWheelEnabled: false,
        edgeHoverColor: 'edge',
        defaultEdgeHoverColor: '#000000',
        doubleClickEnabled: false, // utilisé pour la suppression
        /*
        enableEdgeHovering: true, // bad for memory
        edgeHoverSizeRatio: 1,
        edgeHoverExtremities: true,
        */
      }
    });
    this.s = s;
    
    sigma.layouts.fruchtermanReingold.configure( s, {
      autoArea: true,
      area: 1,
      gravity: 0.5,
      speed: 0.1,
      iterations: 1000
    });

    s.bind( 'doubleClickNode', function( e ) {
      if (e.data.node.type) e.data.node.type = null;
      else e.data.node.type = "hub";
      e.target.refresh();
    });
    s.bind( 'rightClickNode', function( e ) {
      e.data.renderer.graph.dropNode(e.data.node.id);
      e.target.refresh();
    });

    var workOver, workOut;
    s.bind( "overNode", function( e ) {
      if (workOver ) return;
      workOver = true;
      var center= e.data.node;
      var nodes = e.data;
      var neighbors = {};
	    s.graph.edges().forEach( function(e) {
        if ( e.source != center.id && e.target != center.id ) {
          e.hidden = true;
          return;
        }
        neighbors[e.source] = 1;
        neighbors[e.target] = 1;
	    });
      s.graph.nodes().forEach( function(n) {
	      if( neighbors[n.id] ) {
          n.hidden = 0;
	      } else {
          n.hidden = 1;
	      }
	    });
      s.refresh( );
      workOver = false;
    } ).bind('outNode', function() {
      if (workOut) return;
      workOut = true;
      s.graph.edges().forEach( function(e) {
	      e.hidden = 0;
	    } );
      s.graph.nodes().forEach( function(n) {
	      n.hidden = 0;
	    });
      s.refresh();
      workOut = false;
	  } );

    var els = canvas.getElementsByClassName('FR');
    if (els.length) {
      els[0].onclick = function() {
        asigmot.stopForce();
        sigma.layouts.fruchtermanReingold.start( s );
      }
    }
    var els = canvas.getElementsByClassName('atlas2');
    if (els.length) {
      this.atlas2But = els[0];
      els[0].onclick = function() {
        if (this.innerHTML = '►') asigmot.startForce();
        else asigmot.stopForce();
      };
    }
    var els = canvas.getElementsByClassName('noverlap');
    if (els.length) {
      els[0].onclick = function() {
        s.configNoverlap({
          // gridSize: 100,
        });
        s.startNoverlap();
      };
    }
    var els = canvas.getElementsByClassName('colors');
    if (els.length) {
      els[0].onclick = function() {
        var bw = s.settings( 'bw' );
        if (!bw) {
          this.innerHTML = '🌈';
          s.settings( 'bw', true );
        }
        else {
          this.innerHTML = '◐';
          s.settings( 'bw', false );
        }
        s.refresh();
      };
    }
    var els = canvas.getElementsByClassName('fontup');
    if (els.length) {
      els[0].onclick = function() {
        var ratio = s.settings('labelSizeRatio');
        s.settings('labelSizeRatio', ratio * 1.2);
        s.refresh();
      };
    }
    var els = canvas.getElementsByClassName('fontdown');
    if (els.length) {
      els[0].onclick = function() {
        var ratio = s.settings('labelSizeRatio');
        s.settings('labelSizeRatio', ratio * 0.9);
        s.refresh();
      };
    }
    var els = canvas.getElementsByClassName( 'zoomin' );
    if (els.length) {
      els[0].onclick = function() {
        var c = s.camera; c.goTo({ratio: c.ratio / c.settings('zoomingRatio')});
      };
    }
    var els = canvas.getElementsByClassName( 'zoomout' );
    if (els.length) {
      els[0].onclick = function() {
        var c = s.camera; c.goTo({ratio: c.ratio * c.settings('zoomingRatio')});
      };
    }

    
    
    var els = canvas.getElementsByClassName( 'turnleft' );
    if (els.length) {
      els[0].onclick = function() {
        asigmot.rotate(15);
      };
    }
    var els = canvas.getElementsByClassName( 'turnright' );
    if (els.length) {
      els[0].onclick = function() {
        asigmot.rotate(-22.5);
      };
    }
    

    sigmot.mix = function(e) {
      asigmot.stopForce();
      var nodes = s.graph.nodes();
      for (var i=0, length = nodes.length; i < length; i++) {
        nodes[i].x = Math.random()*width;
        nodes[i].y = Math.random()*height;
      }
      s.refresh();
      return false;
    };

    var els = canvas.getElementsByClassName( 'mix' );
    if (els.length) {
      this.mixBut = els[0];
      this.mixBut.net = this;
      this.mixBut.onclick = sigmot.mix;
    }
    var els = canvas.getElementsByClassName( 'shot' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        asigmot.stopForce();
        s.refresh();
        var size = prompt( "Largeur de l’image (en px)", window.innerWidth );
        sigma.plugins.image(s, s.renderers[0], {
          download: true,
          margin: 0,
          size: size,
          clip: true,
          zoomRatio: 1,
          background: "#000",
          labels: false
        });
      };
    }

    // resizer
    var els = canvas.getElementsByClassName( 'resize' );
    if (els.length) {
      els[0].net = this;
      els[0].onmousedown = function(e) {
        asigmot.stopForce();
        var html = document.documentElement;
        html.sigma = this.net.sigma; // give an handle to the sigma instance
        html.dragO = this.net.canvas;
        html.dragX = e.clientX;
        html.dragY = e.clientY;
        html.dragWidth = parseInt( document.defaultView.getComputedStyle( html.dragO ).width, 10 );
        html.dragHeight = parseInt( document.defaultView.getComputedStyle( html.dragO ).height, 10 );
        html.addEventListener( 'mousemove', function(e){asigmot.doDrag(e)}, false );
        html.addEventListener( 'mouseup', function(e){asigmot.stopDrag(e)}, false );
      };
    }

    // Initialize the dragNodes plugin:
    var dragListener = sigma.plugins.dragNodes(s, s.renderers[0]);
    this.startForce();
  }
    // global static
  sigmot.prototype.doDrag = function(e) {
    this.canvas.style.width = ( this.dragWidth + e.clientX - this.dragX ) + 'px';
    this.canvas.style.height = ( this.dragHeight + e.clientY - this.dragY ) + 'px';
  };

  sigmot.prototype.stopDrag = function(e) {
    var height = this.canvas.offsetHeight;
    var width = this.canvas.offsetWidth;

    this.removeEventListener( 'mousemove', sigmot.doDrag, false );
    this.removeEventListener( 'mouseup', sigmot.stopDrag, false );
    this.s.settings( 'height', height );
    this.s.settings( 'width', width );
    // var scale = Math.max( height, 150) / 500;
    // this.s.settings( 'scale', scale );
    this.s.refresh();
  };

  
  sigmot.prototype.startForce = function() {
    if (this.atlas2But) this.atlas2But.innerHTML = '◼';
    var pars = {
      // cristallin
      // strongGravityMode: true, scalingRatio: 200,
      
      // edgeWeightInfluence: 1, // cristal confus
      // cristallin
      // outboundAttractionDistribution: true,
      // instable si gravity >  2 * scalingRatio
      gravity: 10, 
      scalingRatio: 10, 
      // ??
      
      // linLogMode: true, 
      // adjustSizes: true, // instable sans barnes
      // barnesHutOptimize: true, // avec linlog
      // barnesHutTheta: 0.3,  // pas trop petit
      // scalingRatio: 0.3, // pour adjustSizes ?
      
      // startingIterations : 100,
      // slowDown: 1, // NON
      worker: true, // OUI !
      iterationsPerRender : 100, // important
    };
    this.s.startForceAtlas2(pars);
    var myO = this;
    setTimeout(function(){myO.stopForce()}, 3000)
  };
  sigmot.prototype.stopForce = function() {
    this.s.killForceAtlas2();
    if (this.atlas2But) this.atlas2But.innerHTML = '►';
  };
  sigmot.prototype.rotate = function(degrees) {
    this.stopForce();
    var xmin = Infinity,
      xmax = -Infinity,
      ymin = Infinity,
      ymax = -Infinity,
      radians = (Math.PI / 180) * degrees,
      cos = Math.cos(radians),
      sin = Math.sin(radians),
      nodes = this.s.graph.nodes();
    
    for (var i=0, length = nodes.length; i < length; i++) {
      var n = nodes[i];
      xmin = Math.min(xmin, n.x );
      xmax = Math.max(xmax, n.x );
      ymin = Math.min(ymin, n.y );
      ymax = Math.max(ymax, n.y );
    }
    var cx = xmin + (xmax - xmin)/2,
      cy = ymin + (ymax - ymin)/2;
    for (var i=0, length = nodes.length; i < length; i++) {
      var n = nodes[i];
      var nx = (cos * (n.x - cx)) + (sin * (n.y - cy)) + cx;
      var ny = (cos * (n.y - cy)) - (sin * (n.x - cx)) + cy;
      n.x = nx;
      n.y = ny
    }
    this.s.refresh();
  }


})();
