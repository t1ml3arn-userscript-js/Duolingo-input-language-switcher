package;
import js.Promise;
import js.html.*;
import js.*;

class Main {
    static function main() {
        new Main();
    }

    var console:js.html.Console;
    var document:js.html.Document;
    var observer:MutationObserver;
    var isObserved:Bool = false;
    var ereg:js.RegExp = new js.RegExp('duolingo\\.com/skill|practice/');
    var languages:Dynamic;
    var nativeLanguage:String;
    var foreignLanguage:String;
    var targetLanguage:String;
    var sourceLanguage:String;
    var originalTrace:Dynamic;
    var keyCodes:Array<String>;

    function new()
    {
        document = js.Browser.document;
        console = untyped {};
        observer = new MutationObserver(checkMutation);

        // copy original console
        untyped (Object.assign(console, js.Browser.window.console));
        originalTrace = haxe.Log.trace; 
        haxe.Log.trace = function(v,?i)console.log('${i.className}:${i.lineNumber}:', v);

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
            var act:Int = Reflect.field(languages, f).length; 
            if (act != len)
            {
                console.error('LangString test failed: expected len $len; actual len $act; lang name $f');
                console.error(Reflect.field(languages, f));
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
        console.log("Duolingo input switcher inited");

        var t = new haxe.Timer(1000);
        t.run = checkPage;
    }
    
    function checkPage()
    {
        if(ereg.test(Browser.window.location.href))
        {
            if(!isObserved)
                startObserver();
        }
        else
        {
            isObserved = false;
            observer.disconnect();
        }
    }

    function startObserver(?e)
    {
        var selector = '._1zuqL';
        var obsTarget = Browser.document.querySelector(selector);
        if(obsTarget==null)
        {
            console.error('There is no Node with selector "$selector" , so nothing to observe ');
            return;
        }
        observer.observe(obsTarget, {childList:true, subtree:true, attributes:true});
        isObserved=true;
    }

    function checkMutation(?records:Array<MutationRecord>,?obs:MutationObserver)
    {   
        ///TODO Можно заменить мутации на обычный инпут ?
        // т.е. body слушает инпут 

        // console.log(records);

        nativeLanguage = 'ru';
        foreignLanguage = 'en';

        var translationInput = Browser.document.querySelector('textarea[data-test=challenge-translate-input]');
        
        if(translationInput != null)
        {
            var lang = translationInput.getAttribute('lang');
            if(lang==nativeLanguage)
            {
                // console.log('Translation to NATIVE input found');
                targetLanguage = 'ru';
                sourceLanguage = 'en';
            }
            else if (lang==foreignLanguage)
            {
                // console.log('Translation to FOREIGN input found');
                targetLanguage = 'en';
                sourceLanguage = 'ru';
            }
            
            // order of events: keydown, keypress, input
            translationInput.addEventListener('keypress', onInput);
            translationInput.addEventListener('keydown', refocus);
            return;
        }

        var listenInput = Browser.document.querySelector('textarea[data-test=challenge-listen-input]');
        if(listenInput != null)
        {
            // console.log('Listen input found');
            targetLanguage = 'en';
            sourceLanguage = 'ru';
            listenInput.addEventListener('keypress', onInput);
            listenInput.addEventListener('keydown', refocus);
            return;
        }

        var nameInput = Browser.document.querySelector('input[data-test=challenge-name-input]');
        if(nameInput != null)
        {
            // console.log('Name input found');
            targetLanguage = 'en';
            sourceLanguage = 'ru';
            nameInput.addEventListener('keypress',onInput);
            nameInput.addEventListener('keydown',refocus);
            return;
        }
    }

    function refocus(?e:KeyboardEvent)
    {
        if(e.keyCode==13)
            untyped e.currentTarget.blur();
    }

    function onInput(e:KeyboardEvent)
    {    
        console.log(e.type, e.key,e.keyCode,e.charCode,untyped e.code);
        
        var targetLangStr:String = cast Reflect.field(languages, targetLanguage);
        var sourceLangStr:String = cast Reflect.field(languages, sourceLanguage);
        
        var sourceInd = sourceLangStr.indexOf(e.key);
        if (sourceInd!=-1)
        {
            // current symbol is in source, need to translate
            var targetChar = targetLangStr.charAt(sourceInd);
            var input:Dynamic = e.currentTarget;
            Browser.window.setTimeout(replaceChar,1, input,targetChar,input.selectionStart);
        }
    }

    function replaceChar(target:TextAreaElement, newChar:String, position)
    {
        // position--;
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

@:forward
abstract Observer(MutationObserver) from MutationObserver to MutationObserver
{
    public var target(get,set):Node;
    inline function get_target():Node return untyped this.target;
    inline function set_target(v:Node):Node return untyped this.target = v;

    public function observe(t,o)
    {
        target = t;
        this.observe(t,o);
    }
}