#import "WildcardPatternTest.h"

@implementation WildcardPatternTest
- (void) testString
{
    WildcardPattern* pat;

    pat = [[WildcardPattern alloc] initWithString: @"foo"];
    STAssertTrue([[pat string] isEqualTo: @"foo"], @"initializer");

    [pat setString: @"bar"];
    STAssertTrue([[pat string] isEqualTo: @"bar"], @"setter");
    [pat release];
}

- (void) testPlainMatch
{
    WildcardPattern* pat;
    
    pat = [[WildcardPattern alloc] initWithString: @"abc"]; 
    STAssertTrue([pat isMatch: @"abc"], 
                 @"equal.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"abc"]; 
    STAssertFalse([pat isMatch: @"abcdef"], 
                  @"string is longer than pattern.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"abcdef"];  
    STAssertFalse([pat isMatch: @"abc"],
                  @"pattern is longer than string.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"abc"]; 
    STAssertFalse([pat isMatch: @"def"], 
                  @"not equal.");
    [pat release];
}


- (void) testWildcardMatch
{
    WildcardPattern* pat;
    
    pat = [[WildcardPattern alloc] initWithString: @"*cdef"];   
    STAssertTrue([pat isMatch: @"abcdef"],
                 @"'*' at begin.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"*cd"]; 
    STAssertFalse([pat isMatch: @"abcdef"], 
                  @"*' at begin, but pattern is too short.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"*cdef"];   
    STAssertFalse([pat isMatch: @"abcd"], 
                  @"*' at begin, but pattern is too long.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"abcd*"];   
    STAssertTrue([pat isMatch: @"abcdef"], 
                 @"'*' at end.");
    [pat release];

    pat = [[WildcardPattern alloc] initWithString: @"abcd*"];
    STAssertTrue([pat isMatch: @"abcd"], 
                 @"'*' at end, '*' match '\\0'.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"ab*ef"];   
    STAssertTrue([pat isMatch: @"abcdef"], 
                 @"'*' at middle.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"ab*ef"];   
    STAssertFalse([pat isMatch: @"abcd"], 
                  @"'*' at middle, but pattern is too long.");
    [pat release];
    
    pat = [[WildcardPattern alloc] initWithString: @"ab*ef"];   
    STAssertFalse([pat isMatch: @"abcdefgh"], 
                  @"'*' at middle, but pattern is too short.");
    [pat release];

    STAssertFalse([[WildcardPattern patternWithString: @"a.c"] isMatch: @"abc"],
                 @"'.' is not meta char.");

    pat = [WildcardPattern patternWithString: @"google.tld"];
    STAssertTrue([pat isMatch: @"google.com"], @"'google.tld' match '.com'.");

    STAssertTrue([pat isMatch: @"google.co.jp"],
                 @"'google.tld' match '.co.jp'. it's not TLD...");

    pat = [WildcardPattern patternWithString: @"example.tld"];
    STAssertTrue([pat isMatch: @"example.jp"],
                 @"'.tld' match '.jp'.");
    STAssertTrue([pat isMatch: @"example.tokyo.jp"],
                 @"'.tld' match '.tokyo.jp'.");
    STAssertTrue([pat isMatch: @"example.nottokyo.jp"],
                 @"'.tld' match '.nottokyo.jp'.");
    STAssertFalse([pat isMatch: @"example.not-tokyo.jp"],
                 @"'.tld' don't match '.not-tokyo.jp'.");
}

@end
