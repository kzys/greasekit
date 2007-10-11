/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>
#import "GKGMObject.h"

@interface GKAppsController : NSObject {
    NSMutableArray* applications_;
    IBOutlet NSWindow* window;
    IBOutlet NSTableView* applicationTableView;
}
- (NSMutableArray*) applications;

- (IBAction) addApplication: (id) sender;
- (IBAction) removeApplication: (id) sender;

- (NSWindow*) window;

@end
