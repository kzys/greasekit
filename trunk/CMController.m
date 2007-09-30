/*
 * Copyright (c) 2006-2007 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "CMController.h"

#import <WebKit/WebKit.h>
#import "CMUserScript.h"
#import "XMLHttpRequest.h"
#import "JSUtils.h"

#if 0
#  define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#  define DEBUG_LOG ;
#endif

static NSString* BUNDLE_IDENTIFIER = @"info.8-p.GreaseKit";
static NSString* CONFIG_PATH = @"~/Library/Application Support/GreaseKit/config.xml";
static NSString* VALUES_PATH = @"~/Library/Application Support/GreaseKit/values.plist";
static NSString* SCRIPT_DIR_PATH = @"~/Library/Application Support/GreaseKit/";

// Safari
@interface BrowserWebView
- (void) openURLInNewTab: (NSURL*) url tabLocation: (id) loc;
@end

@interface BrowserWindowController
- (BrowserWebView*) currentWebView;
@end

@interface NSMutableString(ReplaceOccurrencesOfStringWithString)
- (unsigned int) replaceOccurrencesOfString: (NSString*) target
                                 withString: (NSString*) replacement;
@end

@implementation NSMutableString(ReplaceOccurrencesOfStringWithString)
- (unsigned int) replaceOccurrencesOfString: (NSString*) target
                                 withString: (NSString*) replacement
{
    return [self replaceOccurrencesOfString: target
                                 withString: replacement
                                    options: 0
                                      range: NSMakeRange(0, [self length])];
}
@end

@implementation CMController
- (BOOL) addApplication: (NSString*) identifier
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    NSString* path = [ws absolutePathForAppBundleWithIdentifier: identifier];
    if (! path) {
        return NO;
    }
    NSImage* icon = [ws iconForFile: path];
    NSString* name = [[NSFileManager defaultManager] displayNameAtPath: path];

    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys: name, @"name", icon, @"icon", [NSNumber numberWithBool: YES], @"enabled", identifier, @"identifier", nil];
    [applications addObject: dict];
    return YES;
}

- (void) buildApplicationList
{
    NSArray* apps = [NSArray arrayWithObjects: @"com.apple.Safari", @"com.mailplaneapp.Mailplane", @"com.factorycity.DietPibb", nil];
    int i;
    for (i = 0; i < [apps count]; i++) {
        [self addApplication: [apps objectAtIndex: i]];
    }
}

- (BOOL) canInjectable: (NSString*) identifier
{
    int i;
    for (i = 0; i < [applications count]; i++) {
        NSDictionary* app = [applications objectAtIndex: i];
        NSLog(@"app = %@", app);
        if ([[app objectForKey: @"identifier"] isEqualTo: identifier]) {
            return YES;
        }
    }
    return NO;
}

- (NSString*) loadScriptTemplate
{
    NSBundle* bundle = [NSBundle bundleWithIdentifier: BUNDLE_IDENTIFIER];
    NSString* path = [NSString stringWithFormat: @"%@/template.js", [bundle resourcePath]];
    return [NSString stringWithContentsOfFile: path];
}

- (NSArray*) scripts
{
    return scripts_;
}

- (NSDictionary*) scriptsConfig
{
    NSString* path = [CONFIG_PATH stringByExpandingTildeInPath];
    return [NSDictionary dictionaryWithContentsOfFile: path];
}

- (void) saveScriptsConfig
{
    NSXMLElement* root = [[NSXMLElement alloc] initWithName: @"UserScriptConfig"];

    int i;
    for (i = 0; i < [scripts_ count]; i++) {
        CMUserScript* script = [scripts_ objectAtIndex: i];
        [root addChild: [script XMLElement]];
    }
    NSString* path = [CONFIG_PATH stringByExpandingTildeInPath];
    NSXMLDocument* doc;
    doc = [[NSXMLDocument alloc] initWithRootElement: root];
    [[doc XMLData] writeToFile: path atomically: YES];
}

- (void) saveScriptValues
{
    NSString* path = [VALUES_PATH stringByExpandingTildeInPath];
    [scriptValues_ writeToFile: path atomically: YES];
}

- (void) installScript: (CMUserScript*) s
{
    [s install: scriptDir_];

    [scripts_ addObject: s];
    [self saveScriptsConfig];
    [self reloadUserScripts: nil];
}

- (void) reloadMenu
{
    int i;

    int count = [menu indexOfItemWithTag: -1];
    for (i = 0; i < count; i++) {
        [menu removeItemAtIndex: 0];
    }

    for (i = 0; i < [scripts_ count]; i++) {
        CMUserScript* script = [scripts_ objectAtIndex: i];

        NSMenuItem* item = [[NSMenuItem alloc] init];

        [item setTag: i];
        [item setTarget: self];
        [item setAction: @selector(toggleScriptEnable:)];
        [item setState: [script isEnabled] ? NSOnState : NSOffState];

        [item setTitle: [script name]];
        [menu insertItem: item atIndex: i];
    }
}

- (void) loadUserScripts
{
    NSFileManager* manager;
    manager = [NSFileManager defaultManager];

    NSArray* files;
    files = [manager directoryContentsAtPath: scriptDir_];

    if (! files) {
        [manager createDirectoryAtPath: scriptDir_
                            attributes: nil];
        files = [manager directoryContentsAtPath: scriptDir_];
    }

    NSDictionary* config = [self scriptsConfig];

    [self willChangeValueForKey: @"scripts"];

    int i;
    for (i = 0; i < [files count]; i++) {
        NSString* path;
        path = [NSString stringWithFormat: @"%@/%@", scriptDir_, [files objectAtIndex: i]];

        if (! [path hasSuffix: @".user.js"]) {
            continue;
        }

        CMUserScript* script;
        script = [[CMUserScript alloc] initWithContentsOfFile: path];

        [script setEnabled: [[config objectForKey: [script basename]] intValue]];

        [scripts_ addObject: script];
        [script release];
    }
    [self didChangeValueForKey: @"scripts"];

    [self reloadMenu];
}

- (NSArray*) matchedScripts: (NSURL*) url
{
    if (! url)
        return nil;
    NSMutableArray* result = [[NSMutableArray alloc] init];

    int i;
    for (i = 0; i < [scripts_ count]; i++) {
        CMUserScript* script = [scripts_ objectAtIndex: i];
        if ([script isEnabled] && [script isMatched: url]) {
            [result addObject: script];
        }
    }

    return [result autorelease];
}

- (void) installAlertDidEnd: (NSAlert*) alert
                 returnCode: (int) returnCode
                contextInfo: (void*) contextInfo
{
    CMUserScript* script = (CMUserScript*) contextInfo;
    if (returnCode == NSAlertFirstButtonReturn) {
        [self installScript: script];
    }
    [script release];
}

- (void) showInstallAlertSheet: (CMUserScript*) script
                       webView: (WebView*) webView
{
    NSAlert* alert = [[NSAlert alloc] init];

    // Informative Text
    NSMutableString* text = [[NSMutableString alloc] init];

    if ([script name] && [script description]) {
        [text appendFormat: @"%@ - %@", [script name], [script description]];
    } else {
        if ([script name])
            [text appendString: [script name]];
        else if ([script description])
            [text appendString: [script description]];
    }

    [alert setInformativeText: text];
    [text release];

    // Message and Buttons
    if([script isInstalled: scriptDir_]) {
        [alert setMessageText: @"This script is installed, Override?"];
        [alert addButtonWithTitle: @"Override"];
    } else {
        [alert setMessageText: @"Install this script?"];
        [alert addButtonWithTitle: @"Install"];
    }
    [alert addButtonWithTitle: @"Cancel"];

    // Begin Sheet
    [alert beginSheetModalForWindow: [webView window]
                      modalDelegate: self
                     didEndSelector: @selector(installAlertDidEnd:returnCode:contextInfo:)
                        contextInfo: script];
}

- (void) evalScriptsInFrame: (WebFrame*) frame
                      force: (BOOL) force
{
    int i;
    NSArray* children = [frame childFrames];
    for (i = 0; i < [children count]; i++) {
        [self evalScriptsInFrame: [children objectAtIndex: i]
                           force: force];
    }

    NSURL* url = [[[frame dataSource] request] URL];
    if (url && (! [[url scheme] isEqualToString: @"about"]) &&
        [frame DOMDocument]) {
        ;
    } else {
        return;
    }

    // Eval!
    id scriptObject = [[frame webView] windowScriptObject];

    WebScriptObject* func;
    id result;

    result = [[frame DOMDocument] valueForKeyJS: @"readyState"];
    if (force || [result isEqualToString: @"loaded"]) {
        id body = [[frame DOMDocument] valueForKeyJS: @"body"];
        if ([[body valueForKeyJS: @"__creammonkeyed__"] intValue]) {
            return;
        } else {
            [body setValue: [NSNumber numberWithBool: YES]
                    forKey: @"__creammonkeyed__"];
        }
    } else {
        return;
    }
    DEBUG_LOG(@"eval: %d %@ %@ %d",
              force, url, [frame DOMDocument],
              [[self matchedScripts: url] count]);

    NSString* bridgeName = [NSString stringWithFormat: @"__bridge%u__", rand()];
    NSArray* ary = [self matchedScripts: url];
    for (i = 0; i < [ary count]; i++) {
        CMUserScript* s = [ary objectAtIndex: i];
        NSMutableString* ms = [NSMutableString stringWithString: scriptTemplate_];

        // create function!
        if ([s namespace]) {
            [ms replaceOccurrencesOfString: @"<namespace>"
                                withString: [s namespace]];
        }
        [ms replaceOccurrencesOfString: @"<name>"
                            withString: [s name]];
        [ms replaceOccurrencesOfString: @"<bridge>"
                            withString: bridgeName];
        [ms replaceOccurrencesOfString: @"<body>"
                            withString: [s script]];
        // DEBUG_LOG(@"ms = %@", ms);
        func = [scriptObject evaluateWebScript: ms];

        // eval on frame
        JSFunctionCall(func, [NSArray arrayWithObjects: self, [frame DOMDocument], nil]);
    }
}

- (void) progressStarted: (NSNotification*) n
{
    // DEBUG_LOG(@"CMController %@ - progressStarted: %@", self, n);
    WebView* webView = [n object];
    WebDataSource* source = [[webView mainFrame] provisionalDataSource];
    if (! source) {
        // source = [[webView mainFrame] provisionalDataSource];
    }
    NSURL* url = [[source request] URL];
    DEBUG_LOG(@"url = %@, matchedScripts = %d",
              url, [[self matchedScripts: url] count]);
    if ([[self matchedScripts: url] count] == 0) {
        return;
    }
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(progressChanged:)
                   name: WebViewProgressEstimateChangedNotification
                 object: [n object]];
}

+ (BOOL) isSelectorExcludedFromWebScript: (SEL) sel
{
    if (sel == @selector(gmLog:) ||
        sel == @selector(gmValueForKey:defaultValue:scriptName:namespace:) ||
        sel == @selector(gmSetValue:forKey:scriptName:namespace:) ||
        sel == @selector(gmRegisterMenuCommand:callback:) ||
        sel == @selector(gmXmlhttpRequest:) ||
        sel == @selector(gmOpenInTab:))
        return NO;
    else
        return YES;
}

+ (BOOL) isKeyExcludedFromWebScript: (const char*) name
{
    return YES;
}

- (id) gmOpenInTab: (NSString*) s
{
    NSURL* url = [NSURL URLWithString: s];
    BrowserWindowController* controller = [[NSApp keyWindow] windowController];
    [[controller currentWebView] openURLInNewTab: url
                                     tabLocation: nil];
    return nil;
}

- (id) gmLog: (NSString*) s
{
    NSLog(@"GM_log: %@", s);
    return nil;
}

- (id) gmValueForKey: (NSString*) key
        defaultValue: (NSString*) defaultValue
          scriptName: (NSString*) name
           namespace: (NSString*) ns
{
    NSMutableDictionary* namespace = [scriptValues_ objectForKey: ns];
    if (! namespace) {
        return defaultValue;
    }
    NSMutableDictionary* dict = [namespace objectForKey: name];
    if (! dict) {
        return defaultValue;
    }
    return [dict objectForKey: key];
}

- (id) gmSetValue: (NSString*) value
           forKey: (NSString*) key
       scriptName: (NSString*) name
        namespace: (NSString*) ns
{
    NSMutableDictionary* namespace = [scriptValues_ objectForKey: ns];
    if (! namespace) {
        namespace = [NSMutableDictionary dictionary];
        [scriptValues_ setObject: namespace
                          forKey: ns];
    }
    NSMutableDictionary* dict = [namespace objectForKey: name];
    if (! dict) {
        dict = [NSMutableDictionary dictionary];
        [namespace setObject: dict
                      forKey: name];
    }
    [dict setObject: value forKey: key];

    [self saveScriptValues];

    return nil;
}

- (id) gmRegisterMenuCommand: (NSString*) text
                    callback: (id) func
{
    // FIXME: Not implemented yet.
    return nil;
}

- (void) gmXmlhttpRequest: (WebScriptObject*) details
{
    XMLHttpRequest* req = [[XMLHttpRequest alloc] initWithDetails: details
                                                         delegate: self];
}

- (void) progressChanged: (NSNotification*) n
{
    // DEBUG_LOG(@"CMController %p - progressChanged: %@", self, n);

    WebView* webView = [n object];
    [self evalScriptsInFrame: [webView mainFrame]
                       force: NO];
}

- (void) progressFinished: (NSNotification*) n
{
    WebView* webView = [n object];
    WebDataSource* dataSource = [[webView mainFrame] dataSource];
    NSURL* url = [[dataSource request] URL];

    // User Script
    if ([[url absoluteString] hasSuffix: @".user.js"]) {
        CMUserScript* script;
        script = [[CMUserScript alloc] initWithContentsOfURL: url];
        if (script) {
            [self showInstallAlertSheet: script webView: webView];
        }
    } else {
        [self evalScriptsInFrame: [webView mainFrame]
                           force: YES];
    }
}

#pragma mark Action
- (IBAction) toggleScriptEnable: (id) sender
{
    CMUserScript* script = [scripts_ objectAtIndex: [sender tag]];

    [script setEnabled: [sender state] != NSOnState];
    [sender setState: [script isEnabled] ? NSOnState : NSOffState];

    [self saveScriptsConfig];
}

- (IBAction) uninstallSelected: (id) sender
{
    CMUserScript* script = [[scriptsController selectedObjects] objectAtIndex: 0];
    [script uninstall];

    [self reloadUserScripts: sender];
}

- (IBAction) orderFrontAboutPanel: (id) sender
{
    NSImage* icon = [[NSWorkspace sharedWorkspace] iconForFileType: @"bundle"];
    [icon setSize: NSMakeSize(128, 128)];

    NSDictionary* options;
    options = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"GreaseKit",  @"ApplicationName",
                            icon,  @"ApplicationIcon",
                            @"",  @"Version",
                            @"Version 1.1",  @"ApplicationVersion",
                            @"Copyright (c) 2006-2007 KATO Kazuyoshi",  @"Copyright",
                            nil];
    [NSApp orderFrontStandardAboutPanelWithOptions: options];
}


- (IBAction) reloadUserScripts: (id) sender
{
    [scripts_ release];

    scripts_ = [[NSMutableArray alloc] init];
    [self loadUserScripts];
}

#pragma mark Override
- (id) init
{
    NSLog(@"CMController %p - init", self);

    self = [super init];
    if (! self)
        return nil;

    scriptDir_ = [[SCRIPT_DIR_PATH stringByExpandingTildeInPath] retain];

    scriptTemplate_ = [[self loadScriptTemplate] retain];

    NSString* path = [VALUES_PATH stringByExpandingTildeInPath];
    scriptValues_ = [NSDictionary dictionaryWithContentsOfFile: path];
    if (scriptValues_) {
        [scriptValues_ retain];
    } else {
        scriptValues_ = [[NSMutableDictionary alloc] init];
    }

    scripts_ = nil;
    [NSBundle loadNibNamed: @"Menu.nib" owner: self];

    return self;
}

- (void) dealloc
{
    NSLog(@"CMController - dealloc");

    [scripts_ release];

    [super dealloc];
}

- (void) awakeFromNib
{
    [self reloadUserScripts: nil];

    // Menu
    NSMenuItem* item;

    item = [[NSMenuItem alloc] init];
    [item setSubmenu: menu];

    [menu setTitle: @":)"];

    [[NSApp mainMenu] addItem: item];
    [item release];

    // Notification
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
#if 0
    [center addObserver: self
               selector: @selector(progressChanged:)
                   name: WebViewProgressEstimateChangedNotification
                 object: nil];
#else
    [center addObserver: self
               selector: @selector(progressStarted:)
                   name: WebViewProgressStartedNotification
                 object: nil];
#endif
    [center addObserver: self
               selector: @selector(progressFinished:)
                   name: WebViewProgressFinishedNotification
                 object: nil];
}


@end
