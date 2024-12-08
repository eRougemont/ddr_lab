;
(function(undefined) {
    'use strict';


    sigma.utils.pkg('sigma.canvas.labels');

    /**
     * This label renderer will just display the label on the center of the node.
     *
     * @param  {object}                   node     The node object.
     * @param  {CanvasRenderingContext2D} ctx  The canvas context.
     * @param  {configurable}             settings The settings function.
     */
    sigma.canvas.labels.def = function(node, ctx, settings) {
        var fontSize,
            prefix = settings('prefix') || '',
            labelWidth = 0,
            labelPlacementX,
            labelPlacementY,
            alignment,
            size = node[prefix + 'size'];

        if (size < settings('labelThreshold'))
            return;

        if (!node.label || typeof node.label !== 'string')
            return;

        if (settings('labelAlignment') === undefined) {
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


        ctx.font = (settings('fontStyle') ? settings('fontStyle') + ' ' : '') +
            fontSize + 'px ' + settings('font');

        var textMetrics = ctx.measureText(node.label);
        var labelWidth = textMetrics.width;
        var labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
        var labelPlacementY = Math.round(node[prefix + 'y'] + fontSize / 3);

        switch (alignment) {
            case 'inside':
                if (labelWidth <= size * 2) {
                    labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2);
                }
                break;
            case 'center':
                labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2);
                break;
            case 'left':
                labelPlacementX = Math.round(node[prefix + 'x'] - size - labelWidth - 3);
                break;
            case 'right':
                labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
                break;
            case 'top':
                labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2);
                labelPlacementY = labelPlacementY - size - fontSize;
                break;
            case 'bottom':
                labelPlacementX = Math.round(node[prefix + 'x'] - labelWidth / 2);
                labelPlacementY = labelPlacementY + size + fontSize;
                break;
            default:
                // Default is aligned 'right'
                labelPlacementX = Math.round(node[prefix + 'x'] + size + 3);
                break;
        }
        var color = (settings('labelColor') === 'node') ? (node.color || settings('defaultNodeColor')) : settings('defaultLabelColor');
        ctx.globalAlpha = 1;
        // Node border:
        if (node.type == 'hub') {
            ctx.strokeStyle = color;
            ctx.lineWidth = 0.5 + 0.05 * fontSize;
            var padx = -4 - fontSize / 5;
            var pady = 5 + fontSize / 10;
            var x = labelPlacementX - padx;
            var y = labelPlacementY - pady - textMetrics.actualBoundingBoxAscent; // - textMetrics.actualBoundingBoxDescent;
            var w = labelWidth + 2 * padx;
            var h = Math.round(textMetrics.actualBoundingBoxAscent + textMetrics.actualBoundingBoxDescent + 2 * pady);
            var e = Math.round(h / 2);
            // ctx.globalAlpha = 0.3;
            ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
            ctx.shadowColor = "#fff";
            ctx.lineWidth = 2 + fontSize / 10;
            ctx.strokeStyle = 'rgba(255, 255, 255, 0.3)';
            ctx.beginPath();
            ctx.moveTo(x, y);
            // ctx.arcTo(x, y, x + e, y, e);
            ctx.lineTo(x + w, y);
            ctx.quadraticCurveTo(x + w + e, y, x + w + e, y + e);
            ctx.quadraticCurveTo(x + w + e, y + h, x + w, y + h);

            ctx.lineTo(x, y + h);
            ctx.quadraticCurveTo(x - e, y + h, x - e, y + e);
            ctx.quadraticCurveTo(x - e, y, x, y);

            ctx.closePath();
            // ctx.fill();
            ctx.stroke();
            ctx.shadowBlur = 0;
        }
        /* too much time
        ctx.shadowColor="#fff";
        ctx.shadowBlur=1;
        */
        /* stroke, bof
        ctx.globalAlpha = 1;
        ctx.lineWidth=0.5;
        ctx.strokeStyle = (settings('labelColor') === 'node') ?
          (node.color || settings('defaultNodeColor')) :
          settings('defaultLabelColor');
        ctx.strokeText(
          node.label,
          labelPlacementX,
          labelPlacementY
        );
        ctx.globalAlpha = 0.6;
        */

        ctx.fillStyle = color;
        ctx.fillText(
            node.label,
            labelPlacementX,
            labelPlacementY
        );


    };

    /**
     * Override the node over for centered labels
     *
     * @param  {object}                   node     The node object.
     * @param  {CanvasRenderingContext2D} ctx  The canvas context.
     * @param  {configurable}             settings The settings function.
     */
    sigma.canvas.hovers.def = function(node, ctx, settings) {
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
        ctx.font = (fontStyle ? fontStyle + ' ' : '') +
            fontSize + 'px ' + (settings('hoverFont') || settings('font'));

        ctx.beginPath();
        ctx.fillStyle = settings('labelHoverBGColor') === 'node' ?
            (node.color || settings('defaultNodeColor')) :
            settings('defaultHoverLabelBGColor');

        if (node.label && settings('labelHoverShadow')) {
            ctx.shadowOffsetX = 0;
            ctx.shadowOffsetY = 0;
            ctx.shadowBlur = 8;
            ctx.shadowColor = settings('labelHoverShadowColor');
        }

        /*
        if (node.label && typeof node.label === 'string') {
          x = Math.round(node[prefix + 'x'] - fontSize / 2 - 2);
          y = Math.round(node[prefix + 'y'] - fontSize / 2 - 2);
          w = Math.round(
            ctx.measureText(node.label).width + fontSize / 2 + size + 7
          );
          h = Math.round(fontSize + 4);
          e = Math.round(fontSize / 2 + 2);

          ctx.moveTo(x, y + e);
          ctx.arcTo(x, y, x + e, y, e);
          ctx.lineTo(x + w, y);
          ctx.lineTo(x + w, y + h);
          ctx.lineTo(x + e, y + h);
          ctx.arcTo(x, y + h, x, y + h - e, e);
          ctx.lineTo(x, y + e);

          ctx.closePath();
          ctx.fill();

          ctx.shadowOffsetX = 0;
          ctx.shadowOffsetY = 0;
          ctx.shadowBlur = 0;
        }
        */

        /*
        // Node border:
        if (settings('borderSize') > 0) {
          ctx.beginPath();
          ctx.fillStyle = settings('nodeBorderColor') === 'node' ?
            (node.color || settings('defaultNodeColor')) :
            settings('defaultNodeBorderColor');
          ctx.arc(
            node[prefix + 'x'],
            node[prefix + 'y'],
            size + settings('borderSize'),
            0,
            Math.PI * 2,
            true
          );
          ctx.closePath();
          ctx.fill();
        }
        */

        // Node:
        var nodeRenderer = sigma.canvas.nodes[node.type] || sigma.canvas.nodes.def;
        // nodeRenderer(node, ctx, settings);

        /*
        // Display the label:
        if (node.label && typeof node.label === 'string') {
          ctx.fillStyle = (settings('labelHoverColor') === 'node') ?
            (node.color || settings('defaultNodeColor')) :
            settings('defaultLabelHoverColor');

          ctx.fillText(
            node.label,
            Math.round(node[prefix + 'x'] + size + 3),
            Math.round(node[prefix + 'y'] + fontSize / 3)
          );
        }
        */
    };

    window.Sigmot = function() {};
    /**
     * A sigma instance
     * @param {*} sig 
     */
    Sigmot.buts = function(mysig) {
        var el = document.querySelector('.but.mix');
        if (el) {
            el.onclick = mysig.mix;
        }
        var el = document.querySelector('.but.FR');
        if (el) {
            el.onclick = function() {
                mysig.stopForce();
                sigma.layouts.fruchtermanReingold.start(mysig);
            }
        }
        var el = document.querySelector('.but.atlas2');
        if (el) {
            mysig.forceBut = el;
            el.onclick = function() {

                // if (this.atlas2But) this.atlas2But.innerHTML = '◼';

                if (mysig.forceBut.innerHTML = '►') {
                    mysig.startForce();
                } else {
                    mysig.stopForce();
                }
            };
        }
        var el = document.querySelector('.but.noverlap');
        if (el) {
            el.onclick = function() {
                mysig.configNoverlap({
                    // row: 10,
                });
                mysig.startNoverlap();
            };
        }
        var el = document.querySelector('.but.colors');
        if (el) {
            el.onclick = function() {
                var bw = mysig.settings('bw');
                if (!bw) {
                    this.innerHTML = '🌈';
                    mysig.settings('bw', true);
                } else {
                    this.innerHTML = '◐';
                    mysig.settings('bw', false);
                }
                mysig.refresh();
            };
        }
        var el = document.querySelector('.but.fontup');
        if (el) {
            el.onclick = function() {
                var ratio = mysig.settings('labelSizeRatio');
                mysig.settings('labelSizeRatio', ratio * 1.2);
                mysig.refresh();
            };
        }
        var el = document.querySelector('.but.fontdown');
        if (el) {
            el.onclick = function() {
                var ratio = mysig.settings('labelSizeRatio');
                mysig.settings('labelSizeRatio', ratio * 0.9);
                mysig.refresh();
            };
        }
        var el = document.querySelector('.but.zoomin');
        if (el) {
            el.onclick = function() {
                var c = mysig.camera;
                c.goTo({ ratio: c.ratio / c.settings('zoomingRatio') });
            };
        }
        var el = document.querySelector('.but.zoomout');
        if (el) {
            el.onclick = function() {
                var c = mysig.camera;
                c.goTo({ ratio: c.ratio * c.settings('zoomingRatio') });
            };
        }

        var el = document.querySelector('.but.shot');
        if (el) {
            el.net = this;
            el.onclick = function() {
                mysig.stopForce();
                mysig.refresh();
                var size = prompt("Largeur de l’image (en px)", window.innerWidth);
                sigma.plugins.image(mysig, mysig.renderers[0], {
                    download: true,
                    margin: 0,
                    size: size,
                    clip: true,
                    zoomRatio: 1,
                    background: "#4c555d",
                    labels: false
                });
            };
        }
        var el = document.querySelector('.but.turnleft');
        if (el) {
            el.onclick = function() {
                mysig.rotate(15);
            };
        }
        var el = document.querySelector('.but.turnright');
        if (el) {
            el.onclick = function() {
                mysig.rotate(-22.5);
            };
        }

        /*
        // resizer
        var el = document.querySelector('.but.resize');
        if (el) {
            el.net = this;
            el.onmousedown = function(e) {
                mysig.stopForce();
                var html = document.documentElement;
                html.sigma = this.net.sigma; // give an handle to the sigma instance
                html.dragO = this.net.zediv;
                html.dragX = e.clientX;
                html.dragY = e.clientY;
                html.dragWidth = parseInt(document.defaultView.getComputedStyle(html.dragO).width, 10);
                html.dragHeight = parseInt(document.defaultView.getComputedStyle(html.dragO).height, 10);
            };
        }
        */


    };


    /**
     * Get a sigma instance with lots of things
     * @param {String} id 
     * @param {*} maxNodeSize 
     */
    Sigmot.sigma = function(id, maxNodeSize) {
        const div = document.getElementById(id);
        if (!div) {
            console.log("[Sigmot] graphe not found id=" + id);
            // graph not found, let it go ?
            return null;
        }
        var height = div.offsetHeight;
        // adjust maxnode size to screen height
        // var scale = Math.max( height, 150) / 700;
        if (!maxNodeSize) maxNodeSize = height / 20;
        else maxNodeSize = maxNodeSize * scale;
        var width = div.offsetWidth;
        // attach sigma instance to the div
        const settings = {
            // autoRescale: false, // non
            // scalingMode: "outside", // non
            autoResize: false,
            // height: height,
            // width: width,
            // scale : 0.9, // effect of global size on graph objects
            // sideMargin: 1,

            defaultNodeColor: "rgba(0, 255, 0, 0.5)",
            defaultEdgeColor: 'rgba(245, 245, 245, 0.6)',
            edgeColor: "default",
            drawLabels: true,
            defaultLabelSize: 15,
            defaultLabelColor: "rgba( 0, 0, 0, 0.8)",
            // labelStrokeStyle: "rgba(255, 255, 255, 0.7)",
            labelThreshold: 0,
            labelSize: "proportional",
            labelSizeRatio: 1.5,
            labelAlignment: 'center', // specific
            labelColor: "node",
            font: '"Fira Sans", "Open Sans", "Roboto", sans-serif', // after fontSize
            fontStyle: 'bold', // before fontSize

            minNodeSize: 8,
            maxNodeSize: maxNodeSize,
            minEdgeSize: 0.4,
            maxEdgeSize: maxNodeSize * 1.5,

            // minArrowSize: 15,
            // maxArrowSize: 20,
            borderSize: 1,
            outerBorderSize: 3, // stroke size of active nodes
            defaultNodeBorderColor: '#000000',
            defaultNodeOuterBorderColor: 'rgb(236, 81, 72)', // stroke color of active nodes
            drawNodes: false,
            // zoomingRatio: 1.1,
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

        const mysig = new sigma({
            id: id,
            renderer: {
                container: div,
                type: 'canvas'
            },
            settings: settings,
        });
        // global conf
        sigma.layouts.fruchtermanReingold.configure(mysig, {
            autoArea: true,
            area: 1,
            gravity: 0.5,
            speed: 0.1,
            iterations: 1000
        });

        mysig.bind('doubleClickNode', function(e) {
            if (e.data.node.type) e.data.node.type = null;
            else e.data.node.type = "hub";
            e.target.refresh();
        });
        mysig.bind('rightClickNode', function(e) {
            e.data.renderer.graph.dropNode(e.data.node.id);
            e.target.refresh();
        });
        var workOver, workOut;
        mysig.bind("overNode", function(e) {
            if (workOver) return;
            workOver = true;
            var center = e.data.node;
            var nodes = e.data;
            var neighbors = {};
            mysig.graph.edges().forEach(function(e) {
                if (e.source != center.id && e.target != center.id) {
                    e.hidden = true;
                    return;
                }
                neighbors[e.source] = 1;
                neighbors[e.target] = 1;
            });
            mysig.graph.nodes().forEach(function(n) {
                if (neighbors[n.id]) {
                    n.hidden = 0;
                } else {
                    n.hidden = 1;
                }
            });
            mysig.refresh();
            workOver = false;
        }).bind('outNode', function() {
            if (workOut) return;
            workOut = true;
            mysig.graph.edges().forEach(function(e) {
                e.hidden = 0;
            });
            mysig.graph.nodes().forEach(function(n) {
                n.hidden = 0;
            });
            mysig.refresh();
            workOut = false;
        });
        mysig.startForce = function(e) {
            var pars = {
                // cristallin
                // strongGravityMode: true, scalingRatio: 200,

                // edgeWeightInfluence: 0.1, // cristal confus
                // outboundAttractionDistribution: true, // cristallin
                // instable si gravity >  2 * scalingRatio

                // /* correct
                // gravity: 10, // corrélation inverse au scaling
                scalingRatio: 0.4,
                startingIterations: 500,
                slowDown: 5, // éviter de trop bouger
                // iterationsPerRender : 100, // en fait non
                // */

                /*
                linLogMode: true,
                iterationsPerRender : 100,
                adjustSizes: true, // instable sans barnes
                barnesHutOptimize: true, // avec linlog
                barnesHutTheta: 0.3,  // pas trop petit
                // scalingRatio: 10, // pour adjustSizes ?
                // */
                worker: true, // OUI !
            };
            mysig.startForceAtlas2(pars);
            if (mysig.forceBut) mysig.forceBut.innerHTML = '▮';
            setTimeout(function() { mysig.stopForce() }, 3000);
        };
        mysig.stopForce = function() {
            mysig.killForceAtlas2();
            if (mysig.forceBut) mysig.forceBut.innerHTML = '►';
        };
        mysig.mix = function(e) {
            mysig.stopForce();
            const nodes = mysig.graph.nodes();
            for (var i = 0, length = nodes.length; i < length; i++) {
                nodes[i].x = Math.random() * width;
                nodes[i].y = Math.random() * height;
            }
            mysig.refresh();
            return false;
        };
        mysig.rotate = function(degrees) {
            mysig.stopForce();
            var xmin = Infinity,
                xmax = -Infinity,
                ymin = Infinity,
                ymax = -Infinity,
                radians = (Math.PI / 180) * degrees,
                cos = Math.cos(radians),
                sin = Math.sin(radians),
                nodes = mysig.graph.nodes();

            for (var i = 0, length = nodes.length; i < length; i++) {
                var n = nodes[i];
                xmin = Math.min(xmin, n.x);
                xmax = Math.max(xmax, n.x);
                ymin = Math.min(ymin, n.y);
                ymax = Math.max(ymax, n.y);
            }
            var cx = xmin + (xmax - xmin) / 2,
                cy = ymin + (ymax - ymin) / 2;
            for (var i = 0, length = nodes.length; i < length; i++) {
                var n = nodes[i];
                var nx = (cos * (n.x - cx)) + (sin * (n.y - cy)) + cx;
                var ny = (cos * (n.y - cy)) - (sin * (n.x - cx)) + cy;
                n.x = nx;
                n.y = ny
            }
            mysig.refresh();
        };
        // Initialize the dragNodes plugin:
        var dragListener = sigma.plugins.dragNodes(mysig, mysig.renderers[0]);

        Sigmot.buts(mysig);
        return mysig;
    }


    /*
        }
        // global static
    sigmot.prototype.doDrag = function(e) {
        this.zediv.style.width = (this.dragWidth + e.clientX - this.dragX) + 'px';
        this.zediv.style.height = (this.dragHeight + e.clientY - this.dragY) + 'px';
    };

    sigmot.prototype.stopDrag = function(e) {
        var height = this.zediv.offsetHeight;
        var width = this.zediv.offsetWidth;

        this.removeEventListener('mousemove', sigmot.doDrag, false);
        this.removeEventListener('mouseup', sigmot.stopDrag, false);
        this.s.settings('height', height);
        this.s.settings('width', width);
        // var scale = Math.max( height, 150) / 500;
        // this.s.settings( 'scale', scale );
        this.s.refresh();
    };
    */





})();