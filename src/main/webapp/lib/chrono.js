import * as d3 from "https://cdn.jsdelivr.net/npm/d3@7/+esm";

(function () {

const form = document.forms['chrono'];
const lines = document.getElementById("lines");




// create a search field for each curve param q=…
const urlPars = new URLSearchParams(window.location.search);
// create at least on q
if (!urlPars.has("q")) urlPars.append("q", "");
for (const q of urlPars.getAll("q")) {
    lineCreate(q);
}

const div = document.createElement("div");
div.className = "searchbuts";
lines.parentNode.insertBefore(div, lines.nextSibling);
const add = document.createElement("button");
add.type = "button";
add.className = "add";
add.onclick = function() {lineCreate("")};
div.append(add);
const submit = document.createElement("button");
submit.type = "submit";
submit.className = "submit";
submit.innerText = "Envoyer";
div.append(submit);

/** Get values of form as search params */
function pars(form) {
    const formData = new FormData(form);
    // delete empty values, be careful, deletion will modify iterator
    const keys = Array.from(formData.keys());
    for (const key of keys) {
        if (!formData.get(key)) {
            formData.delete(key);
        }
    }
    return new URLSearchParams(formData);
}



function lineCreate(q) {
    const li = document.createElement("li");
    li.draggable = false; // make draggable by handle
    li.ondragstart = lineDragStart;
    li.ondragover = lineDragOver;
    li.ondragend = lineDragEnd;
    li.className = "q";
    const area = document.createElement("textarea");
    area.placeholder = "Entrez un ou plusieurs mots à observer";
    area.value = q;
    area.name = "q";
    area.className = "q";
    area.rows= 1;
    area.addEventListener('keypress', function (e) {
        if (e.keyCode === 13 || e.which === 13) {
            e.preventDefault();
            form.draw();
            return false;
        }
    })
    /*
    const div = document.createElement("div");
    div.className = "suggester";
    div.append(area);
    li.append(remove, div);
    */
    const remove = document.createElement("span");
    remove.className = "remove";
    remove.onclick = function() { 
        li.remove(); 
        form.draw();
    };
    const handle = document.createElement("span");
    handle.className = "handle";
    handle.onmousedown = function(e) {
        li.draggable = true;
    };
    handle.onmouseup = function(e) {
        li.draggable = false;
    };
    li.append(remove, area, handle);
    lines.append(li);
}

let lineSelected = null;

function lineDragStart(e) {
    e.currentTarget.classList.add("grabbing");
    document.body.classList.add("grabbing");
    e.dataTransfer.effectAllowed = 'none';
    e.dataTransfer.setData('text/plain', null);
    lineSelected = e.target;
}

function lineDragOver(e) {
    if (e.target.parentNode != lineSelected.parentNode) return;
    e.preventDefault();
    if (isBefore(lineSelected, e.target)) {
        e.target.parentNode.insertBefore(lineSelected, e.target)
    } else {
        e.target.parentNode.insertBefore(lineSelected, e.target.nextSibling)
    }
}

function lineDragEnd() {
    lineSelected.classList.remove("grabbing");
    document.body.classList.remove("grabbing");
    lineSelected.draggable = false;
    lineSelected = null;
    form.draw();
}

function isBefore(el1, el2) {
    let cur;
    if (el2.parentNode === el1.parentNode) {
        for (cur = el1.previousSibling; cur; cur = cur.previousSibling) {
            if (cur === el2) return true;
        }
    }
    return false;
}


const locale = d3.formatDefaultLocale({
    decimal: ",",
    thousands: " ",
    grouping: [3]
});
d3.timeFormatDefaultLocale({
    dateTime: "%x, %X",
    date: "%Y-%-m-%-d",
    time: "%-I:%M:%S %p",
    periods: ["AM", "PM"],
    days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    months: ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"],
    shortMonths: ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
});



/**
 *  
 */
const rollingInput = document.getElementById('rolling');

function rolling(values, rollingLeft, rollingRight)
{
    if (values == null) return null;
    const len = values.length;
    if (len < 2) return values;
    if ( (rollingRight + rollingLeft) < 1) return values; 
    const means = new Float64Array(len).fill(NaN);

    for (let i = 0; i < len; i++) {
        const from = Math.max(0, i - rollingLeft);
        const to = Math.min(len - 1, i + rollingRight);
        let sum = 0;
        let card = 0;
        for (let j = from; j <=to; j++) {
            if (isNaN(values[j])) continue;
            card++;
            sum += values[j];
        }
        if (card > 0) {
            means[i] = sum / card;
        }
    }
    return means;
}


const chart = function(data) {
    // Declare the chart dimensions and margins.
    const width = 960;
    const height = 400;
    const margin = {
        top: 30,
        right: 20,
        bottom: 20,
        left: 50,
    }
    const yearMin = data.desc.yearRange[0];
    const yearMax = data.desc.yearRange[1];

    // Declare the x (horizontal position) scale.
    const x = d3.scaleUtc()
        .domain([new Date("" + yearMin), new Date("" + yearMax)])
        .range([margin.left, width - margin.right]);

    const rollingLeft = (rollingInput)?Number(rollingInput.value):0;
    const rollingRight = rollingLeft;


    // Create the SVG container.
    const svg = d3.create("svg")
        .attr("class", "alix")
        .attr("width", "100%")
        .attr("height", "100%")
        .attr("viewBox", [0, 0, width, height])
        // .attr("style", "max-width: 100%; height: auto; height: intrinsic;")
        .on("pointerenter pointermove", tipmove)
        .on("pointerleave", tipleave)
    ;

    function tipmove(event) {
        const o = x.invert(d3.pointer(event)[0]);
        // get the date
        // console.log(o);
    }

    function tipleave(event) {
    }


    // Add the x-axis and label.
    svg.append("g")
        .attr("transform", "translate(0," + (height - margin.bottom) + ")")
        .call(d3.axisBottom(x).ticks(width / 60).tickSizeOuter(0))
        .call(g => g.selectAll(".tick line").clone()
            .attr("y2", margin.top + margin.bottom - height)
            .attr("stroke-opacity", 0.2)
        )
    ;
    
    // all queries empty, show doc size
    if (!data.desc.freqRange) {
        // const occs = data.series[0].occs;
        // const freqs = data.series[0].freqs;

        const occs = rolling(data.series[0].occs, rollingLeft, rollingRight);
        const freqs = rolling(data.series[0].freqs, rollingLeft, rollingRight);

        // Declare the right vertical scale.
        const y2 = d3.scaleLinear()
            .domain([0, d3.max(occs)])
            .rangeRound([height - margin.bottom, margin.top])
        ;

        // Occs area
        const area = d3.area()
            .x( (d, i) => x(new Date("" + (yearMin + i))) )
            .y0(y2(0))
            .y1((d) => (d == 0)?y2(0):y2(d))
            .curve(d3.curveStep)
        ;
        // Append a path for the area
        svg.append("path")
            .attr("class", "occs")
            .attr("d", area(freqs))
        ;

        let label = "Nombre de mots publiés par an";
        const roll = 1 + rollingLeft + rollingRight;
        if (roll > 1) {
            label += ", avec moyenne glissante sur " + roll + " ans (-" + rollingLeft + ", +" + rollingRight +")";
        }

        // y scale
        svg.append("g")
            .attr("transform", "translate(" + (margin.left) + ",0)")
            .attr("class", "scale")
            .call(d3.axisLeft(y2).ticks(height / 40))
            .call(g => g.select(".domain").remove())
            .call(g => g.selectAll(".tick line").clone()
                .attr("x2", (width - margin.left - margin.right))
                .attr("stroke-opacity", 0.1)
            )
            .call(g => g.append("text")
                .attr("x", 0)
                .attr("y", 20)
                .attr("class", "label")
                .attr("text-anchor", "start")
                .attr("fill", "currentColor")
                .text(label)
        );
        return svg.node();
    }

    const freqrel = (document.getElementById('freqrel'))?document.getElementById('freqrel').checked:false;

    // get the max of series

    let label = "Occurrences, fréquence par an";

    let key = "freqs";
    if (freqrel) {
        label = "Fréquence relative aux mot publiés (%)";
        key = "freqrels";
    }
    

    
    const roll = 1 + rollingLeft + rollingRight;
    if (roll > 1) {
        label += ", avec moyenne glissante sur " + roll + " ans (-" + rollingLeft + ", +" + rollingRight +")";
    }

    const points = [];
    const domain = [0, 0];
    for (let i = 1; i < data.series.length; i++) {
        const p = data.series[i][key];
        if (!p) continue; // empty q
        points[i] = rolling(p,  rollingLeft, rollingRight);
        const max = d3.max(points[i]);
        if (max > domain[1]) domain[1] = max;
    }

    // Declare the y (vertical position) scale.
    const y = d3.scaleLinear()
        .domain(domain)
        .range([height - margin.bottom, margin.top])
    ;


    // Add the y-axis with grid lines
    svg.append("g")
        .attr("transform", "translate(" + margin.left + ",0)")
        .call(d3.axisLeft(y).ticks(height / 40))
        // .call(g => g.select(".domain").remove())
        .call(g => g.selectAll(".tick line").clone()
            .attr("x2", (width - margin.left - margin.right))
            .attr("stroke-opacity", 0.1)
        )
        .call(g => g.append("text")
            .attr("class", "label")
            .attr("x", 0)
            .attr("y", 20)
            .attr("fill", "currentColor")
            .attr("text-anchor", "start")
            .text(label)
        )
    ;


    // Declare the line generator.
    const line = d3.line()
        .x( (d, i) => x(new Date("" + (yearMin + i))))
        .y(d => y(d))
        .curve(d3.curveBasis)
    ;

    for (let i = 1; i < points.length; i++) {
        if (!points[i]) continue; // empty q
        // Append a path for the line.
        svg.append("path")
            .attr("class", "curve curve" + i)
            .attr("d", line(points[i]))
        ;
        // label
        svg.append("text")
            .attr("x", margin.left + 20)
            .attr("y", margin.top + i * 25)
            .attr("class", "legend legend" + i)
            .text(data.series[i].q)

        /*
        // Append the dots.
        const symbolsI = (i-1) % symbols.length;
        const dots = svg.append("g")
            .attr("fill", "none")
            .attr("class", "dots dots" + i)
            .selectAll("text")
            .data(points)
            .join("text")
            .attr("class", "dot")
            .attr("x", (d, i) => x(new Date("" + (yearMin + i))))
            .attr("y", d => y(d))
            .text(symbols[symbolsI])
        ;
        */
    }
    
    return svg.node();
}
// load data
const tempolex = document.getElementById("tempolex");
const chronotip = d3.select("body")
    .append("div")
    .attr("id", "chronotip")
    .attr("class", "tooltip")
    .text("a simple tooltip");

form.draw = function(history = true) {
    const formData = new FormData(form);
    const search = new URLSearchParams(formData);
    if (history) {
        const url = new URL(window.location);
        url.search = pars(form);
        window.history.pushState({}, '', url);
    }
    const url = new URL("data/chrono", window.location);
    url.search = pars(form);
    
    d3.json(url).then(data => {
        tempolex.innerText = '';
        tempolex.append(chart(data));
    })
    // do not update facets and biblio for freqrel toggle
    if (event && event.target && (event.target.id == 'freqrel' || event.target.id == 'rolling')) {
        return;
    }
    const kwicUrl = "data/kwicdate?" + search.toString();
    alix.kwicLoad(kwicUrl);
    console.log(kwicUrl);
}

const freqrel = document.getElementById('freqrel');
if (freqrel) {
    if (freqrel.checked) freqrel.parentNode.classList.add("checked");
    freqrel.addEventListener("change", function(event) {
        if (freqrel.checked) freqrel.parentNode.classList.add("checked");
        else freqrel.parentNode.classList.remove("checked");
    }, true);
}

const controls = form.elements;
for (let i = 0, control; control = controls[i++];) {
    // do not add on change on control without changing value
    if (
        control.type != 'checkbox' 
        && control.type != 'radio'  
        && control.type != 'number' 
        && control.type != 'select'
        && control.type != 'select-one'
    ) continue;
    control.addEventListener("change", form.draw);
}

// attach event listener
form.addEventListener("submit", function(event) {
    event.preventDefault();
    form.draw();
}, true);

form.draw();

window.addEventListener('popstate', function(event){
    if(event.state){
        form.draw(false);
    }
});

})();
