(function (<bridge>, document) {
    if ((! document.__creammonkeyed__) &&
        (document.readyState == "loaded" || document.readyState == "complete")) {
        document.__creammonkeyed__ = true;
    } else {
        return;
    }
    with ({ location: window.location, unsafeWindow: window }) {        
        // define GM functions
       var GM_addStyle = function (s) {
	  var style = document.createElement('style');
	  style.setAttribute('type', 'text/css');
	  style.appendChild(document.createTextNode(s));
	  document.getElementsByTagName('head')[0].appendChild(style);
       }
        var GM_log = function (s) {
            window.console.log('GM_log: ' + s);
            return <bridge>.gmLog_(s);
        };
        var GM_getValue = function (k, d) {
            return <bridge>.gmValueForKey_defaultValue_scriptName_namespace_(k, d, "<name>", "<namespace>");
        };
        var GM_setValue = function (k, v) {
            return <bridge>.gmSetValue_forKey_scriptName_namespace_(v, k, "<name>", "<namespace>");
        };
        /* Not implemented yet
        var GM_registerMenuCommand = function (t, c) {
            <bridge>.gmRegisterMenuCommand_callback_(t, c);
        }
        */
        var GM_xmlhttpRequest = function (d) {
            return <bridge>.gmXmlhttpRequest_(d);
        };

        <body>;
    }
});
