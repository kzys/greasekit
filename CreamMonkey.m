/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "CreamMonkey.h"
#import "CMController.h"
#import "WildcardPattern.h"

@implementation CreamMonkey

#pragma mark Override
+ (void) load
{
	// NSLog(@"CreamMonkey + load");
	
	[[CMController alloc] init];
}

@end
