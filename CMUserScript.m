#import "CMUserScript.h"
#import "WildcardPattern.h"

@implementation CMUserScript

- (NSString*) script
{
	return script_;
}

- (BOOL) isIncluded: (NSURL*) url
{
	NSString* str = [url absoluteString];
	
	int i;
	for (i = 0; i < [include_ count]; i++) {
		WildcardPattern* pat = [include_ objectAtIndex: i];
		if ([pat isMatch: str]) {
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
	[scanner scanUpToCharactersFromSet: [NSCharacterSet whitespaceCharacterSet]
							intoString: &key];

	// Read value until "\r" or "\n"
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
	
	return [result autorelease];
}

- (id) initWithContentsOfFile: (NSString*) path
{
	self = [self init];
	
	script_ = [[NSString alloc] initWithContentsOfFile: path];
	NSDictionary* metadata = [CMUserScript parseMetadata: script_];
	
	NSArray* ary = [metadata objectForKey: @"@include"];
	int i;
	for (i = 0; i < [ary count]; i++) {
		WildcardPattern* pat;
		pat = [[WildcardPattern alloc] initWithString: [ary objectAtIndex: i]];
		[include_ addObject: pat];
	}
	
	NSLog(@"regist: %@", 
		  [[metadata objectForKey: @"@name"] objectAtIndex: 0]);
	
	return self;
}

#pragma mark Override
- (id) init
{
	self = [super init];
	
	script_ = nil;
	include_ = [[NSMutableArray alloc] init];
	
	return self;
}

- (void) dealloc
{
	[script_ release];
	[include_ release];
	
	[super dealloc];
}

@end
