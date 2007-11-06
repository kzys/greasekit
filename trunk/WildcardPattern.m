/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "WildcardPattern.h"

#define TLD_PATTERN @"\\.(com|org|net)"

@implementation WildcardPattern
+ (id) patternWithString: (NSString*) s
{
    id obj = [[self alloc] initWithString: s];
    return [obj autorelease];
}

+ (NSString*) escapeRegexpMetaCharactors: (NSString*) src
{
    NSMutableString* result = [NSMutableString string];
    const char* ptr;
    for (ptr = [src UTF8String]; *ptr != '\0'; ptr++) {
        switch (*ptr) {
        case '*':
            [result appendString: @".*"];
            break;
        case '.':
            [result appendString: @"\\."];
            break;
        default:
            [result appendFormat: @"%c", *ptr];
            break;
        }
    }
    return result;
}

+ (NSString*) regexpFromURIGlob: (NSString*) src
{
    // .tld
    NSRange range = [src rangeOfString: @".tld"];
    if (range.length > 0) {
        NSMutableString* result = [NSMutableString string];
        NSString* s;

        s = [src substringToIndex: range.location];
        [result appendString: [self escapeRegexpMetaCharactors: s]];

        [result appendString: TLD_PATTERN];

        s = [src substringFromIndex: range.location + range.length];
        [result appendString: [self regexpFromURIGlob: s]]; // recursive
        return result;
    } else {
        return [self escapeRegexpMetaCharactors: src];
    }
}

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

    NSString* tmp = [[self class] regexpFromURIGlob: source_];
    NSLog(@"tmp = %@", tmp);
    regcomp(&pattern_,
            [[NSString stringWithFormat: @"^%@$", tmp] UTF8String],
            REG_NOSUB | REG_EXTENDED);
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
