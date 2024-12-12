/**
 * 
 */
import * as d3 from "https://cdn.jsdelivr.net/npm/d3@7/+esm";

(function () {

const form = document.forms['search'];
const lines = document.getElementById("lines");





// create a searche field for each curve param q=…
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



function lineCreate(q) {
    const li = document.createElement("li");
    li.draggable = false; // make draggable by handle
    li.ondragstart = lineDragStart;
    li.ondragover = lineDragOver;
    li.ondragend = lineDragEnd;
    li.className = "q";
    const area = document.createElement("textarea");
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

/*
[
    null,
    [],
    [1, NaN, 1],
    [1, NaN, 1, NaN, 2, NaN, 1, NaN, 1],
].forEach(values => {
    console.log(values);
    console.log(rollingAverage(values, 2, 2));
});
*/

/**
 *  
 */
function rolling(values, left = 0, right = 0)
{
    if (left < 0) left = 0;
    if (right < 0) right = 0;
    if (values == null) return null;
    const len = values.length;
    if (len < 2) return values;
    const means = new Float64Array(len).fill(NaN);
    for (let i = 0; i < len; i++) {
        if (isNaN(values[i])) {
            means[i] = NaN;
            continue;
        }
        let card = 0;
        let sum = 0;
        let from = Math.max(0, i - left);
        let to = Math.min(i+right, len - 1);
        for (let pos = from; pos <= to; pos++) {
            if (isNaN(values[pos])) continue;
            card++;
            sum += values[pos];
        }
        means[i] = sum / card;
    }
    return means;
}

const chart = function(data) {
    const symbols = "●×♡♯ω✻ෆ♮#♦■▲★✚✱☀";
    // Declare the chart dimensions and margins.
    const width = 900;
    const height = 500;
    const margin = {
        top: 20,
        right: 10,
        bottom: 20,
        left: 50,
    }
    // Create the SVG container.
    const svg = d3.create("svg")
        .attr("class", "alix")
        .attr("width", "100%")
        .attr("height", "auto")
        .attr("viewBox", [0, 0, width, height])
        .attr("style", "max-width: 100%; height: auto; height: intrinsic;")
    ;
    const yearMin = data.desc.yearRange[0];
    const yearMax = data.desc.yearRange[1];

    // Declare the x (horizontal position) scale.
    const x = d3.scaleUtc()
        .domain([new Date("" + yearMin), new Date("" + yearMax)])
        .range([margin.left, width - margin.right ]);

    // Add the x-axis and label.
    svg.append("g")
        .attr("transform", "translate(0," + (height - margin.bottom) + ")")
        .call(d3.axisBottom(x).ticks(width / 80).tickSizeOuter(0))
        .call(g => g.selectAll(".tick line").clone()
            .attr("y2", margin.top + margin.bottom - height)
            .attr("stroke-opacity", 0.2)
        )
    ;
    
    // if 0 series, go out
    if (data.series.length < 1) {
        return svg.node();
    }
    

    // if 1 series, it’s occs count
    if (data.series.length == 1) {
        // rolling occs
        // const occs = rolling(data.series[0].points, 2, 2);
        const occs = data.series[0].points;
        // Declare the right vertical scale.
        const y2 = d3.scaleLinear()
            .domain([1, d3.max(occs)]) // + -> number
            .rangeRound([height - margin.bottom , margin.top])
        ;
        // Add the y-axis with grid lines, after occs
        svg.append("g")
            .attr("transform", "translate(" + margin.left + ",0)")
            .call(d3.axisLeft(y2).ticks(height / 40))
            .call(g => g.select(".domain").remove())
            /*.call(g => g.selectAll(".tick line").clone()
                .attr("x2", (width - margin.left - margin.right))
                .attr("stroke-opacity", 0.1)
            )*/
            .call(g => g.append("text")
                .attr("x", 0)
                .attr("y", 15)
                .attr("fill", "currentColor")
                .attr("text-anchor", "middle")
                .text("Mots")
            )
        ;
        /*
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
            .attr("d", area(occs))
        ;
        */
        // Declare the line generator.
        const line = d3.line()
            .x( (d, i) => x(new Date("" + (yearMin + i))))
            .y(d => y2(d))
            .curve(d3.curveBumpX)
        ;
        svg.append("path")
            .attr("class", "curve")
            // .attr("d", line( data.series[i].points ))
            .attr("d", line(occs))
        ;
        
        return svg.node();
    }

    const left = 3;
    const right = 3;
    const occs = rolling(data.series[0].points, left, right);
    console.log(occs);

    // prepare rolling data, get max fro curves
    const points = [];
    let max = 0;
    for (let i = 1; i < data.series.length; i++) {
        if (!data.series[i].points) continue; // empty q
        const series = rolling(data.series[i].points, left, right);
        // proportion
        for (let p = 0; p < series.length; p++) {
            series[p] = series[p] / occs[p];
        }
        points[i-1] = series;
        max = Math.max(max, d3.max(points[i-1]));
    }

    // Declare the y (vertical position) scale.
    const y = d3.scaleLinear()
        .domain([0, max])
        .range([height - margin.bottom, margin.top])
    ;

    const line = d3.line()
        .x( (d, i) => x(new Date("" + (yearMin + i))))
        .y(d => y(d))
        .curve(d3.curveBasis)
        // .curve(d3.curveBumpX)
    ;

    // Add the y-axis with grid lines, after occs
    svg.append("g")
        .attr("transform", "translate(" + margin.left + ",0)")
        .call(d3.axisLeft(y).ticks(height / 40))
        .call(g => g.select(".domain").remove())
        /*.call(g => g.selectAll(".tick line").clone()
            .attr("x2", (width - margin.left - margin.right))
            .attr("stroke-opacity", 0.1)
        )*/
        .call(g => g.append("text")
            .attr("x", 0)
            .attr("y", 15)
            .attr("fill", "currentColor")
            .attr("text-anchor", "middle")
            .text("Mots")
        )
    ;

    for (let i = 0; i < points.length; i++) {
        if (!points[i]) continue; // empty q
        // Append a path for the line.
        svg.append("path")
            .attr("class", "curve curve" + (i + 1))
            // .attr("d", line( data.series[i].points ))
            .attr("d", line(points[i]))
        ;
        /*
        // Append the dots.
        const symbolsI = (i-1) % symbols.length;
        const dots = svg.append("g")
            .attr("fill", "none")
            .attr("class", "dots dots" + i)
            .selectAll("text")
            .data(data.series[i].points)
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


form.draw = function(history = true) {
    const formData = new FormData(form);
    const search = new URLSearchParams(formData);
    if (history) {
        const url = new URL(window.location);    
        url.search = alix.pars(form);
        window.history.pushState({}, '', url);
    }
    const url = new URL("data/chrono", window.location);
    url.search = alix.pars(form);
    d3.json(url).then(data => {
        tempolex.innerText = '';
        tempolex.append(chart(data));
    })
}

// attach event listener
form.addEventListener("submit", function(event) {
    event.preventDefault();
    form.draw();
}, true);

form.draw();

window.addEventListener('popstate', function(event){
    if(event.state){
        console.log("hist");
        form.draw(false);
    }
});

})();
