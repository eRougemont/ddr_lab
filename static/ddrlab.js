function clearForm(form) {
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


el = document.getElementById("checkall");
if (el) {
  el.addEventListener('click', () => {
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
  });
}

