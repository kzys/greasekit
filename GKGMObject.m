#import "GKGMObject.h"

#import <WebKit/WebKit.h>
#import "XMLHttpRequest.h"

// Safari
@interface BrowserWebView
- (void) openURLInNewTab: (NSURL*) url tabLocation: (id) loc;
@end

@interface BrowserWindowController
- (BrowserWebView*) currentWebView;
@end

static NSString* VALUES_PATH = @"~/Library/Application Support/GreaseKit/values.plist";

@implementation GKGMObject
- (void) saveScriptValues
{
    NSString* path = [VALUES_PATH stringByExpandingTildeInPath];
    [scriptValues_ writeToFile: path atomically: YES];
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
	NSString* value = nil;
    NSMutableDictionary* namespace = [scriptValues_ objectForKey: ns];
    if (namespace) {
		NSMutableDictionary* dict = [namespace objectForKey: name];

		if (dict) {
		    value = [dict objectForKey: key];
		}
	}
	
	if(!value){
		value = defaultValue;
	}
	
	return value;
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

- (id) init
{
    self = [super init];
    if (! self) {
        return nil;
    }
    NSString* path = [VALUES_PATH stringByExpandingTildeInPath];
    scriptValues_ = [NSDictionary dictionaryWithContentsOfFile: path];
    if (scriptValues_) {
        [scriptValues_ retain];
    } else {
        scriptValues_ = [[NSMutableDictionary alloc] init];
    }

    return self;
}

@end
