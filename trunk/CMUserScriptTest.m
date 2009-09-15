#import "CMUserScriptTest.h"
#import "CMUserScript.h"
#import "WildcardPattern.h"

@implementation CMUserScriptTest
- (void) testFilename
{
    CMUserScript* script;
    NSString* path = [NSString stringWithFormat: @"%s/%s/Resources/hello.user.js", getenv("BUILD_PRODUCTS_DIR"), getenv("CONTENTS_FOLDER_PATH")];

    script = [[CMUserScript alloc] initWithContentsOfFile: path
                                                  element: nil];
    STAssertEquals(path, [script filename], nil);
    [script release];
}

- (void) testInitWithString
{
    CMUserScript* script;

    script = [[CMUserScript alloc] initWithString: @"hello\rworld\r"
                                          element: nil];
    STAssertTrue([@"hello\nworld\n" isEqualTo: [script script]], nil);
    [script release];

    script = [[CMUserScript alloc] initWithString: @"hello\r\nworld\r\n"
                                          element: nil];
    STAssertTrue([@"hello\nworld\n" isEqualTo: [script script]], nil);
    [script release];

    script = [[CMUserScript alloc] initWithString: @"hello\nworld\n"
                                          element: nil];
    STAssertTrue([@"hello\nworld\n" isEqualTo: [script script]], nil);
    [script release];
}

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
    [pat release];
    STAssertFalse([script isMatched: url], @"exclude");
    
    [script release];
}

- (void) testFileName
{
    NSString* s;

    s = [CMUserScript fileNameFromString: @"FooBar"];
    STAssertTrue([s isEqualTo: @"foobar"], @"lower");

    s = [CMUserScript fileNameFromString: @"Foo Bar Baz"];
    STAssertTrue([s isEqualTo: @"foobarbaz"], @"space");

    s = [CMUserScript fileNameFromString: @"Foo/Bar"];
    STAssertTrue([s isEqualTo: @"foobar"], @"symbol");
}

- (void) testUniqueName
{
    NSString* s;
    NSArray* ary;

    ary = [NSArray array];
    s = [CMUserScript uniqueName: @"foo" others: ary];
    STAssertTrue([s isEqualTo: @"foo.user.js"], @"nothing");

    ary = [NSArray arrayWithObjects: @"foo.user.js", nil];
    s = [CMUserScript uniqueName: @"foo" others: ary];
    STAssertTrue([s isEqualTo: @"foo-2.user.js"], @"1");

    ary = [NSArray arrayWithObjects: @"foo.user.js", @"foo-2.user.js", nil];
    s = [CMUserScript uniqueName: @"foo" others: ary];
    STAssertTrue([s isEqualTo: @"foo-3.user.js"], @"2");
}

- (void) testXMLElement
{
    CMUserScript* script;
    NSXMLElement* element;

    // for test
    [CMUserScript setDummyBundleIdentifier: @"com.example.Dummy"];

    script = [[CMUserScript alloc] init];

    element = [script XMLElement];
    STAssertTrue([[element name] isEqualTo: @"Script"], @"element name");
    
    [script release];
}

- (void) testPatternsFromStrings
{
    NSArray* src = [NSArray arrayWithObjects: @"foo", @"bar", nil];
    NSArray* dst = [CMUserScript patternsFromStrings: src];

    WildcardPattern* pattern = [dst objectAtIndex: 0];
    STAssertTrue([pattern isMatch: @"foo"], @"match");
    STAssertTrue([src count] == [dst count], @"size of array");
    STAssertTrue([[src objectAtIndex: 0] isEqualTo: [pattern string]], @"pattern string");
}

@end
