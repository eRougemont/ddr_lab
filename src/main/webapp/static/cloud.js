window.addEventListener("load", function(event) {
  var cloudId = "wordcloud2";
  var div = document.getElementById(cloudId);
  var fontMin = 14;
  var fontMax = 100;
  WordCloud(div, {
    list: words,
    fontMin: fontMin,
    fontMax: fontMax,
    // origin : [0, 0],
    // drawOutOfBound: false,
    // minSize : fontmin,
    minRotation: -Math.PI / 4,
    maxRotation: Math.PI / 4,
    rotationSteps: 4,
    rotateRatio: 1,
    shuffle: true,
    shape: 'square',
    fontFamily: '"Fira Sans", "Open Sans", "Roboto", sans-serif',
    gridSize: 6,
    color: null,
    fontWeight: function(word, weight, fontSize) {
      var ratio = (fontSize - fontMin) / (fontMax - fontMin);
      var bold = 300 + Math.round(ratio * 16) * 50;
      if (bold > 900) bold = 900; // if bold > 900, display will bug
      return "" + bold;
    },
    backgroundColor: null,
    opacity : function(word, weight, fontSize) {
      var ratio = (fontSize - fontMin) / (fontMax - fontMin);
      var ratio = 1 - Math.pow( 1 - (ratio), 1.4);
      const dec = 100;
      let opacity = Math.round(dec * (1 - ratio * 0.6)) / dec;
      return opacity;
    },
  });
});

