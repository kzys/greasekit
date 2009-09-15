/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>

@class Info8_pGKGMObject;
@class Info8_pGKAppsController;
@class WebView;

#define CMController Info8_pCMController
@interface CMController : NSObject {
    IBOutlet NSMenu* topMenu;
    IBOutlet NSArrayController* scriptsController;
    
    NSMutableArray* scripts_;
    NSString* scriptDir_;
    
    NSString* scriptTemplate_;
    Info8_pGKAppsController* appsController_;
}

- (IBAction) editSelected: (id) sender;
- (IBAction) toggleScriptEnable: (id) sender;
- (IBAction) uninstallSelected: (id) sender;
- (IBAction) orderFrontAboutPanel: (id) sender;
- (IBAction) orderFrontAppsPanel: (id) sender;
- (IBAction) reloadUserScripts: (id) sender;
- (NSArray*) scripts;

- (id) initWithApplications: (NSArray*) apps;

@end
