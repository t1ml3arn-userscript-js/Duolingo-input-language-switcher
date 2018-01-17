class Main {
    static function main() {
        trace("Duolingo input switcher inited");
        new Main();
    }

    var console:js.html.Console;
    var origincons:js.html.Console;
    var document:js.html.Document;

    function new()
    {
        console = js.Browser.window.console; 
        document = js.Browser.document;

        console.error('wtf?');
        origincons = console; // this does not help to bypass site polyfill
        console = untyped {};

        untyped (Object.assign(console, js.Browser.window.console));
        // console.log('console after copy');

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
        console.log('console copy after ready');
        origincons.log('origin console copy after ready');
        trace('it is just a trace()');
    }
}
