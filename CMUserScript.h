#import <Cocoa/Cocoa.h>


@interface CMUserScript : NSObject {
	NSString* script_;
	NSMutableArray* include_;
}

+ (NSDictionary*) parseMetadata: (NSString*) script;

- (id) initWithContentsOfFile: (NSString*) path;

- (NSString*) script;
- (BOOL) isIncluded: (NSURL*) url;

@end
