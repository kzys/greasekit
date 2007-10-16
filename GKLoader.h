/* -*- objc -*-
 *
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */
#import <Cocoa/Cocoa.h>

#define GKLoader Info8_pGKLoader
@interface GKLoader : NSObject {
}
+ (void) saveApplicationList: (NSArray*) apps;
@end
