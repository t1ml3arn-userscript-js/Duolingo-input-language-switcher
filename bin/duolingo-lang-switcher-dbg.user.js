// ==UserScript==
// @name Duolingo input language switcher
// @namespace https://www.duolingo.com/IVrL9
// @author T1mL3arn
// @match https://www.duolingo.com/*
// @match https://*.duolingo.com/*
// @version 3.0.1
// @description This script allows you to type letters appropriate for current challenge without changing keyboard layout. Similar to Punto Switcher.
// @description:ru Скрипт дает возможность выполнять упражнения не отвлекаясь на переключение раскладки клавиатуры. Похоже на Punto Switcher.
// @run-at document-start
// @grant none
// @icon https://www.androidpolice.com/wp-content/uploads/2014/03/nexusae0_Duolingo-Thumb.png
// @license GPL-3.0-only
// @homepageURL https://github.com/T1mL3arn/Duolingo-input-language-switcher
// @supportURL https://greasyfork.org/en/scripts/37693-duolingo-input-language-switcher/feedback
// ==/UserScript==

(function ($global) { "use strict";
var Lambda = function() { };
Lambda.__name__ = true;
Lambda.find = function(it,f) {
	var v = $getIterator(it);
	while(v.hasNext()) {
		var v1 = v.next();
		if(f(v1)) {
			return v1;
		}
	}
	return null;
};
var Main = function() {
	this.CHALLENGE_TYPES = ["listen_complete","complete_reverse_translation","reverse_translate","partial_reverse_translate","reverse_tap","listen","tap","name","listen_tap"];
	var _gthis = this;
	this.document = window.document;
	this.console = $global.console;
	this.console = { };
	Object.assign(this.console,window.console);
	this.originalTrace = haxe_Log.trace;
	haxe_Log.trace = function(v,infos) {
		var out = haxe_Log.formatOutput(v,infos);
		_gthis.console.log(out);
	};
	this.initLanguages();
	if(this.document.readyState == "interactive" || this.document.readyState == "complete") {
		this.onready();
	} else {
		this.document.addEventListener("DOMContentLoaded",$bind(this,this.onready));
	}
};
Main.__name__ = true;
Main.main = function() {
	new Main();
};
Main.prototype = {
	initLanguages: function() {
		this.keyCodes = ["Backquote","Digit1","Digit2","Digit3","Digit4","Digit5","Digit6","Digit7","Digit8","Digit9","Digit0","Minus","Equal","Backslash","KeyQ","KeyW","KeyE","KeyR","KeyT","KeyY","KeyU","KeyI","KeyO","KeyP","BracketLeft","BracketRight","KeyA","KeyS","KeyD","KeyF","KeyG","KeyH","KeyJ","KeyK","KeyL","Semicolon","Quote","KeyZ","KeyX","KeyC","KeyV","KeyB","KeyN","KeyM","Comma","Period","Slash"];
		this.languages = { };
		this.languages.ru = "ё1234567890-=\\йцукенгшщзхъфывапролджэячсмитьбю.Ё!\"№;%:?*()_+/ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,";
		this.languages.en = "`1234567890-=\\qwertyuiop[]asdfghjkl;'zxcvbnm,./~!@#$%^&*()_+|QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>?";
		var len = this.languages.ru.length;
		var _g = 0;
		var _g1 = Reflect.fields(this.languages);
		while(_g < _g1.length) {
			var f = _g1[_g];
			++_g;
			var act = this.languages[f].length;
			if(act != len) {
				this.console.error("LangString test failed: expected len " + len + "; actual len " + act + "; lang name " + f);
				this.console.error(this.languages[f]);
				return;
			}
			if(act != this.keyCodes.length * 2) {
				this.console.error("KeyCodes and LangString test failed: expected lang string len " + this.keyCodes.length * 2 + "; actual len " + act + "; lang name " + f);
				return;
			}
		}
	}
	,onready: function(e) {
		var _gthis = this;
		this.document.removeEventListener("DOMContentLoaded",$bind(this,this.onready));
		var mode = " [ DEBUG MODE ]";
		this.console.log("Duolingo input switcher is ready" + mode);
		window.document.body.addEventListener("keydown",$bind(this,this.onKeyDown));
		new MutationObserver(function(changes) {
			var path = window.location.pathname;
			var isPracticePage = StringTools.startsWith(path,"/practice") || StringTools.startsWith(path,"/lesson");
			var someAdded = Lambda.find(changes,function(c) {
				return c.addedNodes.length > 0;
			}) != null;
			if(isPracticePage && someAdded) {
				var elt = _gthis.document.querySelector("._3x0ok");
				if(elt == null) {
					_gthis.console.log("Not a practice page, reset current challenge");
					_gthis.currentChallengeType = null;
					return;
				}
				var props = _gthis.getReactProps(elt);
				_gthis.challenge = props.children[0]._owner.stateNode.props.currentChallenge;
				if(_gthis.challenge == null) {
					_gthis.console.log("Not a practice page, reset current challenge");
					_gthis.currentChallengeType = null;
					return;
				}
				var sourcelang = _gthis.challenge.metadata.source_language;
				var targetlang = _gthis.challenge.metadata.target_language;
				var specType = _gthis.challenge.metadata.specific_type;
				var genType = _gthis.challenge.metadata.type;
				_gthis.sourceLanguage = sourcelang;
				_gthis.targetLanguage = targetlang != null ? targetlang : sourcelang;
				_gthis.currentChallengeType = specType;
				_gthis.console.log(specType,sourcelang,targetlang,genType);
			}
		}).observe(this.document.body,{ childList : true, subtree : true});
	}
	,getReactProps: function(elt) {
		var _g = 0;
		var _g1 = Reflect.fields(elt);
		while(_g < _g1.length) {
			var propName = _g1[_g];
			++_g;
			if(StringTools.startsWith(propName,"__reactProps")) {
				return Reflect.field(elt,propName);
			}
		}
		return null;
	}
	,onKeyDown: function(e) {
		if(this.currentChallengeType == null) {
			return;
		}
		if(e.ctrlKey) {
			return;
		}
		var pressedKeyCodeIndex = this.keyCodes.indexOf(e.code);
		if(pressedKeyCodeIndex == -1) {
			return;
		}
		if(this.CHALLENGE_TYPES.indexOf(this.currentChallengeType) == -1) {
			return;
		}
		var elt = e.target;
		if(!(elt.hasAttribute("contenteditable") || elt.tagName == "INPUT" || elt.tagName == "TEXTAREA")) {
			return;
		}
		e.preventDefault();
		this.replaceLetter(this.getLanguageLetter(this.targetLanguage,pressedKeyCodeIndex,e.shiftKey),elt);
	}
	,getLanguageLetter: function(language,letterIndex,isUppercase) {
		var letters = this.languages[language];
		if(isUppercase) {
			return letters.charAt(letterIndex + this.keyCodes.length);
		} else {
			return letters.charAt(letterIndex);
		}
	}
	,replaceLetter: function(letter,elt) {
		switch(elt.tagName) {
		case "SPAN":
			var s = window.getSelection();
			if(s.anchorNode != s.focusNode) {
				return false;
			}
			var start = s.anchorOffset;
			var end = s.focusOffset;
			var text = s.anchorNode.textContent;
			if(start != end) {
				s.deleteFromDocument();
			}
			start = s.anchorOffset;
			end = s.focusOffset;
			elt.textContent = text.substring(0,start) + letter + text.substring(end);
			elt.dispatchEvent(new InputEvent("input",{ bubbles : true}));
			s.collapse(elt.childNodes[0],start + 1);
			return true;
		case "INPUT":case "TEXTAREA":
			var elt1 = elt;
			var start = elt1.selectionStart;
			var phrase = elt1.value;
			phrase = phrase.substring(0,start) + letter + phrase.substring(elt1.selectionEnd);
			elt1.value = phrase;
			elt1.setSelectionRange(start + 1,start + 1);
			this.callReactEventHandler(elt1,"onChange",{ type : "change", target : elt1});
			return true;
		default:
			return false;
		}
	}
	,callReactEventHandler: function(elt,methodName,event) {
		var _g = 0;
		var _g1 = Reflect.fields(elt);
		while(_g < _g1.length) {
			var fieldName = _g1[_g];
			++_g;
			if(fieldName.indexOf("__reactProps") != -1) {
				var reactProps = Reflect.field(elt,fieldName);
				reactProps[methodName](event);
				return;
			}
		}
		this.console.error("Cannot find react " + methodName + " handler on",elt);
	}
};
Math.__name__ = true;
var Reflect = function() { };
Reflect.__name__ = true;
Reflect.field = function(o,field) {
	try {
		return o[field];
	} catch( _g ) {
		return null;
	}
};
Reflect.fields = function(o) {
	var a = [];
	if(o != null) {
		var hasOwnProperty = Object.prototype.hasOwnProperty;
		for( var f in o ) {
		if(f != "__id__" && f != "hx__closures__" && hasOwnProperty.call(o,f)) {
			a.push(f);
		}
		}
	}
	return a;
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
var StringTools = function() { };
StringTools.__name__ = true;
StringTools.startsWith = function(s,start) {
	if(s.length >= start.length) {
		return s.lastIndexOf(start,0) == 0;
	} else {
		return false;
	}
};
var haxe_Log = function() { };
haxe_Log.__name__ = true;
haxe_Log.formatOutput = function(v,infos) {
	var str = Std.string(v);
	if(infos == null) {
		return str;
	}
	var pstr = infos.fileName + ":" + infos.lineNumber;
	if(infos.customParams != null) {
		var _g = 0;
		var _g1 = infos.customParams;
		while(_g < _g1.length) str += ", " + Std.string(_g1[_g++]);
	}
	return pstr + ": " + str;
};
haxe_Log.trace = function(v,infos) {
	var str = haxe_Log.formatOutput(v,infos);
	if(typeof(console) != "undefined" && console.log != null) {
		console.log(str);
	}
};
var haxe_iterators_ArrayIterator = function(array) {
	this.current = 0;
	this.array = array;
};
haxe_iterators_ArrayIterator.__name__ = true;
haxe_iterators_ArrayIterator.prototype = {
	hasNext: function() {
		return this.current < this.array.length;
	}
	,next: function() {
		return this.array[this.current++];
	}
};
var js_Boot = function() { };
js_Boot.__name__ = true;
js_Boot.__string_rec = function(o,s) {
	if(o == null) {
		return "null";
	}
	if(s.length >= 5) {
		return "<...>";
	}
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) {
		t = "object";
	}
	switch(t) {
	case "function":
		return "<function>";
	case "object":
		if(((o) instanceof Array)) {
			var str = "[";
			s += "\t";
			var _g = 0;
			var _g1 = o.length;
			while(_g < _g1) {
				var i = _g++;
				str += (i > 0 ? "," : "") + js_Boot.__string_rec(o[i],s);
			}
			str += "]";
			return str;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( _g ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") {
				return s2;
			}
		}
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		var k = null;
		for( k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) {
			str += ", \n";
		}
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "string":
		return o;
	default:
		return String(o);
	}
};
function $getIterator(o) { if( o instanceof Array ) return new haxe_iterators_ArrayIterator(o); else return o.iterator(); }
var $_;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $global.$haxeUID++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = m.bind(o); o.hx__closures__[m.__id__] = f; } return f; }
$global.$haxeUID |= 0;
String.__name__ = true;
Array.__name__ = true;
js_Boot.__toStr = ({ }).toString;
Main.main();
})(typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);
