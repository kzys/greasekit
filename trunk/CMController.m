/*
 * Copyright (c) 2006-2007 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "CMController.h"

#import <WebKit/WebKit.h>
#import "GKLoader.h"
#import "GKAppsController.h"
#import "CMUserScript.h"
#import "Utils.h"

#if 0
#  define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#  define DEBUG_LOG ;
#endif

static NSString* BUNDLE_IDENTIFIER = @"info.8-p.GreaseKit";
static NSString* CONFIG_PATH = @"~/Library/Application Support/GreaseKit/config.xml";
static NSString* SCRIPT_DIR_PATH = @"~/Library/Application Support/GreaseKit/";

@implementation CMController
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

- (NSDictionary*) scriptElementsDictionary
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    NSString* path = [CONFIG_PATH stringByExpandingTildeInPath];

    NSData* data = [NSData dataWithContentsOfFile: path];
    if (! data) {
        return result;
    }

    NSXMLDocument* doc;
    doc = [[NSXMLDocument alloc] initWithData: data
                                      options: 0
                                        error: nil];

    NSArray* ary = [[doc rootElement] elementsForName: @"Script"];
    size_t i;
    for (i = 0; i < [ary count]; i++) {
        NSXMLElement* script = [ary objectAtIndex: i];
        [result setObject: script
                   forKey: [script attributeValueForName: @"filename"]];
    }

    return result;
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
    NSData* data = [doc XMLDataWithOptions: NSXMLNodePrettyPrint];
    [data writeToFile: path atomically: YES];
}

- (void) installScript: (CMUserScript*) s
{
    [s install: scriptDir_];
    [self reloadUserScripts: nil];
}

- (void) reloadMenu
{
    int i;

    int count = [topMenu indexOfItemWithTag: -1];
    for (i = 0; i < count; i++) {
        [topMenu removeItemAtIndex: 0];
    }

    for (i = 0; i < [scripts_ count]; i++) {
        CMUserScript* script = [scripts_ objectAtIndex: i];

        NSMenuItem* item = [[NSMenuItem alloc] init];

        [item setTag: i];
        [item setTarget: self];
        [item setAction: @selector(toggleScriptEnable:)];
        [item setState: [script isEnabled] ? NSOnState : NSOffState];

        [item setTitle: [script name]];
        [topMenu insertItem: item atIndex: i];
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

    NSDictionary* config = [self scriptElementsDictionary];

    [self willChangeValueForKey: @"scripts"];

    int i;
    for (i = 0; i < [files count]; i++) {
        NSString* path;
        path = [NSString stringWithFormat: @"%@/%@", scriptDir_, [files objectAtIndex: i]];

        if (! [path hasSuffix: @".user.js"]) {
            continue;
        }

        NSXMLElement* element = [config objectForKey: [path lastPathComponent]];
        CMUserScript* script;
        script = [[CMUserScript alloc] initWithContentsOfFile: path
                                                      element: element];
        [script addObserver: self forKeyPath: @"enabled"
                    options: NSKeyValueObservingOptionNew
                    context: nil];

        [scripts_ addObject: script];
        [script release];
    }
    [self didChangeValueForKey: @"scripts"];

    [self reloadMenu];
}

- (void) observeValueForKeyPath: (NSString*) path
                       ofObject: (id) object
                         change: (NSDictionary*) change
                        context: (void*) context
{
    if ([path isEqualTo: @"enabled"]) {
        [self reloadMenu];
        [self saveScriptsConfig];
    }
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
    } else {
        [script release];
    }
}

- (void) showInstallAlertSheet: (CMUserScript*) script
                       webView: (WebView*) webView
{
    NSAlert* alert = [[NSAlert alloc] init];

    // Informative Text
    NSMutableString* text = [[NSMutableString alloc] init];

    if ([script name] && [script scriptDescription]) {
        [text appendFormat: @"%@ - %@", [script name], [script scriptDescription]];
    } else {
        if ([script name])
            [text appendString: [script name]];
        else if ([script scriptDescription])
            [text appendString: [script scriptDescription]];
    }

    [alert setInformativeText: text];
    [text release];

    // Message and Buttons
    if([script isInstalled: scriptDir_]) {
        [alert setMessageText: @"This script is installed, does it override the script?"];
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

        func = [scriptObject evaluateWebScript: ms];

        // eval on frame
        JSFunctionCall(func,
                       [NSArray arrayWithObjects: gmObject_, [frame DOMDocument], nil]);
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

    [self evalScriptsInFrame: [webView mainFrame] force: YES];

    // User Script
    if ([[url absoluteString] hasSuffix: @".user.js"]) {
        const char* bytes = (const char*) [[dataSource data] bytes];
        NSString* s = [NSString stringWithUTF8String: bytes];

        CMUserScript* script;
        script = [[CMUserScript alloc] initWithString: s
                                              element: nil];
        if (script) {
            [self showInstallAlertSheet: script webView: webView];
        }
    }
}

#pragma mark Action
- (IBAction) toggleScriptEnable: (id) sender
{
    CMUserScript* script = [scripts_ objectAtIndex: [sender tag]];

    [script setEnabled: [sender state] != NSOnState];
#if 0
    [sender setState: [script isEnabled] ? NSOnState : NSOffState];
    [self saveScriptsConfig];
#endif
}

- (IBAction) uninstallSelected: (id) sender
{
    CMUserScript* script = [[scriptsController selectedObjects] objectAtIndex: 0];
    [script uninstall];

    [self reloadUserScripts: sender];
}

- (IBAction) orderFrontAppsPanel: (id) sender
{
    [[appsController_ window] makeKeyAndOrderFront: nil];
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
                            @"Version 0.1",  @"ApplicationVersion",
                            @"Copyright (c) 2007 KATO Kazuyoshi",  @"Copyright",
                            nil];
    [NSApp orderFrontStandardAboutPanelWithOptions: options];
}


- (IBAction) reloadUserScripts: (id) sender
{
    // FIXME: dirty?
    int i;
    for (i = 0; i < [scripts_ count]; i++) {
        CMUserScript* s = [scripts_ objectAtIndex: i];
        [s removeObserver: self forKeyPath: @"enabled"];
    }
    [scripts_ release];

    scripts_ = [[NSMutableArray alloc] init];
    [self loadUserScripts];
}

- (id) initWithApplications: (NSArray*) apps
{
    self = [self init];
    if (! self)
        return nil;

    appsController_ = [[GKAppsController alloc] initWithApplications: apps];

    return self;
}

#pragma mark Override
- (id) init
{
    DEBUG_LOG(@"CMController %p - init", self);

    self = [super init];
    if (! self)
        return nil;

    scriptDir_ = [[SCRIPT_DIR_PATH stringByExpandingTildeInPath] retain];

    scriptTemplate_ = [[self loadScriptTemplate] retain];

    gmObject_ = [[GKGMObject alloc] init];

    scripts_ = nil;
    [NSBundle loadNibNamed: @"Menu.nib" owner: self];

    return self;
}

- (void) dealloc
{
    NSLog(@"CMController - dealloc");

    [appsController_ release];
    [gmObject_ release];
    [scripts_ release];

    [super dealloc];
}

- (void) awakeFromNib
{
    [self reloadUserScripts: nil];

    // Menu
    NSMenuItem* item;

    item = [[NSMenuItem alloc] init];
    [item setSubmenu: topMenu];

    [topMenu setTitle: @":)"];

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

- (void) windowWillClose: (NSNotification*) n
{
    [self saveScriptsConfig];
}


@end
