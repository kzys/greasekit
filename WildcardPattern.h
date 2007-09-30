/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>

@interface WildcardPattern : NSObject {
	NSString* pattern_;
}

- (id) initWithString: (NSString*) s;
- (BOOL) isMatch: (NSString*) s;

- (NSString*) string;
- (void) setString: (NSString*) s;

@end
