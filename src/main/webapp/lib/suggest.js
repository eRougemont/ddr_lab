/**
 * © 2024, 2012, 2009, frederic.glorieux@fictif.org
 *
 * This program is a free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License 
 * http://www.gnu.org/licenses/lgpl.html
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 */
(function (global, factory) {
    typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
    typeof define === 'function' && define.amd ? define(factory) :
    (global = typeof globalThis !== 'undefined' ? globalThis : global || self, global.suggest = factory());
} (this, function () { 'use strict';

    function hide(event, input) {
        if (!input) input = this;
        input.suggDiv.style.display = "none";
    }

    /**
     * Get form values as url pars
     */
    function pars(form, include) {
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
    
    function load(event) {

        const input = this;
        const value = input.value.trim();
        const suggDiv = input.suggDiv;
        /* no value, get list
        if (!value) {
            suggDiv.innerText = '';
            suggDiv.style.display = "none";
            input.suggIndex = undefined;
            input.suggArray = undefined;
            return;
        }
        */
        // ensure visibility if input was cleared
        suggDiv.style.display = "";
        // indentation prefix is a very bad idea
        const pos = Math.max(value.lastIndexOf(' '), value.lastIndexOf('"'));
        const prefix = (pos >= 0)?(value.substring(0, pos + 1)):'';
        const prefixIndent = "\u00a0\u00a0".repeat(prefix.length); // \u202f
        
        let q = (pos >= 0)?value.substring(pos + 1):value;
        let url = input.src + q;
        if (input.include) {
            url += '&' + pars(input.form, input.include);
        }
        const xhr = input.xhr;
        // abort pendant queries
        xhr.abort();
        xhr.responseType = 'json';
        xhr.open('GET', url);
        xhr.onerror = function() {
            console.error(xhr.status + ": " + url);
        }
        xhr.onload = function() {
            const data = xhr.response;
            suggDiv.innerText = "";
            if (!data.length) return;
            input.suggArray = [];
            input.suggIndex = undefined;
            for (let i = 0; i < data.length; i++) {
                const row = data[i];
                const option = document.createElement('div');
                option.input = input;
                option.index = i;
                option.onmouseover = optionOver;
                option.onmouseout = optionOut;
                option.onmousedown = optionClick;
                option.classList.add("suggest");
                option.classList.add("option");
                option.dataset.word = prefix + row.form;
                option.innerHTML = row.marked + ' <small>(' + row.freq + ', ' + row.hits + ' <span class="document"></span>)</small>';
                suggDiv.appendChild(option);
                input.suggArray[i] = option;
            }
        }
        xhr.send();
    }

    function optionOut(event)
    {
        const option = this;
        const input = option.input;
        if (typeof input.suggIndex !== 'undefined' && input.suggIndex == option.index) {
            input.suggIndex = undefined;
        }
        option.classList.remove("focus");
    }
    
    function optionOver(event)
    {
        const option = this;
        const input = option.input;
        if (typeof input.suggIndex !== 'undefined' && input.suggIndex != option.index) {
            input.suggArray[input.suggIndex].classList.remove("focus");
        }
        input.suggIndex = option.index;
        option.classList.add("focus");
    }

    function optionClick(event)
    {
        const option = this;
        const input = option.input;
        if (typeof input.suggIndex == 'undefined' && input.suggIndex != option.index) {
            input.suggArray[input.suggIndex].classList.remove("focus");
            option.classList.add("focus");
        }
        input.suggIndex = option.index;
        input.value = option.dataset.word;
        event.preventDefault();
        hide(event, input);
        input.form.submit();
    }
    
    function key(event)
    {
        const input = this;
        if (event.key == "Escape") {
            hide(event, input);
        }
        else if (event.key == "ArrowUp" || event.key == "ArrowDown") { // up or down
            if (!input.suggArray) return;
            // unfocus last one
            if (typeof input.suggIndex !== 'undefined') {
                input.suggArray[input.suggIndex].classList.remove("focus");
            }
            if (event.key == "ArrowDown") { // down
                if (typeof input.suggIndex === 'undefined') input.suggIndex = 0;
                else if (input.suggIndex == input.suggArray.length - 1)  input.suggIndex = 0;
                else input.suggIndex++;
            }
            else if (event.key == "ArrowUp") { // up
                if (typeof input.suggIndex === 'undefined') input.suggIndex = input.suggArray.length - 1;
                else if (input.suggIndex === 0) input.suggIndex = input.suggArray.length - 1;
                else input.suggIndex--;
            }
            const option = input.suggArray[input.suggIndex];
            option.classList.add("focus");
            input.value = option.dataset.word;
        } 
        else if (event.key == "Return") { // enter
            // nothing to do
        }
    }
    
    function suggest(input, include) {
        if (!input) {
            console.log("<input> not found.");
            return null;
        }
        if (!input.src) {
            console.log("No data source found (provide an url in the @src attribute of the <input>)" + input);
            return null;
        }
        input.include = include;
        // behaviors
        input.setAttribute('autocomplete', 'off');
        const suggDiv = document.createElement('div');
        suggDiv.style.display = "none";
        input.suggDiv = suggDiv;
        suggDiv.classList.add("suggestions");
        input.parentNode.appendChild(suggDiv);
        
        input.xhr = new XMLHttpRequest();
        input.addEventListener("blur", hide, true);
        input.addEventListener("click", load, true); // value may change with no load
        input.addEventListener("focus", load, true); // value may change with no load
        input.addEventListener("input", load, true);
        input.addEventListener("keydown", key, true);
    }

    return suggest;
}));

