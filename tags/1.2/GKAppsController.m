/*
 * Copyright (c) 2006-2007 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "GKAppsController.h"

#import <WebKit/WebKit.h>
#import "GKLoader.h"
#import "CMUserScript.h"
#import "Utils.h"

#if 0
#  define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#  define DEBUG_LOG ;
#endif

@implementation GKAppsController

- (NSWindow*) window
{
    return window;
}

- (NSMutableArray*) applications
{
    return applications_;
}

- (NSString*) displayNameForAppBundleIdentifier: (NSString*) bundleId
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];

    NSString* path = [ws absolutePathForAppBundleWithIdentifier: bundleId];
    if (path) {
        return [[NSFileManager defaultManager] displayNameAtPath: path];
    } else {
        return nil;
    }
}

- (NSImage*) iconForAppBundleIdentifier: (NSString*) bundleId
{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];

    NSString* path = [ws absolutePathForAppBundleWithIdentifier: bundleId];
    if (path) {
        return [ws iconForFile: path];
    } else {
        return nil;
    }
}

- (id) initWithApplications: (NSArray*) apps
{
    applications_ = [[NSMutableArray alloc] init];
    [applications_ addObjectsFromArray: apps];

    self = [self init];
    if (! self)
        return nil;

    return self;
}

- (void) saveApplicationList
{
    [applicationTableView noteNumberOfRowsChanged];
    [GKLoader saveApplicationList: applications_];
}

#pragma mark Action
- (IBAction) addApplication: (id) sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    NSArray* types = [NSArray arrayWithObjects: @"app", nil];
    if ([panel runModalForTypes: types] != NSOKButton) {
        return;
    }

    NSString* path = ArrayFirstObject([panel filenames]);
    NSBundle* bundle = [NSBundle bundleWithPath: path];

    [applications_ addObject: [bundle bundleIdentifier]];
    [self saveApplicationList];
}

- (IBAction) removeApplication: (id) sender
{
    int row = [applicationTableView selectedRow];
    if (row == -1)
        return;

    [applications_ removeObjectAtIndex: row];
    [self saveApplicationList];
}

#pragma mark Override
- (id) init
{
    self = [super init];
    if (! self)
        return nil;

    [NSBundle loadNibNamed: @"Apps.nib" owner: self];

    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    ;
}

- (void) windowWillClose: (NSNotification*) n
{
    // [self saveScriptsConfig];
}

- (id) tableView: (NSTableView*) tableView objectValueForTableColumn: (NSTableColumn*) column
             row: (int) index;
{
    NSString* bundleId = [applications_ objectAtIndex: index];
    if ([[column identifier] isEqualTo: @"name"]) {
        return [self displayNameForAppBundleIdentifier: bundleId];
    } else if ([[column identifier] isEqualTo: @"icon"]) {
        return [self iconForAppBundleIdentifier: bundleId];
    } else {
        return nil;
    }
}


- (int) numberOfRowsInTableView: (NSTableView*) tableView
{
    return [applications_ count];
}

@end
