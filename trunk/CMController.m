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
#import "config.h"

#if 0
#  define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#  define DEBUG_LOG ;
#endif

static NSString* BUNDLE_IDENTIFIER = @"info.8-p.GreaseKit";
static NSString* CONFIG_PATH = @"~/Library/Application Support/GreaseKit/config.xml";
static NSString* SCRIPT_DIR_PATH = @"~/Library/Application Support/GreaseKit/";
static NSString* CM_SCRIPT_DIR_PATH = @"~/Library/Application Support/Creammonkey/";
static NSString* CM_BUNDLE_PATH = @"~/Library/InputManagers/Creammonkey/";
static NSString* GK_INPUT_MANAGER_PATH = @"~/Library/InputManagers/GreaseKit/";

@implementation CMController
- (NSString*) loadScriptTemplate
{
    NSBundle* bundle = [NSBundle bundleWithIdentifier: BUNDLE_IDENTIFIER];
    NSString* path = [NSString stringWithFormat: @"%@/template.js", [bundle resourcePath]];
    NSError* error;
    return [NSString stringWithContentsOfFile: path
                                     encoding: NSUTF8StringEncoding
                                        error: &error];
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
                   forKey: ElementAttribute(script, @"filename")];
    }
    [doc release];
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
    [root release];

    NSData* data = [doc XMLDataWithOptions: NSXMLNodePrettyPrint];
    [doc release];

    [data writeToFile: path atomically: YES];
}

- (void) addScript: (CMUserScript*) s
{
    [s addObserver: self forKeyPath: @"enabled"
           options: NSKeyValueObservingOptionNew
           context: nil];
    [scripts_ addObject: s];
}

- (void) installScript: (CMUserScript*) s
{
    // write to local fs
    [s install: scriptDir_];

    // add
    [self addScript: s];
    [s release];

    // enable and save config
    [s setEnabled: YES];
    [self saveScriptsConfig];

    // reload all
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
        [item release];
    }
}

- (NSArray*) scriptsAtDir: (NSString*) dir
{
    NSDirectoryEnumerator* files;
    files = [[NSFileManager defaultManager] enumeratorAtPath: dir];

    // Should return nil instead of an empty array, otherwise -loadUserScripts
    // will not create ~/Library/Appplication Support/GreaseKit directory for us
    if (! files)
        return nil;

    NSMutableArray* result = [NSMutableArray array];
    NSString* s;
    while (s = [files nextObject]) {
        NSString* path = [NSString stringWithFormat: @"%@/%@", dir, s];
        if ([path hasSuffix: @".user.js"]) {
            [result addObject: path];
        }
    }
    return result;
}

- (void) showWarningAboutCreammonkey
{
    NSString* path = [CM_BUNDLE_PATH stringByExpandingTildeInPath];

    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath: path
                                         isDirectory: &isDir];
    if (! isDir) {
        return;
    }
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Please remove Creammonkey"];
    [alert setInformativeText: @"GreaseKit can't work with Creammonkey. Please remove Creammonkey from your InputManager folder and relaunch this application."];
    [alert addButtonWithTitle: @"Ok"];
    [[alert autorelease] runModal];
}

- (void) showWarningAboutGreaseKit_1_2
{
    NSString* path = [GK_INPUT_MANAGER_PATH stringByExpandingTildeInPath];

    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath: path
                                         isDirectory: &isDir];
    if (! isDir) {
        return;
    }
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setMessageText: @"Please remove GreaseKit 1.2"];
    [alert setInformativeText: @"GreaseKit 1.5 is implemented as a SIMBL plugin. Please remove GreaseKit 1.2 from your InputManager folder and relaunch this application."];
    [alert addButtonWithTitle: @"Ok"];
    [[alert autorelease] runModal];
}

- (void) installCreammonkeyScripts
{
    NSString* dir = [CM_SCRIPT_DIR_PATH stringByExpandingTildeInPath];
    NSArray* files = [self scriptsAtDir: dir];
    if (! files)
        return;

    size_t i;
    for (i = 0; i < [files count]; i++) {
        NSString* path = [files objectAtIndex: i];
        CMUserScript* s = [[CMUserScript alloc] initWithContentsOfFile: path
                                                               element: nil];
        [self installScript: s];
    }
}

- (void) loadUserScripts
{
    NSFileManager* manager;
    manager = [NSFileManager defaultManager];

    NSString* dir = [SCRIPT_DIR_PATH stringByExpandingTildeInPath];
    NSArray* files = [self scriptsAtDir: dir];

    [self willChangeValueForKey: @"scripts"];
    if (files) {
        NSDictionary* config = [self scriptElementsDictionary];
        size_t i;
        for (i = 0; i < [files count]; i++) {
            NSString* path;
            path = [files objectAtIndex: i];

            NSXMLElement* element = [config objectForKey: [path lastPathComponent]];
            CMUserScript* script;
            script = [[CMUserScript alloc] initWithContentsOfFile: path
                                                          element: element];
            [self addScript: script];
            [script release];
        }
    } else {
        [manager createDirectoryAtPath: dir attributes: nil];
        [self installCreammonkeyScripts];
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
        [self saveScriptsConfig];
        [self reloadMenu];
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

    NSURL* url = WebFrameRequestURL(frame);
    if (url && (! [[url scheme] isEqualToString: @"about"]) &&
        [frame DOMDocument]) {
        ;
    } else {
        return;
    }

    // Eval!
    WebScriptObject* scriptObject = [[frame webView] windowScriptObject];

    WebScriptObject* func;
    id result;

    result = JSValueForKey([frame DOMDocument], @"readyState");
    if (force || [result isEqualToString: @"loaded"]) {
        id body = JSValueForKey([frame DOMDocument], @"body");
        if ([(NSString*) JSValueForKey(body, @"__creammonkeyed__") intValue]) {
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

    NSArray* ary = [self matchedScripts: url];
    for (i = 0; i < [ary count]; i++) {
        CMUserScript* s = [ary objectAtIndex: i];
        NSMutableString* ms = [NSMutableString stringWithFormat: scriptTemplate_, [s script]];
        func = [scriptObject evaluateWebScript: ms];

        NSArray* args = [NSArray arrayWithObjects: [frame DOMDocument], nil];
        // eval on frame
        JSFunctionCall(func, args);
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
    NSURL* url = WebFrameRequestURL([webView mainFrame]);

    [self evalScriptsInFrame: [webView mainFrame] force: YES];

    // User Script
    if ([[url absoluteString] hasSuffix: @".user.js"]) {
        NSString* s = StringWithContentsOfURL(url);

        CMUserScript* script;
        script = [[CMUserScript alloc] initWithString: s
                                              element: nil];
        if (! [script name]) {
            [script setName: [[url path] lastPathComponent]];
        }
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

- (IBAction) editSelected: (id) sender
{
    CMUserScript* script = [[scriptsController selectedObjects] objectAtIndex: 0];
    [[NSWorkspace sharedWorkspace] openFile: [script filename]];
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

    NSString* s = [[NSString alloc] initWithFormat: @"Version %s", VERSION];

    NSDictionary* options;
    options = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"GreaseKit",  @"ApplicationName",
                            icon,  @"ApplicationIcon",
                            @"",  @"Version",
                            s,  @"ApplicationVersion",
                            @"Copyright (c) 2006-2009 KATO Kazuyoshi",  @"Copyright",
                            nil];
    [s release];

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

    scripts_ = nil;
    [NSBundle loadNibNamed: @"Menu.nib" owner: self];

    return self;
}

- (void) dealloc
{
    NSLog(@"CMController - dealloc");

    [appsController_ release];
    [scripts_ release];

    [super dealloc];
}

- (int) menuInsertIndex
{
    size_t n = [[NSApp mainMenu] numberOfItems];

    NSMenu* right = [NSApp windowsMenu];
    if (! right) {
        right = [NSApp helpMenu];
        if (! right) {
            return n;
        }
    }

    size_t i;
    for (i = 1; i < n; i++) {
        NSMenuItem* item = [[NSApp mainMenu] itemAtIndex: i];
        if ([item submenu] == right) {
            return i;
        }
    }

    return n;
}

- (void) awakeFromNib
{
    [self reloadUserScripts: nil];

    NSMenuItem* item = [[NSMenuItem alloc] init];
    [[NSApp mainMenu] insertItem: item
                         atIndex: [self menuInsertIndex]];
    [item release];

    [topMenu setTitle: @"GreaseKit"];
    [item setSubmenu: topMenu];

    // Notification
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver: self
               selector: @selector(progressStarted:)
                   name: WebViewProgressStartedNotification
                 object: nil];
    [center addObserver: self
               selector: @selector(progressFinished:)
                   name: WebViewProgressFinishedNotification
                 object: nil];

    [center addObserver: self
               selector: @selector(applicationDidFinishLaunching:)
                   name: NSApplicationDidFinishLaunchingNotification
                 object: NSApp];
}

- (void) windowWillClose: (NSNotification*) n
{
    [self saveScriptsConfig];
}

- (void) applicationDidFinishLaunching: (NSNotification*) n
{
    [self showWarningAboutCreammonkey];
    [self showWarningAboutGreaseKit_1_2];
}

@end

// Workaround for PAC (Proxy Auto Config) by hetima-san <http://hetima.com>
@implementation DOMHTMLBodyElement(Info8_pCMUndefinedKeySupport)
- (id) valueForUndefinedKey: (NSString*) key
{
    // NSLog(@"DOMHTMLBodyElement %p valueForUndefinedKey: %@", self, key);
    if ([key isEqualToString:@"__creammonkeyed__"]) {
        return nil;
    }
    return [super valueForUndefinedKey: key];
}
@end

@implementation DOMHTMLFrameSetElement(Info8_pCMUndefinedKeySupport)
- (id) valueForUndefinedKey: (NSString*) key
{
    // NSLog(@"DOMHTMLFrameElement %p valueForUndefinedKey: %@", self, key);
    if ([key isEqualToString:@"__creammonkeyed__"]) {
        return nil;
    }
    return [super valueForUndefinedKey: key];
}
@end
