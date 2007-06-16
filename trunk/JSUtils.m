#import "JSUtils.h"

WebScriptObject* JSFunctionCall(WebScriptObject* func, id arg)
{
    if (IS_JS_UNDEF(func)) {
        return nil;
    }
    WebScriptObject* jsThis = [func evaluateWebScript: @"this"];
    return [func callWebScriptMethod: @"call"
                       withArguments: [NSArray arrayWithObjects: jsThis, arg, nil]];
}

NSArray* JSObjectKeys(WebScriptObject* obj)
{
    WebScriptObject* func = [obj evaluateWebScript: @"function(obj){var result=[];for(var k in obj)result.push(k);return result;}"];
    WebScriptObject* keys = JSFunctionCall(func, obj);
    
    size_t i;
    NSMutableArray* result = [NSMutableArray array];
    WebScriptObject* jsUndefined = [obj evaluateWebScript: @"undefined"];
    for (i = 0; [keys webScriptValueAtIndex: i] != jsUndefined; i++) {
        [result addObject: [keys webScriptValueAtIndex: i]];
    }
    return result;
}

@implementation NSObject(ValueForKeyJS)
- (id) valueForKeyJS: (NSString*) key
{
    id result;
    @try {
        result = [self valueForKey: key];
    } @catch (NSException* e) {
        return nil;
    }
    
    if (IS_JS_UNDEF(result)) {
        return nil;
    }
    
    return result;
}
@end
