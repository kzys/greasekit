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

@end
