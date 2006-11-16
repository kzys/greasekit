/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "CMUserScript.h"
#import "WildcardPattern.h"

@interface NSArray(ArrayFirstObject)
- (id) firstObject;
@end

@implementation NSArray(ArrayFirstObject)
- (id) firstObject
{
	if ([self count] > 0)
		return [self objectAtIndex: 0];
	else
		return nil;
}
@end

@implementation CMUserScript
- (BOOL) isInstalled: (NSString*) scriptDir
{
	NSString* path;
	path = [NSString stringWithFormat: @"%@/%@", scriptDir, basename_];
	
	return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (NSString*) name
{
	return [[metadata_ objectForKey: @"@name"] firstObject];
}

- (NSString*) description
{
	return [[metadata_ objectForKey: @"@description"] firstObject];
}

- (NSString*) script
{
	return script_;
}

- (BOOL) install: (NSString*) path
{
	[fullPath_ release];
	fullPath_ = [[NSString alloc] initWithFormat: @"%@/%@", path, basename_];
	
	return [script_ writeToFile: fullPath_ atomically: YES];
}

- (BOOL) uninstall
{
	if (fullPath_) {
		return [[NSFileManager defaultManager] removeFileAtPath: fullPath_
														handler: nil];
	}
	return NO;
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
	
	// metadata
	metadata_ = [[CMUserScript parseMetadata: script] retain];
	// NSLog(@"metadata_ = %@", metadata_);
	
	// include
	NSArray* ary;
	ary = [CMUserScript createPatterns: [metadata_ objectForKey: @"@include"]];
	[include_ addObjectsFromArray: ary];
	
	// exclude
	ary = [CMUserScript createPatterns: [metadata_ objectForKey: @"@exclude"]];
	[exclude_ addObjectsFromArray: ary];
	
	return self;
}

- (id) initWithContentsOfFile: (NSString*) path
{
	NSString* script = [[NSString alloc] initWithContentsOfFile: path];
	
	self = [self initWithString: script];
	[script release];	

	if (! self)
		return nil;
	
	basename_ = [[path lastPathComponent] retain];
	fullPath_ = [path retain];
	
	return self;
}

- (id) initWithContentsOfURL: (NSURL*) url
{
	NSString* script = [[NSString alloc] initWithContentsOfURL: url];
	
	self = [self initWithString: script];
	[script release];
	
	if (! self)
		return nil;
	
	basename_ = [[[url absoluteString] lastPathComponent] retain];
	
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
	
	basename_ = nil;
	fullPath_ = nil;
	
	return self;
}

- (void) dealloc
{
	// NSLog(@"CMUserScript %p - dealloc", self);

	[script_ release];

	[metadata_ release];
	[include_ release];
	
	[basename_ release];
	[fullPath_ release];
	
	[super dealloc];
}

@end
