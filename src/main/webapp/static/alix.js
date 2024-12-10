/**
 * 
 */
const piagetlabo = function()
{
    /**
     * Get form values as url pars
     */
    function pars(form, ...include) {
        const formData = new FormData(form);
        // delete empty values, be careful, deletion will modify iterator
        const keys = Array.from(formData.keys());
        for (const key of keys) {
            if (include.length > 0 && !include.find(k => k === key)) {
                formData.delete(key);
            }
            if (!formData.get(key)) {
                formData.delete(key);
            }
        }
        return new URLSearchParams(formData);
    }
    return{
        pars:pars,
    }
}();


/**
 * Tabs
 */
(function(){
    
    const pathname = window.location.pathname;
    const tabs = document.querySelectorAll("nav.tabs a.tab");
    for (let i = 0, len = tabs.length; i < len; i++) {
        const a = tabs[i];
        if(pathname == a.pathname) a.classList.add("here");
        else a.classList.remove("here");
    }
})();

/**
 * Live search on home
 */
(function(){
    const form = document.forms['livesearch'];
    if (!form) return;
    if (!form['q']) return;
    const results = document.getElementById('results');
    if (!results) return;
    const scroller = document.getElementById('scroller');
    const status = document.getElementById('status');
    // the loader, make it unique to allow abort() when type
    const xhr = new XMLHttpRequest();

    /**
     * Get some text
     * 
     * @param {String} url 
     * @param {function} callback 
     * @returns 
     */
    const load = function (url, callback) {
        xhr.open('GET', url); // open as fast as possible for readyState
        /*
        // do something onprogress ?
        
        let start = 0;
        xhr.onprogress = function() {
            // loop on separator
            var end;
            while ((end = xhr.response.indexOf(sep, start)) >= 0) {
                callback(xhr.response.slice(start, end));
                start = end + sep.length;
            }
        };
        */
        xhr.responseType = 'text';
        xhr.onload = function() {
            callback(xhr.response);
        };
        xhr.onerror = function() {
            if(xhr.status == 404) {
                callback(404);
            }
        };
        xhr.send();
    };

    


    let page = 1;
    let loading = false;

    // callback after ajax load
    const print = function(html) {
        // no more results, say to scroll it is loading
        if (html == 404) {
            return;
        }
        const div = document.createElement("div");
        div.classList.add("append");
        div.classList.add("paging");
        div.innerHTML = html;
        results.appendChild(div);
        loading = false;
    };
    // event for infinite scroll
    window.addEventListener('scroll', e => {
        if (loading) return;
        
        const endOfPage = document.documentElement.scrollTop +
          document.documentElement.clientHeight >=
        document.documentElement.scrollHeight - 100;
        if (!endOfPage) return;
        loading = true;
        const formData = new FormData(form);
        const pars = new URLSearchParams(formData);
        pars.set("page", ++page);
        const ajaxurl = form.action + '?' + pars;
        load(ajaxurl, print);
    }, false);
    
    const showSlides = function() {
        document.documentElement.classList.add("slides");
        const slides = document.querySelectorAll("body > .slide");
        for (let i = 0, len = slides.length; i < len; i++) {
            const slide = slides[i];
            slide.classList.remove("hide");
        }
    };

    const hideSlides = function() {
        document.documentElement.classList.remove("slides");
        const slides = document.querySelectorAll("body > .slide");
        for (let i = 0, len = slides.length; i < len; i++) {
            const slide = slides[i];
            slide.classList.add("hide");
        }
    };
    
    let lastq;
    const qpop = function() {
        xhr.abort();
        const formData = new FormData(form);
        const url = new URL(window.location);
        url.search = piagetlabo.pars(form);
        window.history.replaceState({}, '', url);
        const q = form['q'].value;
        
        results.innerText = '';
        if (!q) {
            if (lastq) {
                showSlides();
                scroller.classList.add("hide");
                lastq = null;
            }
            xhr.abort();
            return;
        }
        // new value, hide slides
        if (!lastq) {
            hideSlides();
            scroller.classList.remove("hide");
        }
        lastq = q;
        const ajaxurl = form.action + '?' + new URLSearchParams(formData);
        results.innerText = '';
        loading = true;
        load(ajaxurl, print);
    }
    // on form change, load new results, according to form
    form['q'].addEventListener('input', qpop, false);
    
    // load as bottom script
    const url = new URL(window.location);
    let searchParams = new URLSearchParams(window.location.search);
    const q = searchParams.get("q");
    if (q) {
        form["q"].value = q;
        qpop();
    }
})();

/**
 * Labo
 */
(function() {
    const fnum = new Intl.NumberFormat('fr-FR');
    // a form with tags also needed
    const form = document.forms['filter'];
    if (!form) return;
    // server side checked radio button
    form.reset();
    let graph = null;
    async function fetchGraph(url) {
        const response = await fetch(url);
        if (!response.ok) {
            console.error(url + " fetch error:", error);
        }
        const data = await response.json();
        if (graph) {
            graph.s.kill();
        }
        graph = new sigmot('graph', data);
    }

    // update biblio
    const biblioDiv = document.getElementById('biblio');
    const biblioXhr = new XMLHttpRequest();
    const biblioLoad = function (url) {
        // if (!biblioDiv) CRY
        biblioDiv.textContent = "";
        biblioXhr.open('GET', url);
        biblioXhr.responseType = 'text';
        let start = 0;
        const sep = "<article";
        biblioXhr.onprogress = function() {
            // loop on separator
            const end = biblioXhr.response.lastIndexOf(sep);
            if (end < 1) {
                biblioDiv.insertAdjacentHTML('beforeend', biblioXhr.response.slice(start));
                start = biblioXhr.response.length;
            }
            else {
                biblioDiv.insertAdjacentHTML('beforeend', biblioXhr.response.slice(start, end));
                start = end;
            }
            /*
            while ((end = xhr.response.indexOf(sep, start)) >= 0) {
                callback(xhr.response.slice(start, end));
                start = end + sep.length;
            }
            */
        };
        
        biblioXhr.onload = function() {
            biblioDiv.insertAdjacentHTML('beforeend', biblioXhr.response.slice(start));
            // biblioDiv.innerHTML = biblioXhr.response;
        };
        biblioXhr.onerror = function() {
            console.error(biblioXhr.status + ": " + url);
        };
        biblioXhr.send();
    };

    const facetsXhr = new XMLHttpRequest();
    const facetsLoad = function (url) {
        facetsXhr.open('GET', url);
        facetsXhr.responseType = 'json';
        facetsXhr.onload = function() {
            const json = facetsXhr.response;
            const freqAll = json.desc.freqAll;
            const hitsAll = json.desc.hitsAll;
            const docsAll = json.desc.docsAll;
            // loop on <output> controls and set them
            for (let i = 0, control; control = form.elements[i++];) {
                if (control.type != 'output') continue;
                const counts = json.data[control.name];
                if (!counts) continue;
                let title = "";
                if (freqAll > 0) {
                    title += ''
                        + fnum.format(+counts.hits) 
                        + "/<small>" + fnum.format(+counts.docs) + "</small>" 
                        + " textes";
                    if (counts.freq > 0) {
                        title += ", " + fnum.format(+counts.freq) + " occurences"
                    }
                }
                else if (hitsAll > 0 && hitsAll != docsAll) {
                    title += ''
                        + fnum.format(+counts.hits) 
                        + "/<small>" + fnum.format(+counts.docs) + "</small>"
                        + " textes"
                    ;
                }
                else {
                    title += ''
                        + fnum.format(+counts.docs) + " textes, "
                        + fnum.format(+counts.occs) + " mots"
                    ;
                }
                // fnum.format(+counts.freq) 
                // + "/" 
                // + fnum.format(+counts.occs) 
                // control.title = title;
                control.innerHTML = " (" + title + ")";
            }
        };
        facetsXhr.onerror = function() {
            console.error(facetsXhr.status + ": " + url);
        };
        facetsXhr.send();
    };


    let lastLabel;
    form.update = function() {
        const formData = new FormData(form);
        const search = new URLSearchParams(formData);
        
        const url = new URL(window.location);
        
        url.search = piagetlabo.pars(form);
        window.history.pushState({}, '', url);

        
        const graphUrl = "data/graph.json?win=1o&nodes=100&" + search.toString();
        fetchGraph(graphUrl);
        const biblioUrl = "data/kwicdate?" + search.toString();
        biblioLoad(biblioUrl);
        const facetsUrl = "data/facets?" + search.toString();
        facetsLoad(facetsUrl);
        if (lastLabel) {
            lastLabel.classList.remove('active');
        }
        const label = this.parentNode;
        lastLabel = label;
        if (label) {
            label.classList.add('active');
        }
    }
    const controls = form.elements;
    for (let i = 0, control; control = controls[i++];) {
        if (control.type != 'checkbox' && control.type != 'radio') continue;
        control.addEventListener("change", form.update);
    }
    // load as bottom script
    form.update();
})();

// set the date slider
(function() {
    const slider = document.getElementById('slider');
    if (!slider) return;
    const form = document.forms['filter'];
    const min = parseInt(slider.dataset.min);
    const max = parseInt(slider.dataset.max);
    noUiSlider.create(slider, {
        start: [min, max],
        range: {
            'min': [min],
            'max': [max]
        },
        connect: [false, true, false],
        step: 1,
        orientation: 'vertical',
        tooltips: {to: function (value) {
            return Math.round(value);
        }},
        animate: false,
    });
    const sliderUpdate = function (values, handle, unencoded, tap, positions, noUiSlider) {
        const lower = Math.round(values[0]);
        const upper = Math.round(values[1]);
        if (lower != min || upper != max) {
            form.elements['year'][0].value = lower;
            form.elements['year'][1].value = upper;
        }
        form.update();
    };
    slider.noUiSlider.on('set', sliderUpdate);
})();
