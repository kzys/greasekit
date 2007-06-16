#import <WebKit/WebKit.h>

#define IS_JS_UNDEF(obj) ([(obj) isKindOfClass: [WebUndefined class]])

@interface NSObject(ValueForKeyJS)
- (id) valueForKeyJS: (NSString*) key;
@end
