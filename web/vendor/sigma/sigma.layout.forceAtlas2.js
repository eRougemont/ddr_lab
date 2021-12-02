;(function(undefined) {
  'use strict';

  if (typeof sigma === 'undefined')
    throw 'sigma is not declared';

  /**
   * Sigma ForceAtlas2.5 Supervisor
   * ===============================
   *
   * Author: Guillaume Plique (Yomguithereal)
   * Version: 0.1
   */
  var _root = this;

  /**
   * Feature detection
   * ------------------
   */
  var webWorkers = 'Worker' in _root;

  /**
   * Supervisor Object
   * ------------------
   */
  function Supervisor(sigInst, options) {
    var _this = this,
        workerFn = sigInst.getForceAtlas2Worker &&
          sigInst.getForceAtlas2Worker();

    options = options || {};

    // _root URL Polyfill
    _root.URL = _root.URL || _root.webkitURL;

    // Properties
    this.sigInst = sigInst;
    this.graph = this.sigInst.graph;
    this.ppn = 10;
    this.ppe = 3;
    this.config = {};
    this.shouldUseWorker =
      options.worker === false ? false : true && webWorkers;
    this.workerUrl = options.workerUrl;

    // State
    this.started = false;
    this.running = false;

    // Web worker or classic DOM events?
    if (this.shouldUseWorker) {
      if (!this.workerUrl) {
        var blob = this.makeBlob(workerFn);
        this.worker = new Worker(URL.createObjectURL(blob));
      }
      else {
        this.worker = new Worker(this.workerUrl);
      }

      // Post Message Polyfill
      this.worker.postMessage =
        this.worker.webkitPostMessage || this.worker.postMessage;
    }
    else {

      eval(workerFn);
    }

    // Worker message receiver
    this.msgName = (this.worker) ? 'message' : 'newCoords';
    this.listener = function(e) {

      // Retrieving data
      _this.nodesByteArray = new Float32Array(e.data.nodes);

      // If ForceAtlas2 is running, we act accordingly
      if (_this.running) {

        // Applying layout
        _this.applyLayoutChanges();

        // Send data back to worker and loop
        _this.sendByteArrayToWorker();

        // Rendering graph
        _this.sigInst.refresh();
      }
    };

    (this.worker || document).addEventListener(this.msgName, this.listener);

    // Filling byteArrays
    this.graphToByteArrays();

    // Binding on kill to properly terminate layout when parent is killed
    sigInst.bind('kill', function() {
      sigInst.killForceAtlas2();
    });
  }

  Supervisor.prototype.makeBlob = function(workerFn) {
    var blob;

    try {
      blob = new Blob([workerFn], {type: 'application/javascript'});
    }
    catch (e) {
      _root.BlobBuilder = _root.BlobBuilder ||
                          _root.WebKitBlobBuilder ||
                          _root.MozBlobBuilder;

      blob = new BlobBuilder();
      blob.append(workerFn);
      blob = blob.getBlob();
    }

    return blob;
  };

  Supervisor.prototype.graphToByteArrays = function() {
    var nodes = this.graph.nodes(),
        edges = this.graph.edges(),
        nbytes = nodes.length * this.ppn,
        ebytes = edges.length * this.ppe,
        nIndex = {},
        i,
        j,
        l;

    // Allocating Byte arrays with correct nb of bytes
    this.nodesByteArray = new Float32Array(nbytes);
    this.edgesByteArray = new Float32Array(ebytes);

    // Iterate through nodes
    for (i = j = 0, l = nodes.length; i < l; i++) {

      // Populating index
      nIndex[nodes[i].id] = j;

      // Populating byte array
      this.nodesByteArray[j] = nodes[i].x;
      this.nodesByteArray[j + 1] = nodes[i].y;
      this.nodesByteArray[j + 2] = 0;
      this.nodesByteArray[j + 3] = 0;
      this.nodesByteArray[j + 4] = 0;
      this.nodesByteArray[j + 5] = 0;
      this.nodesByteArray[j + 6] = 1 + this.graph.degree(nodes[i].id);
      this.nodesByteArray[j + 7] = 1;
      this.nodesByteArray[j + 8] = nodes[i].size;
      this.nodesByteArray[j + 9] = 0;
      j += this.ppn;
    }

    // Iterate through edges
    for (i = j = 0, l = edges.length; i < l; i++) {
      this.edgesByteArray[j] = nIndex[edges[i].source];
      this.edgesByteArray[j + 1] = nIndex[edges[i].target];
      this.edgesByteArray[j + 2] = edges[i].weight || 0;
      j += this.ppe;
    }
  };

  // TODO: make a better send function
  Supervisor.prototype.applyLayoutChanges = function() {
    var nodes = this.graph.nodes(),
        j = 0,
        realIndex;

    // Moving nodes
    for (var i = 0, l = this.nodesByteArray.length; i < l; i += this.ppn) {
      nodes[j].x = this.nodesByteArray[i];
      nodes[j].y = this.nodesByteArray[i + 1];
      j++;
    }
  };

  Supervisor.prototype.sendByteArrayToWorker = function(action) {
    var content = {
      action: action || 'loop',
      nodes: this.nodesByteArray.buffer
    };

    var buffers = [this.nodesByteArray.buffer];

    if (action === 'start') {
      content.config = this.config || {};
      content.edges = this.edgesByteArray.buffer;
      buffers.push(this.edgesByteArray.buffer);
    }

    if (this.shouldUseWorker)
      this.worker.postMessage(content, buffers);
    else
      _root.postMessage(content, '*');
  };

  Supervisor.prototype.start = function() {
    if (this.running)
      return;

    this.running = true;

    // Do not refresh edgequadtree during layout:
    var k,
        c;
    for (k in this.sigInst.cameras) {
      c = this.sigInst.cameras[k];
      c.edgequadtree._enabled = false;
    }

    if (!this.started) {

      // Sending init message to worker
      this.sendByteArrayToWorker('start');
      this.started = true;
    }
    else {
      this.sendByteArrayToWorker();
    }
  };

  Supervisor.prototype.stop = function() {
    if (!this.running)
      return;

    // Allow to refresh edgequadtree:
    var k,
        c,
        bounds;
    for (k in this.sigInst.cameras) {
      c = this.sigInst.cameras[k];
      c.edgequadtree._enabled = true;

      // Find graph boundaries:
      bounds = sigma.utils.getBoundaries(
        this.graph,
        c.readPrefix
      );

      // Refresh edgequadtree:
      if (c.settings('drawEdges') && c.settings('enableEdgeHovering'))
        c.edgequadtree.index(this.sigInst.graph, {
          prefix: c.readPrefix,
          bounds: {
            x: bounds.minX,
            y: bounds.minY,
            width: bounds.maxX - bounds.minX,
            height: bounds.maxY - bounds.minY
          }
        });
    }

    this.running = false;
  };

  Supervisor.prototype.killWorker = function() {
    if (this.worker) {
      this.worker.terminate();
    }
    else {
      _root.postMessage({action: 'kill'}, '*');
      document.removeEventListener(this.msgName, this.listener);
    }
  };

  Supervisor.prototype.configure = function(config) {

    // Setting configuration
    this.config = config;

    if (!this.started)
      return;

    var data = {action: 'config', config: this.config};

    if (this.shouldUseWorker)
      this.worker.postMessage(data);
    else
      _root.postMessage(data, '*');
  };

  /**
   * Interface
   * ----------
   */
  sigma.prototype.startForceAtlas2 = function(config) {

    // Create supervisor if undefined
    if (!this.supervisor)
      this.supervisor = new Supervisor(this, config);

    // Configuration provided?
    if (config)
      this.supervisor.configure(config);

    // Start algorithm
    this.supervisor.start();

    return this;
  };

  sigma.prototype.stopForceAtlas2 = function() {
    if (!this.supervisor)
      return this;

    // Pause algorithm
    this.supervisor.stop();

    return this;
  };

  sigma.prototype.killForceAtlas2 = function() {
    if (!this.supervisor)
      return this;

    // Stop Algorithm
    this.supervisor.stop();

    // Kill Worker
    this.supervisor.killWorker();

    // Kill supervisor
    this.supervisor = null;

    return this;
  };

  sigma.prototype.configForceAtlas2 = function(config) {
    if (!this.supervisor)
      this.supervisor = new Supervisor(this, config);

    this.supervisor.configure(config);

    return this;
  };

  sigma.prototype.isForceAtlas2Running = function(config) {
    return !!this.supervisor && this.supervisor.running;
  };
}).call(this);

;(function(undefined) {
  'use strict';

  /**
   * Sigma ForceAtlas2.5 Webworker
   * ==============================
   *
   * Author: Guillaume Plique (Yomguithereal)
   * Algorithm author: Mathieu Jacomy @ Sciences Po Medialab & WebAtlas
   * Version: 1.0.3
   */

  var _root = this,
      inWebWorker = !('document' in _root);

  /**
   * Worker Function Wrapper
   * ------------------------
   *
   * The worker has to be wrapped into a single stringified function
   * to be passed afterwards as a BLOB object to the supervisor.
   */
  var Worker = function(undefined) {
    'use strict';

    /**
     * Worker settings and properties
     */
    var W = {

      // Properties
      ppn: 10,
      ppe: 3,
      ppr: 9,
      maxForce: 10,
      iterations: 0,
      converged: false,

      // Possible to change through config
      settings: {
        linLogMode: false,
        outboundAttractionDistribution: false,
        adjustSizes: false,
        edgeWeightInfluence: 0,
        scalingRatio: 1,
        strongGravityMode: false,
        gravity: 1,
        slowDown: 1,
        barnesHutOptimize: false,
        barnesHutTheta: 0.5,
        startingIterations: 1,
        iterationsPerRender: 1
      }
    };

    var NodeMatrix,
        EdgeMatrix,
        RegionMatrix;

    /**
     * Helpers
     */
    function extend() {
      var i,
          k,
          res = {},
          l = arguments.length;

      for (i = l - 1; i >= 0; i--)
        for (k in arguments[i])
          res[k] = arguments[i][k];
      return res;
    }

    function __emptyObject(obj) {
      var k;

      for (k in obj)
        if (!('hasOwnProperty' in obj) || obj.hasOwnProperty(k))
          delete obj[k];

      return obj;
    }

    /**
     * Matrices properties accessors
     */
    var nodeProperties = {
      x: 0,
      y: 1,
      dx: 2,
      dy: 3,
      old_dx: 4,
      old_dy: 5,
      mass: 6,
      convergence: 7,
      size: 8,
      fixed: 9
    };

    var edgeProperties = {
      source: 0,
      target: 1,
      weight: 2
    };

    var regionProperties = {
      node: 0,
      centerX: 1,
      centerY: 2,
      size: 3,
      nextSibling: 4,
      firstChild: 5,
      mass: 6,
      massCenterX: 7,
      massCenterY: 8
    };

    function np(i, p) {

      // DEBUG: safeguards
      if ((i % W.ppn) !== 0)
        throw 'np: non correct (' + i + ').';
      if (i !== parseInt(i))
        throw 'np: non int.';

      if (p in nodeProperties)
        return i + nodeProperties[p];
      else
        throw 'ForceAtlas2.Worker - ' +
              'Inexistant node property given (' + p + ').';
    }

    function ep(i, p) {

      // DEBUG: safeguards
      if ((i % W.ppe) !== 0)
        throw 'ep: non correct (' + i + ').';
      if (i !== parseInt(i))
        throw 'ep: non int.';

      if (p in edgeProperties)
        return i + edgeProperties[p];
      else
        throw 'ForceAtlas2.Worker - ' +
              'Inexistant edge property given (' + p + ').';
    }

    function rp(i, p) {

      // DEBUG: safeguards
      if ((i % W.ppr) !== 0)
        throw 'rp: non correct (' + i + ').';
      if (i !== parseInt(i))
        throw 'rp: non int.';

      if (p in regionProperties)
        return i + regionProperties[p];
      else
        throw 'ForceAtlas2.Worker - ' +
              'Inexistant region property given (' + p + ').';
    }

    // DEBUG
    function nan(v) {
      if (isNaN(v))
        throw 'NaN alert!';
    }


    /**
     * Algorithm initialization
     */

    function init(nodes, edges, config) {
      config = config || {};
      var i, l;

      // Matrices
      NodeMatrix = nodes;
      EdgeMatrix = edges;

      // Length
      W.nodesLength = NodeMatrix.length;
      W.edgesLength = EdgeMatrix.length;

      // Merging configuration
      configure(config);
    }

    function configure(o) {
      W.settings = extend(o, W.settings);
    }

    /**
     * Algorithm pass
     */

    // MATH: get distances stuff and power 2 issues
    function pass() {
      var a, i, j, l, r, n, n1, n2, e, w, g, k, m;

      var outboundAttCompensation,
          coefficient,
          xDist,
          yDist,
          ewc,
          mass,
          distance,
          size,
          factor;

      // 1) Initializing layout data
      //-----------------------------

      // Resetting positions & computing max values
      for (n = 0; n < W.nodesLength; n += W.ppn) {
        NodeMatrix[n + 4] = NodeMatrix[n + 2];
        NodeMatrix[n + 5] = NodeMatrix[n + 3];
        NodeMatrix[n + 2] = 0;
        NodeMatrix[n + 3] = 0;
      }

      // If outbound attraction distribution, compensate
      if (W.settings.outboundAttractionDistribution) {
        outboundAttCompensation = 0;
        for (n = 0; n < W.nodesLength; n += W.ppn) {
          outboundAttCompensation += NodeMatrix[n + 6];
        }

        outboundAttCompensation /= W.nodesLength;
      }


      // 1.bis) Barnes-Hut computation
      //------------------------------

      if (W.settings.barnesHutOptimize) {

        var minX = Infinity,
            maxX = -Infinity,
            minY = Infinity,
            maxY = -Infinity,
            q, q0, q1, q2, q3;

        // Setting up
        // RegionMatrix = new Float32Array(W.nodesLength / W.ppn * 4 * W.ppr);
        RegionMatrix = [];

        // Computing min and max values
        for (n = 0; n < W.nodesLength; n += W.ppn) {
          minX = Math.min(minX, NodeMatrix[n]);
          maxX = Math.max(maxX, NodeMatrix[n]);
          minY = Math.min(minY, NodeMatrix[n + 1]);
          maxY = Math.max(maxY, NodeMatrix[n + 1]);
        }

        // Build the Barnes Hut root region
        RegionMatrix[0] = -1;
        RegionMatrix[0 + 1] = (minX + maxX) / 2;
        RegionMatrix[0 + 2] = (minY + maxY) / 2;
        RegionMatrix[0 + 3] = Math.max(maxX - minX, maxY - minY);
        RegionMatrix[0 + 4] = -1;
        RegionMatrix[0 + 5] = -1;
        RegionMatrix[0 + 6] = 0;
        RegionMatrix[0 + 7] = 0;
        RegionMatrix[0 + 8] = 0;

        // Add each node in the tree
        l = 1;
        for (n = 0; n < W.nodesLength; n += W.ppn) {

          // Current region, starting with root
          r = 0;

          while (true) {
            // Are there sub-regions?

            // We look at first child index
            if (RegionMatrix[r + 5] >= 0) {

              // There are sub-regions

              // We just iterate to find a "leave" of the tree
              // that is an empty region or a region with a single node
              // (see next case)

              // Find the quadrant of n
              if (NodeMatrix[n] < RegionMatrix[r + 1]) {

                if (NodeMatrix[n + 1] < RegionMatrix[r + 2]) {

                  // Top Left quarter
                  q = RegionMatrix[r + 5];
                }
                else {

                  // Bottom Left quarter
                  q = RegionMatrix[r + 5] + W.ppr;
                }
              }
              else {
                if (NodeMatrix[n + 1] < RegionMatrix[r + 2]) {

                  // Top Right quarter
                  q = RegionMatrix[r + 5] + W.ppr * 2;
                }
                else {

                  // Bottom Right quarter
                  q = RegionMatrix[r + 5] + W.ppr * 3;
                }
              }

              // Update center of mass and mass (we only do it for non-leave regions)
              RegionMatrix[r + 7] =
                (RegionMatrix[r + 7] * RegionMatrix[r + 6] +
                 NodeMatrix[n] * NodeMatrix[n + 6]) /
                (RegionMatrix[r + 6] + NodeMatrix[n + 6]);

              RegionMatrix[r + 8] =
                (RegionMatrix[r + 8] * RegionMatrix[r + 6] +
                 NodeMatrix[n + 1] * NodeMatrix[n + 6]) /
                (RegionMatrix[r + 6] + NodeMatrix[n + 6]);

              RegionMatrix[r + 6] += NodeMatrix[n + 6];

              // Iterate on the right quadrant
              r = q;
              continue;
            }
            else {

              // There are no sub-regions: we are in a "leave"

              // Is there a node in this leave?
              if (RegionMatrix[r] < 0) {

                // There is no node in region:
                // we record node n and go on
                RegionMatrix[r] = n;
                break;
              }
              else {

                // There is a node in this region

                // We will need to create sub-regions, stick the two
                // nodes (the old one r[0] and the new one n) in two
                // subregions. If they fall in the same quadrant,
                // we will iterate.

                // Create sub-regions
                RegionMatrix[r + 5] = l * W.ppr;
                w = RegionMatrix[r + 3] / 2;  // new size (half)

                // NOTE: we use screen coordinates
                // from Top Left to Bottom Right

                // Top Left sub-region
                g = RegionMatrix[r + 5];

                RegionMatrix[g] = -1;
                RegionMatrix[g + 1] = RegionMatrix[r + 1] - w;
                RegionMatrix[g + 2] = RegionMatrix[r + 2] - w;
                RegionMatrix[g + 3] = w;
                RegionMatrix[g + 4] = g + W.ppr;
                RegionMatrix[g + 5] = -1;
                RegionMatrix[g + 6] = 0;
                RegionMatrix[g + 7] = 0;
                RegionMatrix[g + 8] = 0;

                // Bottom Left sub-region
                g += W.ppr;
                RegionMatrix[g] = -1;
                RegionMatrix[g + 1] = RegionMatrix[r + 1] - w;
                RegionMatrix[g + 2] = RegionMatrix[r + 2] + w;
                RegionMatrix[g + 3] = w;
                RegionMatrix[g + 4] = g + W.ppr;
                RegionMatrix[g + 5] = -1;
                RegionMatrix[g + 6] = 0;
                RegionMatrix[g + 7] = 0;
                RegionMatrix[g + 8] = 0;

                // Top Right sub-region
                g += W.ppr;
                RegionMatrix[g] = -1;
                RegionMatrix[g + 1] = RegionMatrix[r + 1] + w;
                RegionMatrix[g + 2] = RegionMatrix[r + 2] - w;
                RegionMatrix[g + 3] = w;
                RegionMatrix[g + 4] = g + W.ppr;
                RegionMatrix[g + 5] = -1;
                RegionMatrix[g + 6] = 0;
                RegionMatrix[g + 7] = 0;
                RegionMatrix[g + 8] = 0;

                // Bottom Right sub-region
                g += W.ppr;
                RegionMatrix[g] = -1;
                RegionMatrix[g + 1] = RegionMatrix[r + 1] + w;
                RegionMatrix[g + 2] = RegionMatrix[r + 2] + w;
                RegionMatrix[g + 3] = w;
                RegionMatrix[g + 4] = RegionMatrix[r + 4];
                RegionMatrix[g + 5] = -1;
                RegionMatrix[g + 6] = 0;
                RegionMatrix[g + 7] = 0;
                RegionMatrix[g + 8] = 0;

                l += 4;

                // Now the goal is to find two different sub-regions
                // for the two nodes: the one previously recorded (r[0])
                // and the one we want to add (n)

                // Find the quadrant of the old node
                if (NodeMatrix[RegionMatrix[r]] < RegionMatrix[r + 1]) {
                  if (NodeMatrix[RegionMatrix[r] + 1] < RegionMatrix[r + 2]) {

                    // Top Left quarter
                    q = RegionMatrix[r + 5];
                  }
                  else {

                    // Bottom Left quarter
                    q = RegionMatrix[r + 5] + W.ppr;
                  }
                }
                else {
                  if (NodeMatrix[RegionMatrix[r] + 1] < RegionMatrix[r + 2]) {

                    // Top Right quarter
                    q = RegionMatrix[r + 5] + W.ppr * 2;
                  }
                  else {

                    // Bottom Right quarter
                    q = RegionMatrix[r + 5] + W.ppr * 3;
                  }
                }

                // We remove r[0] from the region r, add its mass to r and record it in q
                RegionMatrix[r + 6] = NodeMatrix[RegionMatrix[r] + 6];
                RegionMatrix[r + 7] = NodeMatrix[RegionMatrix[r]];
                RegionMatrix[r + 8] = NodeMatrix[RegionMatrix[r] + 1];

                RegionMatrix[q] = RegionMatrix[r];
                RegionMatrix[r] = -1;

                // Find the quadrant of n
                if (NodeMatrix[n] < RegionMatrix[r + 1]) {
                  if (NodeMatrix[n + 1] < RegionMatrix[r + 2]) {

                    // Top Left quarter
                    q2 = RegionMatrix[r + 5];
                  }
                  else {
                    // Bottom Left quarter
                    q2 = RegionMatrix[r + 5] + W.ppr;
                  }
                }
                else {
                  if(NodeMatrix[n + 1] < RegionMatrix[r + 2]) {

                    // Top Right quarter
                    q2 = RegionMatrix[r + 5] + W.ppr * 2;
                  }
                  else {

                    // Bottom Right quarter
                    q2 = RegionMatrix[r + 5] + W.ppr * 3;
                  }
                }

                if (q === q2) {

                  // If both nodes are in the same quadrant,
                  // we have to try it again on this quadrant
                  r = q;
                  continue;
                }

                // If both quadrants are different, we record n
                // in its quadrant
                RegionMatrix[q2] = n;
                break;
              }
            }
          }
        }
      }


      // 2) Repulsion
      //--------------
      // NOTES: adjustSizes = antiCollision & scalingRatio = coefficient

      if (W.settings.barnesHutOptimize) {
        coefficient = W.settings.scalingRatio;

        // Applying repulsion through regions
        for (n = 0; n < W.nodesLength; n += W.ppn) {

          // Computing leaf quad nodes iteration

          r = 0; // Starting with root region
          while (true) {

            if (RegionMatrix[r + 5] >= 0) {

              // The region has sub-regions

              // We run the Barnes Hut test to see if we are at the right distance
              distance = Math.sqrt(
                (Math.pow(NodeMatrix[n] - RegionMatrix[r + 7], 2)) +
                (Math.pow(NodeMatrix[n + 1] - RegionMatrix[r + 8], 2))
              );

              if (2 * RegionMatrix[r + 3] / distance < W.settings.barnesHutTheta) {

                // We treat the region as a single body, and we repulse

                xDist = NodeMatrix[n] - RegionMatrix[r + 7];
                yDist = NodeMatrix[n + 1] - RegionMatrix[r + 8];

                if (W.settings.adjustSizes) {

                  //-- Linear Anti-collision Repulsion
                  if (distance > 0) {
                    factor = coefficient * NodeMatrix[n + 6] *
                      RegionMatrix[r + 6] / distance / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                  else if (distance < 0) {
                    factor = -coefficient * NodeMatrix[n + 6] *
                      RegionMatrix[r + 6] / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                }
                else {

                  //-- Linear Repulsion
                  if (distance > 0) {
                    factor = coefficient * NodeMatrix[n + 6] *
                      RegionMatrix[r + 6] / distance / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                }

                // When this is done, we iterate. We have to look at the next sibling.
                if (RegionMatrix[r + 4] < 0)
                  break;  // No next sibling: we have finished the tree
                r = RegionMatrix[r + 4];
                continue;

              }
              else {

                // The region is too close and we have to look at sub-regions
                r = RegionMatrix[r + 5];
                continue;
              }

            }
            else {

              // The region has no sub-region
              // If there is a node r[0] and it is not n, then repulse

              if (RegionMatrix[r] >= 0 && RegionMatrix[r] !== n) {
                xDist = NodeMatrix[n] - NodeMatrix[RegionMatrix[r]];
                yDist = NodeMatrix[n + 1] - NodeMatrix[RegionMatrix[r] + 1];

                distance = Math.sqrt(xDist * xDist + yDist * yDist);

                if (W.settings.adjustSizes) {

                  //-- Linear Anti-collision Repulsion
                  if (distance > 0) {
                    factor = coefficient * NodeMatrix[n + 6] *
                      NodeMatrix[RegionMatrix[r] + 6] / distance / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                  else if (distance < 0) {
                    factor = -coefficient * NodeMatrix[n + 6] *
                      NodeMatrix[RegionMatrix[r] + 6] / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                }
                else {

                  //-- Linear Repulsion
                  if (distance > 0) {
                    factor = coefficient * NodeMatrix[n + 6] *
                      NodeMatrix[RegionMatrix[r] + 6] / distance / distance;

                    NodeMatrix[n + 2] += xDist * factor;
                    NodeMatrix[n + 3] += yDist * factor;
                  }
                }

              }

              // When this is done, we iterate. We have to look at the next sibling.
              if (RegionMatrix[r + 4] < 0)
                break;  // No next sibling: we have finished the tree
              r = RegionMatrix[r + 4];
              continue;
            }
          }
        }
      }
      else {
        coefficient = W.settings.scalingRatio;

        // Square iteration
        for (n1 = 0; n1 < W.nodesLength; n1 += W.ppn) {
          for (n2 = 0; n2 < n1; n2 += W.ppn) {

            // Common to both methods
            xDist = NodeMatrix[n1] - NodeMatrix[n2];
            yDist = NodeMatrix[n1 + 1] - NodeMatrix[n2 + 1];

            if (W.settings.adjustSizes) {

              //-- Anticollision Linear Repulsion
              distance = Math.sqrt(xDist * xDist + yDist * yDist) -
                NodeMatrix[n1 + 8] -
                NodeMatrix[n2 + 8];

              if (distance > 0) {
                factor = coefficient *
                  NodeMatrix[n1 + 6] *
                  NodeMatrix[n2 + 6] /
                  distance / distance;

                // Updating nodes' dx and dy
                NodeMatrix[n1 + 2] += xDist * factor;
                NodeMatrix[n1 + 3] += yDist * factor;

                NodeMatrix[n2 + 2] += xDist * factor;
                NodeMatrix[n2 + 3] += yDist * factor;
              }
              else if (distance < 0) {
                factor = 100 * coefficient *
                  NodeMatrix[n1 + 6] *
                  NodeMatrix[n2 + 6];

                // Updating nodes' dx and dy
                NodeMatrix[n1 + 2] += xDist * factor;
                NodeMatrix[n1 + 3] += yDist * factor;

                NodeMatrix[n2 + 2] -= xDist * factor;
                NodeMatrix[n2 + 3] -= yDist * factor;
              }
            }
            else {

              //-- Linear Repulsion
              distance = Math.sqrt(xDist * xDist + yDist * yDist);

              if (distance > 0) {
                factor = coefficient *
                  NodeMatrix[n1 + 6] *
                  NodeMatrix[n2 + 6] /
                  distance / distance;

                // Updating nodes' dx and dy
                NodeMatrix[n1 + 2] += xDist * factor;
                NodeMatrix[n1 + 3] += yDist * factor;

                NodeMatrix[n2 + 2] -= xDist * factor;
                NodeMatrix[n2 + 3] -= yDist * factor;
              }
            }
          }
        }
      }


      // 3) Gravity
      //------------
      g = W.settings.gravity / W.settings.scalingRatio;
      coefficient = W.settings.scalingRatio;
      for (n = 0; n < W.nodesLength; n += W.ppn) {
        factor = 0;

        // Common to both methods
        xDist = NodeMatrix[n];
        yDist = NodeMatrix[n + 1];
        distance = Math.sqrt(
          Math.pow(xDist, 2) + Math.pow(yDist, 2)
        );

        if (W.settings.strongGravityMode) {

          //-- Strong gravity
          if (distance > 0)
            factor = coefficient * NodeMatrix[n + 6] * g;
        }
        else {

          //-- Linear Anti-collision Repulsion n
          if (distance > 0)
            factor = coefficient * NodeMatrix[n + 6] * g / distance;
        }

        // Updating node's dx and dy
        NodeMatrix[n + 2] -= xDist * factor;
        NodeMatrix[n + 3] -= yDist * factor;
      }



      // 4) Attraction
      //---------------
      coefficient = 1 *
        (W.settings.outboundAttractionDistribution ?
          outboundAttCompensation :
          1);

      // TODO: simplify distance
      // TODO: coefficient is always used as -c --> optimize?
      for (e = 0; e < W.edgesLength; e += W.ppe) {
        n1 = EdgeMatrix[e];
        n2 = EdgeMatrix[e + 1];
        w = EdgeMatrix[e + 2];

        // Edge weight influence
        ewc = Math.pow(w, W.settings.edgeWeightInfluence);

        // Common measures
        xDist = NodeMatrix[n1] - NodeMatrix[n2];
        yDist = NodeMatrix[n1 + 1] - NodeMatrix[n2 + 1];

        // Applying attraction to nodes
        if (W.settings.adjustSizes) {

          distance = Math.sqrt(
            (Math.pow(xDist, 2) + Math.pow(yDist, 2)) -
            NodeMatrix[n1 + 8] -
            NodeMatrix[n2 + 8]
          );

          if (W.settings.linLogMode) {
            if (W.settings.outboundAttractionDistribution) {

              //-- LinLog Degree Distributed Anti-collision Attraction
              if (distance > 0) {
                factor = -coefficient * ewc * Math.log(1 + distance) /
                distance /
                NodeMatrix[n1 + 6];
              }
            }
            else {

              //-- LinLog Anti-collision Attraction
              if (distance > 0) {
                factor = -coefficient * ewc * Math.log(1 + distance) / distance;
              }
            }
          }
          else {
            if (W.settings.outboundAttractionDistribution) {

              //-- Linear Degree Distributed Anti-collision Attraction
              if (distance > 0) {
                factor = -coefficient * ewc / NodeMatrix[n1 + 6];
              }
            }
            else {

              //-- Linear Anti-collision Attraction
              if (distance > 0) {
                factor = -coefficient * ewc;
              }
            }
          }
        }
        else {

          distance = Math.sqrt(
            Math.pow(xDist, 2) + Math.pow(yDist, 2)
          );

          if (W.settings.linLogMode) {
            if (W.settings.outboundAttractionDistribution) {

              //-- LinLog Degree Distributed Attraction
              if (distance > 0) {
                factor = -coefficient * ewc * Math.log(1 + distance) /
                  distance /
                  NodeMatrix[n1 + 6];
              }
            }
            else {

              //-- LinLog Attraction
              if (distance > 0)
                factor = -coefficient * ewc * Math.log(1 + distance) / distance;
            }
          }
          else {
            if (W.settings.outboundAttractionDistribution) {

              //-- Linear Attraction Mass Distributed
              // NOTE: Distance is set to 1 to override next condition
              distance = 1;
              factor = -coefficient * ewc / NodeMatrix[n1 + 6];
            }
            else {

              //-- Linear Attraction
              // NOTE: Distance is set to 1 to override next condition
              distance = 1;
              factor = -coefficient * ewc;
            }
          }
        }

        // Updating nodes' dx and dy
        // TODO: if condition or factor = 1?
        if (distance > 0) {

          // Updating nodes' dx and dy
          NodeMatrix[n1 + 2] += xDist * factor;
          NodeMatrix[n1 + 3] += yDist * factor;

          NodeMatrix[n2 + 2] -= xDist * factor;
          NodeMatrix[n2 + 3] -= yDist * factor;
        }
      }


      // 5) Apply Forces
      //-----------------
      var force,
          swinging,
          traction,
          nodespeed;

      // MATH: sqrt and square distances
      if (W.settings.adjustSizes) {

        for (n = 0; n < W.nodesLength; n += W.ppn) {
          if (!NodeMatrix[n + 9]) {
            force = Math.sqrt(
              Math.pow(NodeMatrix[n + 2], 2) +
              Math.pow(NodeMatrix[n + 3], 2)
            );

            if (force > W.maxForce) {
              NodeMatrix[n + 2] =
                NodeMatrix[n + 2] * W.maxForce / force;
              NodeMatrix[n + 3] =
                NodeMatrix[n + 3] * W.maxForce / force;
            }

            swinging = NodeMatrix[n + 6] *
              Math.sqrt(
                (NodeMatrix[n + 4] - NodeMatrix[n + 2]) *
                (NodeMatrix[n + 4] - NodeMatrix[n + 2]) +
                (NodeMatrix[n + 5] - NodeMatrix[n + 3]) *
                (NodeMatrix[n + 5] - NodeMatrix[n + 3])
              );

            traction = Math.sqrt(
              (NodeMatrix[n + 4] + NodeMatrix[n + 2]) *
              (NodeMatrix[n + 4] + NodeMatrix[n + 2]) +
              (NodeMatrix[n + 5] + NodeMatrix[n + 3]) *
              (NodeMatrix[n + 5] + NodeMatrix[n + 3])
            ) / 2;

            nodespeed =
              0.1 * Math.log(1 + traction) / (1 + Math.sqrt(swinging));

            // Updating node's positon
            NodeMatrix[n] =
              NodeMatrix[n] + NodeMatrix[n + 2] *
              (nodespeed / W.settings.slowDown);
            NodeMatrix[n + 1] =
              NodeMatrix[n + 1] + NodeMatrix[n + 3] *
              (nodespeed / W.settings.slowDown);
          }
        }
      }
      else {

        for (n = 0; n < W.nodesLength; n += W.ppn) {
          if (!NodeMatrix[n + 9]) {

            swinging = NodeMatrix[n + 6] *
              Math.sqrt(
                (NodeMatrix[n + 4] - NodeMatrix[n + 2]) *
                (NodeMatrix[n + 4] - NodeMatrix[n + 2]) +
                (NodeMatrix[n + 5] - NodeMatrix[n + 3]) *
                (NodeMatrix[n + 5] - NodeMatrix[n + 3])
              );

            traction = Math.sqrt(
              (NodeMatrix[n + 4] + NodeMatrix[n + 2]) *
              (NodeMatrix[n + 4] + NodeMatrix[n + 2]) +
              (NodeMatrix[n + 5] + NodeMatrix[n + 3]) *
              (NodeMatrix[n + 5] + NodeMatrix[n + 3])
            ) / 2;

            nodespeed = NodeMatrix[n + 7] *
              Math.log(1 + traction) / (1 + Math.sqrt(swinging));

            // Updating node convergence
            NodeMatrix[n + 7] =
              Math.min(1, Math.sqrt(
                nodespeed *
                (Math.pow(NodeMatrix[n + 2], 2) +
                 Math.pow(NodeMatrix[n + 3], 2)) /
                (1 + Math.sqrt(swinging))
              ));

            // Updating node's positon
            NodeMatrix[n] =
              NodeMatrix[n] + NodeMatrix[n + 2] *
              (nodespeed / W.settings.slowDown);
            NodeMatrix[n + 1] =
              NodeMatrix[n + 1] + NodeMatrix[n + 3] *
              (nodespeed / W.settings.slowDown);
          }
        }
      }

      // Counting one more iteration
      W.iterations++;
    }

    /**
     * Message reception & sending
     */

    // Sending data back to the supervisor
    var sendNewCoords;

    if (typeof window !== 'undefined' && window.document) {

      // From same document as sigma
      sendNewCoords = function() {
        var e;

        if (document.createEvent) {
          e = document.createEvent('Event');
          e.initEvent('newCoords', true, false);
        }
        else {
          e = document.createEventObject();
          e.eventType = 'newCoords';
        }

        e.eventName = 'newCoords';
        e.data = {
          nodes: NodeMatrix.buffer
        };
        requestAnimationFrame(function() {
          document.dispatchEvent(e);
        });
      };
    }
    else {

      // From a WebWorker
      sendNewCoords = function() {
        self.postMessage(
          {nodes: NodeMatrix.buffer},
          [NodeMatrix.buffer]
        );
      };
    }

    // Algorithm run
    function run(n) {
      for (var i = 0; i < n; i++)
        pass();
      sendNewCoords();
    }

    // On supervisor message
    var listener = function(e) {
      switch (e.data.action) {
        case 'start':
          init(
            new Float32Array(e.data.nodes),
            new Float32Array(e.data.edges),
            e.data.config
          );

          // First iteration(s)
          run(W.settings.startingIterations);
          break;

        case 'loop':
          NodeMatrix = new Float32Array(e.data.nodes);
          run(W.settings.iterationsPerRender);
          break;

        case 'config':

          // Merging new settings
          configure(e.data.config);
          break;

        case 'kill':

          // Deleting context for garbage collection
          __emptyObject(W);
          NodeMatrix = null;
          EdgeMatrix = null;
          RegionMatrix = null;
          self.removeEventListener('message', listener);
          break;

        default:
      }
    };

    // Adding event listener
    self.addEventListener('message', listener);
  };


  /**
   * Exporting
   * ----------
   *
   * Crush the worker function and make it accessible by sigma's instances so
   * the supervisor can call it.
   */
  var crush = null; function no_crush(fnString) {
    var pattern,
        i,
        l;

    var np = [
      'x',
      'y',
      'dx',
      'dy',
      'old_dx',
      'old_dy',
      'mass',
      'convergence',
      'size',
      'fixed'
    ];

    var ep = [
      'source',
      'target',
      'weight'
    ];

    var rp = [
      'node',
      'centerX',
      'centerY',
      'size',
      'nextSibling',
      'firstChild',
      'mass',
      'massCenterX',
      'massCenterY'
    ];

    // rp
    // NOTE: Must go first
    for (i = 0, l = rp.length; i < l; i++) {
      pattern = new RegExp('rp\\(([^,]*), \'' + rp[i] + '\'\\)', 'g');
      fnString = fnString.replace(
        pattern,
        (i === 0) ? '$1' : '$1 + ' + i
      );
    }

    // np
    for (i = 0, l = np.length; i < l; i++) {
      pattern = new RegExp('np\\(([^,]*), \'' + np[i] + '\'\\)', 'g');
      fnString = fnString.replace(
        pattern,
        (i === 0) ? '$1' : '$1 + ' + i
      );
    }

    // ep
    for (i = 0, l = ep.length; i < l; i++) {
      pattern = new RegExp('ep\\(([^,]*), \'' + ep[i] + '\'\\)', 'g');
      fnString = fnString.replace(
        pattern,
        (i === 0) ? '$1' : '$1 + ' + i
      );
    }

    return fnString;
  }

  // Exporting
  function getWorkerFn() {
    var fnString = crush ? crush(Worker.toString()) : Worker.toString();
    return ';(' + fnString + ').call(this);';
  }

  if (inWebWorker) {

    // We are in a webworker, so we launch the Worker function
    eval(getWorkerFn());
  }
  else {

    // We are requesting the worker from sigma, we retrieve it therefore
    if (typeof sigma === 'undefined')
      throw 'sigma is not declared';

    sigma.prototype.getForceAtlas2Worker = getWorkerFn;
  }
}).call(this);
