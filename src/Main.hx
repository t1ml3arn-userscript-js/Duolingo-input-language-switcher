package;
import js.Promise;
import js.html.*;
import js.*;

class Main {
    static function main() {
        new Main();
    }

    var console:ConsoleInstance;
    var document:js.html.Document;
    var languages:Dynamic;
    var nativeLanguage:String;
    var foreignLanguage:String;
    var targetLanguage:String;
    var sourceLanguage:String;
    var originalTrace:Dynamic;
    /** The list of all the valid keycodes which can be automatically switched. */
    var keyCodes:Array<String>;

    function new()
    {
        document = js.Browser.document;
        console = Browser.console;

        #if debug
        // copy original console
        console = untyped {};
        untyped (Object.assign(console, js.Browser.window.console));
        originalTrace = haxe.Log.trace;
        haxe.Log.trace = function(v,?infos) {
            var out = haxe.Log.formatOutput(v, infos);
            console.log(out);
        }
        #end
        
        initLanguages();
        
    /*
        run-at states:

        document_start == Document.readyState is "loading" == ... ?
        document_end == Document.readyState is "interactive" == "DOMContentLoaded" event fired
        document_idle == Document.readyState is "complete" == document "load" event fired

    */

        if(document.readyState == 'interactive' || document.readyState == 'complete')
            onready();
        else
            document.addEventListener('DOMContentLoaded', onready);
    }

    function initLanguages()
    {
        // code to build array of key codes
        // https://jsfiddle.net/efc0nj5f/

        // all possible key code values
        keyCodes = ['Backquote', 'Digit1', 'Digit2', 'Digit3', 'Digit4', 'Digit5', 'Digit6', 'Digit7', 'Digit8', 'Digit9', 'Digit0', 'Minus', 'Equal', 'Backslash', 'KeyQ', 'KeyW', 'KeyE', 'KeyR', 'KeyT', 'KeyY', 'KeyU', 'KeyI', 'KeyO', 'KeyP', 'BracketLeft', 'BracketRight', 'KeyA', 'KeyS', 'KeyD', 'KeyF', 'KeyG', 'KeyH', 'KeyJ', 'KeyK', 'KeyL', 'Semicolon', 'Quote', 'KeyZ', 'KeyX', 'KeyC', 'KeyV', 'KeyB', 'KeyN', 'KeyM', 'Comma', 'Period', 'Slash'];

        // don/t forget about numpad coma!
        languages = {};
        languages.ru = 'ё1234567890-=\\йцукенгшщзхъфывапролджэячсмитьбю.Ё!"№;%:?*()_+/ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,';
        languages.en = '`1234567890-=\\qwertyuiop[]asdfghjkl;\'zxcvbnm,./~!@#$%^&*()_+|QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?';

        // test
        var len:Int = languages.ru.length;
        for(f in Reflect.fields(languages))
        {
            var act:Int = untyped languages[f].length; 
            if (act != len)
            {
                console.error('LangString test failed: expected len $len; actual len $act; lang name $f');
                console.error(untyped languages[f]);
                return;
            }
            if(act != keyCodes.length*2)
            {
                console.error('KeyCodes and LangString test failed: expected lang string len ${keyCodes.length*2}; actual len $act; lang name $f');
                return;
            }
        }
    }

    function onready(?e)
    {
        document.removeEventListener('DOMContentLoaded', onready);
        var mode = #if debug " [ DEBUG MODE ]" #else "" #end;
        console.log('Duolingo input switcher is ready$mode');
        
        Browser.document.body.addEventListener('keypress', onKeyPress);
        Browser.document.body.addEventListener('keydown', refocus);
    }
    
    function onKeyPress(e:KeyboardEvent)
    {
        if(e.ctrlKey)
            return;
            
        var sourceElt:Element = cast e.target;
        if(isInput(sourceElt))
        {
            var challengeType:String = sourceElt.dataset.test;
            switch (challengeType)
            {
                case 'challenge-translate-input':

                    nativeLanguage = 'ru';
                    foreignLanguage = 'en';
                    
                    var lang = sourceElt.getAttribute('lang');
                    if(lang==nativeLanguage)
                    {
                        // trace('Translation to NATIVE input found');
                        setLanguagePair('ru', 'en');
                    }
                    else if (lang==foreignLanguage)
                    {
                        // trace('Translation to FOREIGN input found');
                        setLanguagePair('en', 'ru');
                    }

                case 'challenge-listen-input', 'challenge-name-input', 'challenge-listentap-input':

                    // trace('Listen or name input found');
                    setLanguagePair('en', 'ru');

                case 'challenge-text-input':

                    setLanguagePair('en', 'ru');

                default:    return;
            }
            
            var targetLangStr:String = untyped languages[targetLanguage];
            
            var keyCodeInd = keyCodes.indexOf(untyped e.code);
            if(keyCodeInd != -1)
            {
                // current symbol is in source, need to translate
                var targetChar = e.shiftKey ? targetLangStr.charAt(keyCodeInd+keyCodes.length) : targetLangStr.charAt(keyCodeInd);
                var input:Dynamic = sourceElt;
                Browser.window.setTimeout(replaceChar,1, input,targetChar,input.selectionStart);
            }
        }
    }

    function isInput(elt:Element):Bool
    {
        return elt.tagName == 'TEXTAREA' || (elt.tagName == 'INPUT' && elt.getAttribute('type') == 'text');
    }

    function setLanguagePair(target:String, source:String)
    {
        this.targetLanguage = target;
        this.sourceLanguage = source;
    }

    function refocus(e:KeyboardEvent)
    {
        if(isInput(cast e.target))
        if(e.keyCode==13||untyped e.code == "Enter")
            untyped e.target.blur();
    }

    function replaceChar(target:InputElement, newChar:String, position)
    {
        var val = target.value;
        val = val.substring(0, position)+newChar+val.substr(position+1);
        target.innerText = val; 
        target.value = val;
        target.setSelectionRange(position+1,position+1);
    }

    function getUserLanguage():Promise<String>
    {
        // query to get data from duolingo,
        // includes user's lang as"fromLanguage" and
        // learning lang as "learningLanguage" 
        // 'https://www.duolingo.com/2017-06-30/users/331083510?fields=adsEnabled,bio,blockedUserIds,canUseModerationTools,courses,creationDate,currentCourse,email,emailAnnouncement,emailAssignment,emailAssignmentComplete,emailClassroomJoin,emailClassroomLeave,emailComment,emailEditSuggested,emailFollow,emailPass,emailWeeklyProgressReport,emailSchoolsAnnouncement,emailStreamPost,emailVerified,emailWeeklyReport,enableMicrophone,enableSoundEffects,enableSpeaker,experiments,facebookId,fromLanguage,globalAmbassadorStatus,googleId,hasPlus,id,joinedClassroomIds,learningLanguage,lingots,location,monthlyXp,name,observedClassroomIds,persistentNotifications,picture,plusDiscounts,practiceReminderSettings,privacySettings,roles,streak,timezone,timezoneOffset,totalXp,trackingProperties,username,webNotificationIds,weeklyXp,xpGains,xpGoal,zhTw,_achievements&_=1516251889761'

        // var request = new haxe.Http('https://www.duolingo.com/?fields=fromLanguage');
        // to do ?
        return Promise.resolve('ru');
    }

    function getForeignLanguage():Promise<String>
    {
        // to do ?
        return Promise.resolve('en');
    }
}