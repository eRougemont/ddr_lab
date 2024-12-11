<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true"%>
<%!



%>
<%
FieldInt fint = alix.fieldInt(YEAR);
final int yearMin = fint.min();
final int yearMax = fint.max();



%>
<!DOCTYPE html>
<html>
    <head>
        <%@ include file="local/head.jsp" %>
        <title>Chronologies</title>
    </head>
    <body class="courbes">
        <header id="header">
            <%@ include file="local/tabs.jsp" %>
        </header>
        <div class="row">
            <aside id="aside" class="form">
                <form name="search">
                    <ul id="lines" class="lines">
                    </ul>
                </form>
            </aside>
            <main>
                <div id="tempolex"></div>
            </main>
        </div>
        <%@include file="local/footer.jsp" %>
        <script type="module">
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
    if (values == null) return null;
    const len = values.length;
    if (len < 2) return values;
    const means = new Float64Array(len).fill(NaN);
    let rightSure = Math.min(right, len - 1);
    let card = 0;
    let sum = 0;
    for (let i = 0; i <= rightSure; i++) {
        if (isNaN(values[i])) continue;
        card++;
        sum += values[i];
    }
    for (let i = 0; i < len; i++) {
        if (isNaN(values[i])) {
            // do nothing
        }
        else {
            means[i] = sum / card;
        }
        // del from left context
        const subIndex = i - left;
        if (subIndex >= 0 && !isNaN(values[subIndex])) {
            sum -= values[subIndex];
            card--;
        }
        else if (i > 0 && !isNaN(values[i - 1])) {
            sum -= values[i-1];
            card++;
        }
        // add from right context
        const addIndex = i + right;
        if (addIndex < len && !isNaN(values[subIndex])) {
            sum += values[addIndex];
            card++;
        }
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
        right: 30,
        bottom: 20,
        left: 50,
    }
    const yearMin = data.desc.yearRange[0];
    const yearMax = data.desc.yearRange[1];

    // Declare the x (horizontal position) scale.
    const x = d3.scaleUtc()
        .domain([new Date("" + yearMin), new Date("" + yearMax)])
        .range([margin.left, width - margin.right - margin.left]);

    // Declare the y (vertical position) scale.
    const y = d3.scaleLinear()
        .domain([
            0,
            data.desc.freqRange[1]
        ]) // + -> number
        .range([height - margin.bottom, margin.top]);



    // Create the SVG container.
    const svg = d3.create("svg")
        .attr("class", "alix")
        .attr("width", "100%")
        .attr("height", "auto")
        .attr("viewBox", [0, 0, width, height])
        .attr("style", "max-width: 100%; height: auto; height: intrinsic;");

    /*
    // Add the x-axis.
    svg.append("g")
        .attr("transform", "translate(0," + (height - margin.bottom) + ")")
        .call(
            d3.axisBottom(x)
            .ticks(width / 80).tickSizeOuter(0)
        );
    */


    // rolling occs
    // const occs = rolling(data.series[0].points, 2, 2);
    const occs = data.series[0].points;

    // Declare the right vertical scale.
    const y2 = d3.scaleLinear()
        .domain([1, d3.max(occs)]) // + -> number
        .rangeRound([height - margin.bottom, margin.top])
    ;

    /*
    const bandwidth = (width - margin.right - margin.left) / (1 + yearMax - yearMin);
    svg.append("g")
        .attr("fill", "rgba(255, 255, 255, 0.9)")
        .selectAll()
        .data()
        .join("rect")
            .attr("x", (d, i) => x(new Date("" + (yearMin + i))) - (bandwidth / 2))
            .attr("y", (d) => y2(d))
            .attr("height", (d) => y2(0) - y2(d))
            .attr("width", bandwidth)
    ;
    */
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

    // right scale
    svg.append("g")
        .attr("transform", "translate(" + (width - margin.left  - margin.right) + ",0)")
        .attr("class", "scale right")
        .call(d3.axisRight(y2).ticks(height / 40))
        .call(g => g.select(".domain").remove())
        .call(g => g.append("text")
            .attr("x", 0)
            .attr("y", 10)
            .attr("text-anchor", "start")
            .attr("fill", "currentColor")
            .text("Mots")
        );
    



    // Add the x-axis and label.
    svg.append("g")
        .attr("transform", "translate(0," + (height - margin.bottom) + ")")
        .call(d3.axisBottom(x).ticks(width / 80).tickSizeOuter(0))
        .call(g => g.selectAll(".tick line").clone()
            .attr("y2", margin.top + margin.bottom - height)
            .attr("stroke-opacity", 0.2)
        )
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
            .text("Occurrences")
        )
    ;


    // Declare the line generator.
    const line = d3.line()
        .x( (d, i) => x(new Date("" + (yearMin + i))))
        .y(d => y(d))
        .curve(d3.curveBasis)
    ;

    for (let i = 1; i < data.series.length; i++) {
        if (!data.series[i].points) continue; // empty q
        // Append a path for the line.
        svg.append("path")
            .attr("class", "curve curve" + i)
            // .attr("d", line( data.series[i].points ))
            .attr("d", line(rolling(data.series[i].points, 3, 3) ))
        ;

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

        </script>
    </body>
</html>
