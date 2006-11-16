#import "CMUserScriptTest.h"
#import "CMUserScript.h"

@implementation CMUserScriptTest

- (void) testEmptyScript
{
	CMUserScript* s;
	
	s = [[CMUserScript alloc] initWithString: nil];	
	STAssertNil(s, nil);
	[s release];
	
	s = [[CMUserScript alloc] initWithString: @""];	
	STAssertNil(s, @"empty string");
	[s release];
}

- (void) testInvalidScript
{
	CMUserScript* s;
	
	s = [[CMUserScript alloc] initWithString: @"// ==UserScript==\n//\n//\n"];	
	STAssertNil(s, @"'/UserScript' is not found");
	[s release];
		
	s = [[CMUserScript alloc] initWithString: @"// ==UserScript==\n// @a b\n// ==/UserScript==\n"];	
	STAssertNil(s, @"@name is missing");
	[s release];
}


@end
