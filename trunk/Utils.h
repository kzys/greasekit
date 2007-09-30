#import <Cocoa/Cocoa.h>

@interface NSArray(ArrayFirstObject)
- (id) firstObject;
@end

@interface NSMutableString(ReplaceOccurrencesOfStringWithString)
- (unsigned int) replaceOccurrencesOfString: (NSString*) target
                                 withString: (NSString*) replacement;
@end

@class WebScriptObject;

WebScriptObject* JSFunctionCall(WebScriptObject* func, NSArray* args);
NSArray* JSObjectKeys(WebScriptObject* obj);

#define IS_JS_UNDEF(obj) ([(obj) isKindOfClass: [WebUndefined class]])

@interface NSObject(ValueForKeyJS)
- (id) valueForKeyJS: (NSString*) key;
@end
