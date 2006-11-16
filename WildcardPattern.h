#import <Cocoa/Cocoa.h>


@interface WildcardPattern : NSObject {
	NSString* pattern_;
}

- (id) initWithString: (NSString*) s;
- (BOOL) isMatch: (NSString*) s;

@end
