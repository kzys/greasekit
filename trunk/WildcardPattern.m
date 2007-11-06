/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "WildcardPattern.h"

@implementation WildcardPattern
- (void) setString: (NSString*) s
{
    if (source_) {
        [source_ release];
        regfree(&pattern_);
    }

    if (! s) {
        return;
    }
    source_ = [s retain];

    NSMutableString* tmp = [NSMutableString string];
    const char* ptr;
    [tmp appendString: @"^"];
    for (ptr = [s UTF8String]; *ptr != '\0'; ptr++) {
        switch (*ptr) {
        case '*':
            [tmp appendString: @".*"];
            break;
        default:
            [tmp appendFormat: @"%c", *ptr];
            break;
        }
    }
    [tmp appendString: @"$"];

    regcomp(&pattern_, [tmp UTF8String], REG_NOSUB);
}

- (NSString*) string
{
    return source_;
}

- (id) initWithString: (NSString*) s
{
	self = [self init];
    if (! self) {
        return nil;
    }

    [self setString: s];
	return self;
}

- (BOOL) isMatch: (NSString*) s
{
    return regexec(&pattern_, [s UTF8String], 0, NULL, 0) == 0;
}

- (void) dealloc
{
    [self setString: nil];
    [super dealloc];
}

@end
