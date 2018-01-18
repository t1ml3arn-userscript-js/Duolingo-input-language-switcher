package;
import js.Promise;
import js.html.*;

class Main {
    static function main() {
        new Main();
    }

    var console:js.html.Console;
    var document:js.html.Document;

    function new()
    {
        document = js.Browser.document;
        console = untyped {};

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

        var selector = '._1zuqL';
        var obsTarget = document.querySelector(selector);
        if(obsTarget==null)
        {
            console.error('There is no Node with selector "$selector" , so nothing to observe ');
            return;
        }

        var obsInit = {childList:true, subtree:true};
        var obs = new MutationObserver(checkMutation);
        obs.observe(obsTarget, obsInit);
    }

    function checkMutation(records:Array<MutationRecord>,obs:MutationObserver)
    {
        console.log(records);
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
