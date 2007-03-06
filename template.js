(function () {
    // define GM functions
    var GM_log = function (s) {
        <bridge>.gmLog_(s);
    }
    var GM_getValue = function (k, d) {
        <bridge>.gmValueForKey_defaultValue_(k, d);
    }
    var GM_setValue = function (k, v) {
        <bridge>.gmSetValue_ForKey_(v, k);
    }
    var GM_registerMenuCommand = function (t, c) {
        <bridge>.gmRegisterMenuCommand_callback_(t, c);
    }
    var GM_xmlhttpRequest = function (d) {
        <bridge>.gmXmlhttpRequest_(d);
    }

    // unsafeWindow
    var unsafeWindow = window;
    window = null;

    with ({ document: unsafeWindow.document, location: unsafeWindow.location }) {
        <body>;
    }
})();
