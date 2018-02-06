// ==UserScript==
// @name Duolingo input language switcher
// @namespace https://www.duolingo.com/IVrL9
// @match https://www.duolingo.com/*
// @match https://www.example.com/*
// @match https://example.com/*
// @version 1.1.2
// @description This script allows you to type letters appropriate for current task without changing keyboard's layout
// @run-at document-start
// @grant none
// @license GPLv3
// @homepageURL https://github.com/T1mL3arn/Duolingo-input-language-switcher
// @supportURL https://greasyfork.org/en/scripts/37693-duolingo-input-language-switcher/feedback
// ==/UserScript==// Generated by Haxe 3.4.2 (git build master @ 890f8c7)
(function() {
    "use strict";
    var HxOverrides = function() {};
    HxOverrides.__name__ = true;
    HxOverrides.substr = function(s, pos, len) {
        if (len == null) {
            len = s.length;
        } else if (len < 0) {
            if (pos == 0) {
                len = s.length + len;
            } else {
                return "";
            }
        }
        return s.substr(pos, len);
    };
    var Main = function() {
        this.observerTargetSelector = "._1zuqL";
        this.ereg = new RegExp("duolingo\\.com/skill|practice");
        this.isObserved = false;
        var _gthis = this;
        this.document = window.document;
        this.console = {};
        Object.assign(this.console, window.console);
        this.originalTrace = haxe_Log.trace;
        haxe_Log.trace = function(v, i) {
            _gthis.console.log("" + i.className + ":" + i.lineNumber + ":", v);
        };
        this.initLanguages();
        if (this.document.readyState == "interactive" || this.document.readyState == "complete") {
            this.onready();
        } else {
            this.document.addEventListener("DOMContentLoaded", $bind(this, this.onready));
        }
    };
    Main.__name__ = true;
    Main.main = function() {
        new Main();
    };
    Main.prototype = {
        initLanguages: function() {
            this.keyCodes = ["Backquote", "Digit1", "Digit2", "Digit3", "Digit4", "Digit5", "Digit6", "Digit7", "Digit8", "Digit9", "Digit0", "Minus", "Equal", "Backslash", "KeyQ", "KeyW", "KeyE", "KeyR", "KeyT", "KeyY", "KeyU", "KeyI", "KeyO", "KeyP", "BracketLeft", "BracketRight", "KeyA", "KeyS", "KeyD", "KeyF", "KeyG", "KeyH", "KeyJ", "KeyK", "KeyL", "Semicolon", "Quote", "KeyZ", "KeyX", "KeyC", "KeyV", "KeyB", "KeyN", "KeyM", "Comma", "Period", "Slash"];
            this.languages = {};
            this.languages.ru = "ё1234567890-=\\йцукенгшщзхъфывапролджэячсмитьбю.Ё!\"№;%:?*()_+/ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,";
            this.languages.en = "`1234567890-=\\qwertyuiop[]asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+|QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?";
            var len = this.languages.ru.length;
            var _g = 0;
            var _g1 = Reflect.fields(this.languages);
            while (_g < _g1.length) {
                var f = _g1[_g];
                ++_g;
                var act = this.languages[f].length;
                if (act != len) {
                    this.console.error("LangString test failed: expected len " + len + "; actual len " + act + "; lang name " + f);
                    this.console.error(this.languages[f]);
                    return;
                }
                if (act != this.keyCodes.length * 2) {
                    this.console.error("KeyCodes and LangString test failed: expected lang string len " + this.keyCodes.length * 2 + "; actual len " + act + "; lang name " + f);
                    return;
                }
            }
        },
        onready: function(e) {
            this.document.removeEventListener("DOMContentLoaded", $bind(this, this.onready));
            this.console.log("Duolingo input switcher inited");
            window.setInterval($bind(this, this.checkPage), 1000);
        },
        checkPage: function() {
            var isThatPage = this.ereg.test(window.location.href);
            if (isThatPage) {
                if (!this.isObserved) {
                    this.startObserver();
                }
            }
            if (this.isObserved && (!isThatPage || window.document.querySelector(this.observerTargetSelector) == null)) {
                this.disconnectObserver();
            }
        },
        startObserver: function(e) {
            var obsTarget = window.document.querySelector(this.observerTargetSelector);
            if (obsTarget == null) {
                this.console.error("There is no Node with selector \"" + this.observerTargetSelector + "\" , so nothing to observe ");
                return;
            }
            this.observer = new MutationObserver($bind(this, this.checkMutation));
            this.observer.observe(obsTarget, { childList: true, subtree: true, attributes: true });
            this.isObserved = true;
        },
        disconnectObserver: function() {
            this.isObserved = false;
            if (this.observer == null) {
                return;
            }
            this.observer.disconnect();
        },
        checkMutation: function(records, obs) {
            this.nativeLanguage = "ru";
            this.foreignLanguage = "en";
            var translationInput = window.document.querySelector("textarea[data-test=challenge-translate-input]");
            if (translationInput != null) {
                var lang = translationInput.getAttribute("lang");
                if (lang == this.nativeLanguage) {
                    this.initInput(translationInput, "ru", "en");
                } else if (lang == this.foreignLanguage) {
                    this.initInput(translationInput, "en", "ru");
                }
                return;
            }
            var listenInput = window.document.querySelector("textarea[data-test=challenge-listen-input]");
            if (listenInput != null) {
                this.initInput(listenInput, "en", "ru");
                return;
            }
            var nameInput = window.document.querySelector("input[data-test=challenge-name-input]");
            if (nameInput != null) {
                this.initInput(nameInput, "en", "ru");
            }
        },
        initInput: function(input, targetLanguage, sourceLanguage) {
            this.targetLanguage = targetLanguage;
            this.sourceLanguage = sourceLanguage;
            input.addEventListener("keypress", $bind(this, this.onInput));
            input.addEventListener("keydown", $bind(this, this.refocus));
        },
        refocus: function(e) {
            if (e.keyCode == 13 || e.code == "Enter") {
                e.currentTarget.blur();
            }
        },
        onInput: function(e) {
            if (e.ctrlKey) {
                return;
            }
            var targetLangStr = this.languages[this.targetLanguage];
            var keyCodeInd = this.keyCodes.indexOf(e.code);
            if (keyCodeInd != -1) {
                var targetChar = e.shiftKey ? targetLangStr.charAt(keyCodeInd + this.keyCodes.length) : targetLangStr.charAt(keyCodeInd);
                var input = e.currentTarget;
                window.setTimeout($bind(this, this.replaceChar), 1, input, targetChar, input.selectionStart);
            }
        },
        replaceChar: function(target, newChar, position) {
            var val = target.value;
            val = val.substring(0, position) + newChar + HxOverrides.substr(val, position + 1, null);
            target.innerText = val;
            target.value = val;
            target.setSelectionRange(position + 1, position + 1);
        }
    };
    Math.__name__ = true;
    var Reflect = function() {};
    Reflect.__name__ = true;
    Reflect.fields = function(o) {
        var a = [];
        if (o != null) {
            var hasOwnProperty = Object.prototype.hasOwnProperty;
            for (var f in o) {
                if (f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o, f)) {
                    a.push(f);
                }
            }
        }
        return a;
    };
    var haxe_Log = function() {};
    haxe_Log.__name__ = true;
    haxe_Log.trace = function(v, infos) {
        js_Boot.__trace(v, infos);
    };
    var js_Boot = function() {};
    js_Boot.__name__ = true;
    js_Boot.__unhtml = function(s) {
        return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
    };
    js_Boot.__trace = function(v, i) {
        var msg = i != null ? i.fileName + ":" + i.lineNumber + ": " : "";
        msg += js_Boot.__string_rec(v, "");
        if (i != null && i.customParams != null) {
            var _g = 0;
            var _g1 = i.customParams;
            while (_g < _g1.length) {
                var v1 = _g1[_g];
                ++_g;
                msg += "," + js_Boot.__string_rec(v1, "");
            }
        }
        var d;
        var tmp;
        if (typeof(document) != "undefined") {
            d = document.getElementById("haxe:trace");
            tmp = d != null;
        } else {
            tmp = false;
        }
        if (tmp) {
            d.innerHTML += js_Boot.__unhtml(msg) + "<br/>";
        } else if (typeof console != "undefined" && console.log != null) {
            console.log(msg);
        }
    };
    js_Boot.__string_rec = function(o, s) {
        if (o == null) {
            return "null";
        }
        if (s.length >= 5) {
            return "<...>";
        }
        var t = typeof(o);
        if (t == "function" && (o.__name__ || o.__ename__)) {
            t = "object";
        }
        switch (t) {
            case "function":
                return "<function>";
            case "object":
                if (o instanceof Array) {
                    if (o.__enum__) {
                        if (o.length == 2) {
                            return o[0];
                        }
                        var str = o[0] + "(";
                        s += "\t";
                        var _g1 = 2;
                        var _g = o.length;
                        while (_g1 < _g) {
                            var i = _g1++;
                            if (i != 2) {
                                str += "," + js_Boot.__string_rec(o[i], s);
                            } else {
                                str += js_Boot.__string_rec(o[i], s);
                            }
                        }
                        return str + ")";
                    }
                    var l = o.length;
                    var i1;
                    var str1 = "[";
                    s += "\t";
                    var _g11 = 0;
                    var _g2 = l;
                    while (_g11 < _g2) {
                        var i2 = _g11++;
                        str1 += (i2 > 0 ? "," : "") + js_Boot.__string_rec(o[i2], s);
                    }
                    str1 += "]";
                    return str1;
                }
                var tostr;
                try {
                    tostr = o.toString;
                } catch (e) {
                    return "???";
                }
                if (tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
                    var s2 = o.toString();
                    if (s2 != "[object Object]") {
                        return s2;
                    }
                }
                var k = null;
                var str2 = "{\n";
                s += "\t";
                var hasp = o.hasOwnProperty != null;
                for (var k in o) {
                    if (hasp && !o.hasOwnProperty(k)) {
                        continue;
                    }
                    if (k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
                        continue;
                    }
                    if (str2.length != 2) {
                        str2 += ", \n";
                    }
                    str2 += s + k + " : " + js_Boot.__string_rec(o[k], s);
                }
                s = s.substring(1);
                str2 += "\n" + s + "}";
                return str2;
            case "string":
                return o;
            default:
                return String(o);
        }
    };
    var $_, $fid = 0;

    function $bind(o, m) { if (m == null) return null; if (m.__id__ == null) m.__id__ = $fid++; var f; if (o.hx__closures__ == null) o.hx__closures__ = {};
        else f = o.hx__closures__[m.__id__]; if (f == null) { f = function() { return f.method.apply(f.scope, arguments); };
            f.scope = o;
            f.method = m;
            o.hx__closures__[m.__id__] = f; } return f; }
    String.__name__ = true;
    Array.__name__ = true;
    Main.main();
})();