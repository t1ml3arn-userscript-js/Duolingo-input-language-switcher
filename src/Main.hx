package;
import js.lib.Promise;
import js.html.*;
import js.lib.*;
import js.Browser;

using Reflect;

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
        document = Browser.document;
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

        Browser.document.body.addEventListener('keydown', onKeyDown);
    }

    function onKeyDown(e:KeyboardEvent) 
    {
        // NOTE: e.code always represents the QWERTY keyboard key.
        // See more https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code
        
        // if pressed key cannot be switched - do nothing
        var pressedKeyCodeIndex = this.keyCodes.indexOf(e.code);
        if(pressedKeyCodeIndex == -1) return;

        var inputElt:InputElement = cast e.target;
        var challengeType:String = inputElt.dataset.test;
        
        // determine language pair, 
        // i.e language from which to convert to target language
        switch (challengeType)
        {
            case 'challenge-translate-input':

                nativeLanguage = 'ru';
                foreignLanguage = 'en';
                
                var lang = inputElt.getAttribute('lang');
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

            default:    

                // event sender is not an element we are looking for
                return;
        }

        e.preventDefault();
        
        var newLetter = getLanguageLetter(targetLanguage, pressedKeyCodeIndex, e.shiftKey);
        
        this.replaceLetter(inputElt.selectionStart, newLetter, inputElt);
        this.callReactOnChange(inputElt);
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

    function getLanguageLetter(language:String, letterIndex:Int, isUppercase:Bool):String
    {
        var letters = untyped this.languages[language];
        
        if(isUppercase)
            return letters.charAt(letterIndex + this.keyCodes.length);
        else
            return letters.charAt(letterIndex);
    }

    /**
     * Replaces at position `index` one letter for `inputElt.value` by
     * given new `letter`
     * @param index Position to replace
     * @param letter New letter
     * @param inputElt Target input element
     */
    function replaceLetter(index:Int, letter:String, inputElt:InputElement)
    {
        var val = inputElt.value;
        val = val.substring(0, index) + letter + val.substring(index + 1);
        inputElt.value = val;
        inputElt.setSelectionRange(index+1, index+1);
    }

    function callReactOnChange(elt:Element) 
    {
        /* 
        It is needed to force Reach to update state (otherwise nothing will work).
        To do so we find object with name like `__reactInternalInstance$d64zg30yj9p`
        and call its `onChange()`. It is usefull to use React Devtools extension ...
        */
        for(fieldName in elt.fields())
        {
            if(StringTools.contains(fieldName, '__reactEventHandlers'))
            {
                var reactHandler:ReactEventHandlers = elt.field(fieldName);
                reactHandler.onChange({ target: elt});
            }
        }
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

typedef ReactEventHandlers = 
{
    function onChange(e:Dynamic):Void;
}