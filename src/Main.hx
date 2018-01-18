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
    var ereg:EReg = ~/duolingo.com\/skill|practice/;
    var languages:Dynamic;
    var nativeLanguage:String;
    var foreignLanguage:String;
    var targetLanguage:String;
    var sourceLanguage:String;
    var originalTrace:Dynamic;

    function new()
    {
        document = js.Browser.document;
        console = untyped {};
        observer = new MutationObserver(checkMutation);

        // copy original console
        untyped (Object.assign(console, js.Browser.window.console));
        originalTrace = haxe.Log.trace; 
        haxe.Log.trace = function(v,?i)console.log('${i.className}:${i.lineNumber} : ', v);

        // don/t forget about numpad coma!
        languages = {};
        // languages.ru = 'ё1234567890-=\\йцукенгшщзхъфывапролджэячсмитьбю.Ё!"№;%:?*()_+/ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,,';
        // languages.en = '`1234567890-=\\qwertyuiop[]asdfghjkl;\'zxcvbnm,./~!@#$%^&*()_+|QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?.';
        languages.ru = 'ёйцукенгшщзхъфывапролджэячсмитьбю.ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,';
        languages.en = '`qwertyuiop[]asdfghjkl;\'zxcvbnm,./~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>?';

        // test
        var len = languages.ru.length;
        for(f in Reflect.fields(languages))
        {
            var act = Reflect.field(languages, f).length; 
            if (act != len)
            {
                console.error('Language test failed: expected len $len; actual len $act; lang name $f');
                console.error(Reflect.field(languages, f));
                return;
            }
        }

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

    function onready(?e)
    {
        document.removeEventListener('DOMContentLoaded', onready);
        console.log("Duolingo input switcher inited");

        var t = new haxe.Timer(1000);
        t.run = checkPage;
    }
    
    function checkPage()
    {
        if(ereg.match(Browser.window.location.href))
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
            
            // order of events
            // keydown
            // keypress
            // input
            translationInput.addEventListener('keypress',onInput);
            return;
        }

        var listenInput = Browser.document.querySelector('textarea[data-test=challenge-listen-input]');
        if(listenInput != null)
        {
            // console.log('Listen input found');
            targetLanguage = 'en';
            sourceLanguage = 'ru';
            listenInput.addEventListener('keypress',onInput);
            return;
        }

        var nameInput = Browser.document.querySelector('input[data-test=challenge-name-input]');
        if(nameInput != null)
        {
            // console.log('Name input found');
            targetLanguage = 'en';
            sourceLanguage = 'ru';
            nameInput.addEventListener('keydown',onInput);
            return;
        }
    }

    function onInput(e:KeyboardEvent)
    {
        console.log(e.type, e.key,e.keyCode,e.charCode,untyped e.code);
        
        var target:String = cast Reflect.field(languages, targetLanguage);
        var source:String = cast Reflect.field(languages, sourceLanguage);

        // current symbol is TARGET language - do nothing
        if(target.indexOf(e.key)!=-1)
            return;
        var sourceInd = source.indexOf(e.key);
        if (sourceInd!=-1)
        {
            // current symbol is in source, need to translate
            var input:Element = cast e.currentTarget;
            var targetChar = target.charAt(sourceInd);
            e.preventDefault();
            untyped input.value += targetChar;
            // trace('replace ${e.key} on ${targetChar}');
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
        // return 'ru';
    }

    function getForeignLanguage():Promise<String>
    {
        // to do ?
        return Promise.resolve('en');
        // return 'en';
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