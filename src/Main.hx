package;
import js.lib.Promise;
import js.html.*;
import js.lib.*;
import js.Browser;

using Reflect;

typedef DuoChallenge = 
{
    var metadata:DuoChallengeMeta;
}

typedef DuoChallengeMeta = 
{
    var source_language:String;
    var target_language:String;
    var type:String;
    var specific_type:String;
}

class Main {
    static function main() {
        new Main();
    }

    final CHALLENGE_TYPES = [
        'listen_complete', 
        'complete_reverse_translation', 
        'reverse_translate',
        'partial_reverse_translate',
        'reverse_tap',
        'listen',
        'tap',
        'name',
        'listen_tap',
    ];

    var console:ConsoleInstance;
    var document:js.html.Document;
    var languages:Dynamic;
    var targetLanguage:String;
    var sourceLanguage:String;
    var originalTrace:Dynamic;
    /** The list of all the valid keycodes which can be automatically switched. */
    var keyCodes:Array<String>;
    var challenge:DuoChallenge;
    var currentChallengeType:String;

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

        new MutationObserver(cast changes -> {
            var path = Browser.window.location.pathname;
            var isPracticePage = StringTools.startsWith(path, '/practice') || StringTools.startsWith(path, '/lesson');
            var someAdded = Lambda.find(changes, c -> c.addedNodes.length > 0) != null;

            if(isPracticePage && someAdded)
            {
                var elt = document.querySelector('._3x0ok');
                if(elt == null)
                {
                    console.log('Not a practice page, reset current challenge');
                    currentChallengeType = null;
                    return;
                }

                var props = getReactProps(elt);
                // The way to get desired react data was inspired by this
                // https://greasyfork.org/en/scripts/451185-new-duolingo-cheat-duohacker-works-duolingo-automation/code
                // script.
                challenge = untyped props.children[0]._owner.stateNode.props.currentChallenge;
                if(challenge == null)
                {
                    console.log('Not a practice page, reset current challenge');
                    currentChallengeType = null;
                    return;
                }

                var sourcelang = challenge.metadata.source_language;
                var targetlang = challenge.metadata.target_language;
                var specType = challenge.metadata.specific_type;
                var genType = challenge.metadata.type;

                // setLanguagePair(targetlang, sourcelang);
                this.sourceLanguage = sourcelang;
                this.targetLanguage = targetlang != null ? targetlang : sourcelang;
                this.currentChallengeType = specType;

                console.log(specType, sourcelang, targetlang, genType);
            /*
                [ ] - have to do
                [-] - doesnot needed
                [x] - done
                [*] - bug

                type source target genericType

                [-] select_transcription en undefined select_transcription
                [-] listen_isolation undefined undefined listen_isolation
                [-] listen_match undefined undefined listen_match
                [-] assist undefined undefined assist
                [x] listen_complete en undefined listen_complete (listen and complete by typing EN)
                [x] complete_reverse_translation ru en complete_reverse_translation (translate from RU to EN and type it)
                [x] reverse_translate ru en translate (translate from RU to EN and type it)
                [x] partial_reverse_translate ru en partial_reverse_translate (same as above, NEW)
                [x] reverse_tap ru en translate (same as reverse_translate, words can be selected or typed)
                [x] listen en undefined listen (listen and type all in EN)
                [x] name en undefined name (type single word in EN)
                [x] tap en ru translate
                [x] listen_tap en undefined listen_tap
            */
                // TODO for "reverse_translate" dos not work deletion of 
                // sevral selected ranges.
                // This type of input uses <input> or <textarea>.
                // Do I really care about it?
            }
        }).observe(document.body, { childList: true, subtree: true });
    }

    function getReactProps(elt:Element):Dynamic
    {
        for(propName in elt.fields())
        {
            if(StringTools.startsWith(propName, '__reactProps'))
                return elt.field(propName);
        }

        return null;
    }

    function onKeyDown(e:KeyboardEvent)
    {
        if(currentChallengeType == null) return;

        // do nothing if Ctrl key is present
        if(e.ctrlKey)   return;
        
        // NOTE: e.code always represents the QWERTY keyboard key.
        // See more https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code

        // if pressed key cannot be switched - do nothing 
        var pressedKeyCodeIndex = this.keyCodes.indexOf(e.code);
        if(pressedKeyCodeIndex == -1) return;

        // do nothing if the challenge type is not we are looking for
        if(CHALLENGE_TYPES.indexOf(currentChallengeType) == -1)
            return;

        var elt:Element = cast e.target;
        
        // check the target elt is <input> or <span>
        if(!(elt.hasAttribute('contenteditable') || elt.tagName == 'INPUT' || elt.tagName == 'TEXTAREA'))
            return;

        e.preventDefault();

        var newLetter = getLanguageLetter(targetLanguage, pressedKeyCodeIndex, e.shiftKey);

        replaceLetter(newLetter, cast elt);
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
     * Replaces selected text with given `letter` for `inputElt.value`
     * @param letter New letter
     * @param elt Target element
     */
    function replaceLetter(letter:String, elt:Element)
    {
        switch(elt.tagName)
        {
            case 'SPAN':
                
                var s = Browser.window.getSelection();
                if (s.anchorNode != s.focusNode)    return false;

                var start = s.anchorOffset;
                var end = s.focusOffset;
                var text = s.anchorNode.textContent;

                // if there is selection - delete selected text
                if(start != end)    s.deleteFromDocument();

                // duno if it gets updated after deleting, so read them again to be sure
                start = s.anchorOffset;
                end = s.focusOffset;

                // make the new text
                var newText = text.substring(0, start) + letter + text.substring(end);
                elt.textContent = newText;

                // NOTE with help of https://stackoverflow.com/questions/33658630/how-to-select-text-range-within-a-contenteditable-div-that-has-no-child-nodes
                // I figured it out!

                // tell React text was updated
                elt.dispatchEvent(new InputEvent('input', { bubbles: true }));

                s.collapse(elt.childNodes[0], start+1);

                return true;

            case 'INPUT', 'TEXTAREA':

                var elt:InputElement = cast elt;
                var start = elt.selectionStart;
                var end = elt.selectionEnd;
                var phrase = elt.value;
                var prefix = phrase.substring(0, start);
                var postfix = phrase.substring(end);
                phrase = prefix + letter + postfix;
                elt.value = phrase;
                elt.setSelectionRange(start+1, start+1);

                // somehow triggering change event does not work as with span
                // elt.dispatchEvent(new Event('change', { bubbles: true }));
                
                callReactEventHandler(elt, 'onChange', { type: 'change', target: elt });
                // duolingo onChange handler code: onChange:e=>i(e,e.target.value)

                return true;

            default:    
                return false;
        }
    }

    function callReactEventHandler(elt:Element, methodName:String, event:Dynamic)
    {
        /* 
        It is needed to force React to update state (otherwise nothing will work).
        To do it we find object with name like `__reactProps$d64zg30yj9p`
        and call its `onChange()`.
        */

        for(fieldName in elt.fields())
        {
            if(StringTools.contains(fieldName, '__reactProps'))
            {
                var reactProps = elt.field(fieldName);
                reactProps[untyped methodName](event);
                return;
            }
        }

        console.error('Cannot find react $methodName handler on', elt);
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
}