#import <WebKit/WebKit.h>

WebScriptObject* JSFunctionCall(WebScriptObject* func, id arg);
NSArray* JSObjectKeys(WebScriptObject* obj);

#define IS_JS_UNDEF(obj) ([(obj) isKindOfClass: [WebUndefined class]])

@interface NSObject(ValueForKeyJS)
- (id) valueForKeyJS: (NSString*) key;
@end
