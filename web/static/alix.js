'use strict';

var alix = function(){
  var q = document.getElementById("titles");
  function init(){
    qtitles();
    /*
    el = document.getElementById("checkall");
    if (el) {
      el.addEventListener('click', () => );
    }
    */
  }
  
  function qtitles(event)
  {
    if(!q) return;
    let url = "jsp/titles.jsp?q=";
    let suggest = q.parentNode.querySelector(".suggest");
    if (!suggest) return;
    let progress = q.parentNode.querySelector(".progress");
    // Liser.header = document.getElementById("header");
    let inId = q.form.id;
    
    q.addEventListener('input', function(e) {
      let query = this.value;
      if (!query);
      else if (query.slice(-1) != ' ') query += '*';
      if(progress) progress.style.visibility = 'visible';
      fetch(url + query, {
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache'
        }
      }).then(response => {
        return response.text()
      })
      .then(data => {
        suggest.innerHTML = data;
        let els = suggest.querySelectorAll(".bibl");
        for (let i = 0; i < els.length; ++i) {
          els[i].addEventListener('click', (event) => {
            inId.value = els[i].id;
            q.form.submit();
          });
        }
        
        if(progress) progress.style.visibility = 'hidden';
      });
      
    });
    q.addEventListener('keydown', function(e) {
      e = e || window.event;
      if (e.keyCode == 27) {
        q.blur(); //27 is the code for escape
        suggest.style.display = 'none';
      }
    });
    q.addEventListener('click', function(e) { // focus do not work on mobile
      suggest.style.display = 'block';
      // q.form.classList.add('focus');
      q.dispatchEvent(new Event('input')); // prendre les premiers résultats
    });
    window.addEventListener('click',  (event) => {
      suggest.style.display = 'none';
    });
    q.parentNode.addEventListener('click', (event) => { 
      event.stopPropagation(); // // do not propagate the click to blur outside form
    });

    suggest.addEventListener("touchstart", function (event) {
      // si on défile la liste de résultats sur du tactile, désafficher le clavier
      q.blur();
    });
  }

  
  // TOTHINK, put on all reste buttons ?
  function formClear(form) {
    form.reset();
    var elements = form.elements;
    for(i=0; i<elements.length; i++) {
      field_type = elements[i].type.toLowerCase();
      el = elements[i];
      switch(field_type) {
        case "text":
        case "password":
        case "textarea":
        case "hidden":
          el.value = "";
          break;
        case "radio":
        case "checkbox":
          if (el.checked) el.checked = false;
          break;
        case "select-one":
        case "select-multi":
          el.selectedIndex = -1;
          break;
        default:
          break;
      }
    }
  }
  
  // TODO, retest and parametrized
  function checkall(el) {
    let checked = el.checked;
    let form = el.form;
    let els = form.elements;
    for(i=0; i<els.length; i++) {
      let el = els[i];
      let type = el.type.toLowerCase();
      switch(type) {
        case "checkbox":
          el.checked = checked;
          break;
      }
    }
  }
  return{
    init:init,
    formClear:formClear,
  }
}();


alix.init();

