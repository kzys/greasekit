#import "CreamMonkey.h"
#import "CMController.h"
#import "WildcardPattern.h"

@implementation CreamMonkey

#pragma mark Override
+ (void) load
{
	NSLog(@"CreamMonkey + load");
	
	[[CMController alloc] init];
}

@end
