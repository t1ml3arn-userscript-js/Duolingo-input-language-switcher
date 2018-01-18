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

    function new()
    {
        document = js.Browser.document;
        console = untyped {};
        observer = new MutationObserver(checkMutation);
        // copy original console
        untyped (Object.assign(console, js.Browser.window.console));

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
        // var selector = '._1zuqL';
        var selector = '._1Y5M_';
        var obsTarget = Browser.document.querySelector(selector);
        if(obsTarget==null)
        {
            console.error('There is no Node with selector "$selector" , so nothing to observe ');
            return;
        }
        observer.observe(obsTarget, {childList:true, subtree:true});
        isObserved=true;
    }

    function checkMutation(?records:Array<MutationRecord>,?obs:MutationObserver)
    {
        var noAddedNodes = true;
        console.log(records);
        for(mr in records)
        {
            // console.log('Mutation type: ${mr.type}');
            if(mr.addedNodes.length > 0)
            {
                noAddedNodes = false;
                break;
            }
        }
        if(noAddedNodes)    return;
        
        var foreignLang = 'en';
        var nativeLang = 'ru';
        var translationInput = Browser.document.querySelector('textarea[data-test=challenge-translate-input]');
        if(translationInput != null)
        {
            var lang = translationInput.getAttribute('lang');
            if(lang==nativeLang)
            {
                console.log('Translation to NATIVE input found');
            }
            else if (lang==foreignLang)
            {
                console.log('Translation to FOREIGN input found');
            }
            return;
        }

        var listenInput = Browser.document.querySelector('textarea[data-test=challenge-listen-input]');
        if(listenInput != null)
        {
            console.log('Listen input found');
            return;
        }

        var nameInput = Browser.document.querySelector('input[data-test=challenge-name-input]');
        if(nameInput != null)
        {
            console.log('Name input found');
            return;
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