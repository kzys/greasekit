#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface NSArray(ArrayFirstObject)
- (id) firstObject;
@end

@interface NSMutableString(ReplaceOccurrencesOfStringWithString)
- (unsigned int) replaceOccurrencesOfString: (NSString*) target
                                 withString: (NSString*) replacement;
@end

WebScriptObject* JSFunctionCall(WebScriptObject* func, NSArray* args);
NSArray* JSObjectKeys(WebScriptObject* obj);

#define IS_JS_UNDEF(obj) ([(obj) isKindOfClass: [WebUndefined class]])

@interface NSObject(ValueForKeyJS)
- (id) valueForKeyJS: (NSString*) key;
@end

@interface NSXMLElement(SetAttributeForName)
- (void) setAttribute: (NSString*) value forName: (NSString*) key;
- (NSString*) attributeValueForName: (NSString*) key;
@end
