(function (bridge) {
    // unsafeWindow
    var unsafeWindow = window;

    with ({ document: unsafeWindow.document, location: unsafeWindow.location, window: {} }) {
        // define GM functions
        var GM_log = function (s) {
            return bridge.gmLog_(s);
        }
        var GM_getValue = function (k, d) {
            return bridge.gmValueForKey_defaultValue_scriptName_namespace_(k, d, "<name>", "<namespace>");
        }
        var GM_setValue = function (k, v) {
            return bridge.gmSetValue_forKey_scriptName_namespace_(v, k, "<name>", "<namespace>");
        }
        /* Not implemented yet
        var GM_registerMenuCommand = function (t, c) {
            <bridge>.gmRegisterMenuCommand_callback_(t, c);
        }
        */
        var GM_xmlhttpRequest = function (d) {
            return bridge.gmXmlhttpRequest_(d);
        }

        <body>;
    }
});
