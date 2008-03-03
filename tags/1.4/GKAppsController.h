/*
 * Copyright (c) 2006-2007 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>

#define GKAppsController Info8_pGKAppsController
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
