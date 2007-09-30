/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "CMUserScript.h"
#import "WildcardPattern.h"

#import "Utils.h"

@implementation CMUserScript
- (NSMutableArray*) include
{
    return include_;
}

- (void) setInclude: (NSArray*) ary
{
    [include_ setArray: ary];
}

- (NSMutableArray*) exclude
{
    return exclude_;
}

- (void) setExclude: (NSArray*) ary
{
    [exclude_ setArray: ary];
}

- (void) configureWithXMLElement: (NSXMLElement*) element
{
    BOOL flag;

    // false or not ("true", nil -> true, "false" -> false)
    flag = [[element attributeValueForName: @"enabled"] isEqualTo: @"false"];
    [self setEnabled: ! flag];
}

- (NSXMLElement*) XMLElement
{
    NSXMLElement* result;
    result = [[NSXMLElement alloc] initWithName: @"Script"];

    [result setAttribute: [self name] forName: @"name"];
    [result setAttribute: [self namespace] forName: @"namespace"];
    [result setAttribute: [self description] forName: @"description"];

    [result setAttribute: ([self isEnabled] ? @"true" : @"false")
                 forName: @"enabled"];

    if (fullPath_) {
        [result setAttribute: [fullPath_ lastPathComponent]
                     forName: @"filename"];
    }

    return [result autorelease];
}

- (BOOL) isEqualTo: (CMUserScript*) other
{
    return ([[self name] isEqualTo: [other name]] &&
            [[self namespace] isEqualTo: [other namespace]]);
}

- (BOOL) isInstalled: (NSString*) scriptDir
{
	NSString* path;
	path = [NSString stringWithFormat: @"%@/%@", scriptDir, [self basenameFromName]];
    if (! [[NSFileManager defaultManager] fileExistsAtPath: path]) {
        return NO;
    }

    CMUserScript* other;
    other = [[CMUserScript alloc] initWithContentsOfFile: path];
    [other autorelease];

    return [self isEqualTo: other];
}

- (NSString*) name
{
    if ([metadata_ objectForKey: @"@name"])
        return [[metadata_ objectForKey: @"@name"] firstObject];
    else
        return nil;
}

- (NSString*) description
{
	return [[metadata_ objectForKey: @"@description"] firstObject];
}

- (NSString*) namespace
{
	return [[metadata_ objectForKey: @"@namespace"] firstObject];
}

- (NSString*) script
{
    if (fullPath_) {
        return [[NSString alloc] initWithData: [NSData dataWithContentsOfFile: fullPath_]
                                     encoding: NSUTF8StringEncoding];        
    } else {
        return script_;
    }
}

+ (NSString*) fileNameFromString: (NSString*) s
{
    size_t len = [s length];

    unichar* src = (unichar*) malloc(len * sizeof(unichar));
    [s getCharacters: src];

    unichar* dst = (unichar*) malloc(len * sizeof(unichar));

    NSCharacterSet* cs = [NSCharacterSet alphanumericCharacterSet];
    size_t i, j = 0;
    for (i = 0; i < len; i++) {
        if ([cs characterIsMember: src[i]]) {
            dst[j++] = src[i];
        }
    }

    return [[NSString stringWithCharacters: dst length: j] lowercaseString];
}

- (NSString*) basenameFromName
{
    NSString* s = [[self class] fileNameFromString: [self name]];
    return [NSString stringWithFormat: @"%@.user.js", s];
}

+ (NSString*) uniqueName: (NSString*) name
                  others: (NSArray*) others
{
    int i = 2;
    NSString* s = [NSString stringWithFormat: @"%@.user.js", name];
    while ([others containsObject: s]) {
        s = [NSString stringWithFormat: @"%@-%d.user.js", name, i];
        i++;
    }
    return s;
}

- (BOOL) install: (NSString*) dir
{
	[fullPath_ release];
	fullPath_ = [[NSString alloc] initWithFormat: @"%@/%@", dir, [self basenameFromName]];

    if ([[NSFileManager defaultManager] fileExistsAtPath: fullPath_]) {
        CMUserScript* other;
        other = [[CMUserScript alloc] initWithContentsOfFile: fullPath_];

        // same filename, but not same script
        if (! [self isEqualTo: other]) {
            NSArray* ary = [[NSFileManager defaultManager] directoryContentsAtPath: dir];
            NSString* s;
            s = [[self class] uniqueName: [[self class] fileNameFromString: [self name]]
                                  others: ary];

            [fullPath_ release];
            fullPath_ = [[NSString alloc] initWithFormat: @"%@/%@", dir, s];
        }
        [other release];
    }

    NSData* data = [script_ dataUsingEncoding: NSUTF8StringEncoding];
    return [data writeToFile: fullPath_ atomically: YES];
}

- (BOOL) uninstall
{
	if (fullPath_) {
		return [[NSFileManager defaultManager] removeFileAtPath: fullPath_
														handler: nil];
	}
	return NO;
}

- (BOOL) isEnabled
{
    return enabled_;
}

- (void) setEnabled: (BOOL) flag
{
    enabled_ = flag;
}

- (BOOL) isMatched: (NSURL*) url
		  patterns: (NSArray*) ary
{
	NSString* str = [url absoluteString];
	
	int i;
	for (i = 0; i < [ary count]; i++) {
		WildcardPattern* pat = [ary objectAtIndex: i];
		if ([pat isMatch: str]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL) isMatched: (NSURL*) url
{
    if (! include_)
        return YES;
    
	if ([self isMatched: url patterns: include_]) {
		if (! [self isMatched: url patterns: exclude_]) {
			return YES;
		}
	}
	return NO;
}

+ (void) parseMetadataLine: (NSString*) line
					result: (NSMutableDictionary*) result
{
	NSString* key;
	NSString* value;
	
	NSScanner* scanner = [[NSScanner alloc] initWithString: line];
	[scanner autorelease];
	
	// Skip to "@"
	[scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @"@"]
							intoString: NULL];
	
	// Read key until whitespace
	if ([scanner isAtEnd])
		return;
	[scanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
							intoString: &key];

	// Read value until "\r" or "\n"
	if ([scanner isAtEnd])
		return;
	[scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\r"]
							intoString: &value];
	
	NSMutableArray* ary = [result objectForKey: key];
	if (! ary) {
		ary = [[NSMutableArray alloc] init];
		[result setObject: ary forKey: key];
		[ary release];
	}
	[ary addObject: value];
}

+ (NSDictionary*) parseMetadata: (NSString*) script
{
	NSMutableDictionary* result;
	result = [[NSMutableDictionary alloc] init];
	
	BOOL inMetadata = NO;
	NSArray* lines = [script componentsSeparatedByString: @"\n"];
	int i;
	for (i = 0; i < [lines count]; i++) {
		NSString* line = [lines objectAtIndex: i];

		
		if ([line rangeOfString: @"==UserScript=="].length) {
			inMetadata = YES;
		} else if ([line rangeOfString: @"==/UserScript=="].length) {
			inMetadata = NO;
		} else if (inMetadata) {
			[CMUserScript parseMetadataLine: line
									 result: result];
		}
	}
	
	if ([result count] == 0) {
		[result release];
		return nil;
	} else {
		return [result autorelease];
	}
}

+ (NSArray*) createPatterns: (NSArray*) ary
{
    if (! ary)
        return nil;
    
	NSMutableArray* result = [[NSMutableArray alloc] init];
	
	int i;
	for (i = 0; i < [ary count]; i++) {
		WildcardPattern* pat;
		pat = [[WildcardPattern alloc] initWithString: [ary objectAtIndex: i]];
		[result addObject: pat];
	}
	
	return [result autorelease];
}

- (id) initWithString: (NSString*) script
{
	self = [self init];
	if (! self)
		return nil;
		
	script_ = [script retain];
    // NSLog(@"script_ = %@", script_);
	
	// metadata
	metadata_ = [[CMUserScript parseMetadata: script] retain];
	// NSLog(@"metadata_ = %@", metadata_);
	
	// include
	NSArray* ary;
	ary = [CMUserScript createPatterns: [metadata_ objectForKey: @"@include"]];
    [self setInclude: ary];
	include_ = [ary retain];
	
	// exclude
	ary = [CMUserScript createPatterns: [metadata_ objectForKey: @"@exclude"]];
    [self setExclude: ary];
	
	return self;
}

- (id) initWithData: (NSData*) data
{
    NSString* str = [[NSString alloc] initWithData: data
                                          encoding: NSUTF8StringEncoding];
    
	self = [self initWithString: str];
	if (! self)
		return nil;
	
	return self;
}


- (id) initWithContentsOfFile: (NSString*) path
{
    self = [self initWithData: [NSData dataWithContentsOfFile: path]];

	if (! self)
		return nil;
	
	fullPath_ = [path retain];
	
	return self;
}

#pragma mark Override
- (id) init
{
	// NSLog(@"CMUserScript %p - init", self);

	self = [super init];
	
	script_ = nil;

	metadata_ = nil;

	include_ = [[NSMutableArray alloc] init];
	exclude_ = [[NSMutableArray alloc] init];
	
	fullPath_ = nil;

    enabled_ = YES;
	
	return self;
}

- (void) dealloc
{
	// NSLog(@"CMUserScript %p - dealloc", self);

	[script_ release];

	[metadata_ release];

	[include_ release];
	[exclude_ release];
	
	[fullPath_ release];
	
	[super dealloc];
}

@end
