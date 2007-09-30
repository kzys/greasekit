#import "CMUserScriptTest.h"
#import "CMUserScript.h"
#import "WildcardPattern.h"

@implementation CMUserScriptTest
#if 0
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
#endif

- (void) testMatch
{
    NSURL* url = [NSURL URLWithString: @"http://example.com/foo/bar"];
    WildcardPattern* pat;
    CMUserScript* script;
    script = [[CMUserScript alloc] init];

    pat = [[WildcardPattern alloc] init];
    [pat setString: @"http://example.com/foo/*"];
    [[script include] addObject: pat];
    [pat release];
    STAssertTrue([script isMatched: url], @"include");

    pat = [[WildcardPattern alloc] init];
    [pat setString: @"http://example.com/foo/bar"];
    [[script exclude] addObject: pat];
    STAssertFalse([script isMatched: url], @"exclude");
}

- (void) testXMLElement
{
    CMUserScript* script;
    script = [[CMUserScript alloc] init];

    NSXMLElement* element = [script XMLElement];
    STAssertTrue([[element name] isEqualTo: @"Script"], @"element name");
}

@end
