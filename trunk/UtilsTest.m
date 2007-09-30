#import "UtilsTest.h"
#import "Utils.h"

@implementation UtilsTest

- (void) testArrayFirstObject
{
    NSArray* ary = [NSArray arrayWithObjects: @"foo", @"bar", @"baz", nil];
    STAssertTrue([[ary firstObject] isEqualTo: @"foo"], @"first");
}

- (void) testStringReplace
{
    NSMutableString* s = [NSMutableString stringWithString: @"foo bar foo bar"];
    [s replaceOccurrencesOfString: @"bar" withString: @"baz"];
    STAssertTrue([s isEqualTo: @"foo baz foo baz"], @"replace");
}

- (void) testValueForKeyJS
{
    WebView* webView = [[WebView alloc] init];
    WebScriptObject* wso = [webView windowScriptObject];

    id obj = [wso evaluateWebScript: @"new Object({foo: 'FOO'})"];

    STAssertTrue([[obj valueForKeyJS: @"foo"] isEqualTo: @"FOO"], @"exist");
    STAssertTrue([obj valueForKeyJS: @"bar"] == nil, @"not exist");

    [webView release];
}

- (void) testXMLElementAttribute
{
    NSXMLElement* element = [NSXMLElement elementWithName: @"foo"];
    [element setAttribute: @"BAR" forName: @"bar"];

    STAssertTrue([[element XMLString] isEqualTo: @"<foo bar=\"BAR\"></foo>"], @"str");

    STAssertTrue([[element attributeValueForName: @"bar"] isEqualTo: @"BAR"], @"attr");
}

@end
