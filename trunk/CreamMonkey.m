/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "Creammonkey.h"
#import "CMController.h"
#import "WildcardPattern.h"

@implementation Creammonkey

#pragma mark Override
+ (void) load
{
	[[CMController alloc] init];
}

@end
