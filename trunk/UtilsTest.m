#import "UtilsTest.h"
#import "Utils.h"

@implementation UtilsTest

- (void) testArrayFirstObject
{
    NSArray* ary = [NSArray arrayWithObjects: @"foo", @"bar", @"baz", nil];
    STAssertTrue([ArrayFirstObject(ary) isEqualTo: @"foo"], @"first");
}

- (void) testStringReplace
{
    NSMutableString* s = [NSMutableString stringWithString: @"foo bar foo bar"];
    StringReplace(s, @"bar", @"baz");
    STAssertTrue([s isEqualTo: @"foo baz foo baz"], @"replace");
}

- (void) testValueForKeyJS
{
    WebView* webView = [[WebView alloc] init];
    WebScriptObject* wso = [webView windowScriptObject];

    id obj = [wso evaluateWebScript: @"new Object({foo: 'FOO'})"];

    STAssertTrue([JSValueForKey(obj, @"foo") isEqualTo: @"FOO"], @"exist");
    STAssertTrue(JSValueForKey(obj, @"bar") == nil, @"not exist");

    [webView release];
}

- (void) testXMLElementAttribute
{
    NSXMLElement* element = [NSXMLElement elementWithName: @"foo"];
    ElementSetAttribute(element, @"bar", @"BAR");

    STAssertTrue([[element XMLString] isEqualTo: @"<foo bar=\"BAR\"></foo>"], @"str");

    STAssertTrue([ElementAttribute(element, @"bar") isEqualTo: @"BAR"], @"attr");
}

@end
