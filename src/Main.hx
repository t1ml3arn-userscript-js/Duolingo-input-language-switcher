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
        console.log("Duolingo input switcher inited");

    }

    function getUserLanguage():String
    {
        return 'en-en';
    }

    function getForeignLanguage():String
    {
        return 'en-en';
    }
}
