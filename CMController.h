/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>
#import "GKGMObject.h"

@interface CMController : NSObject {
	IBOutlet NSPopUpButton* applicationsButton;
	IBOutlet NSMenu* topMenu;
	IBOutlet NSArrayController* scriptsController;
	
	NSMutableArray* scripts_;
	NSString* scriptDir_;
    NSMutableArray* applications_;
    
    NSString* scriptTemplate_;
    GKGMObject* gmObject_;
}

- (IBAction) toggleScriptEnable: (id) sender;
- (IBAction) uninstallSelected: (id) sender;
- (IBAction) orderFrontAboutPanel: (id) sender;
- (IBAction) reloadUserScripts: (id) sender;
- (NSArray*) scripts;

- (id) initWithApplications: (NSArray*) apps;

@end
