#import "Utils.h"

@implementation NSArray(ArrayFirstObject)
- (id) firstObject
{
	if ([self count] > 0)
		return [self objectAtIndex: 0];
	else
		return nil;
}
@end

@implementation NSMutableString(ReplaceOccurrencesOfStringWithString)
- (unsigned int) replaceOccurrencesOfString: (NSString*) target
                                 withString: (NSString*) replacement
{
    return [self replaceOccurrencesOfString: target
                                 withString: replacement
                                    options: 0
                                      range: NSMakeRange(0, [self length])];
}
@end

WebScriptObject* JSFunctionCall(WebScriptObject* func, NSArray* args)
{
    if (IS_JS_UNDEF(func)) {
        return nil;
    }
    WebScriptObject* jsThis = [func evaluateWebScript: @"this"];
    if (! jsThis) {
        return nil;
    }
    NSMutableArray* ary = [NSMutableArray arrayWithObject: jsThis];
    [ary addObjectsFromArray: args];
    return [func callWebScriptMethod: @"call" withArguments: ary];
}

NSArray* JSObjectKeys(WebScriptObject* obj)
{
    WebScriptObject* func = [obj evaluateWebScript: @"function(obj){var result=[];for(var k in obj)result.push(k);return result;}"];
    WebScriptObject* keys = JSFunctionCall(func, [NSArray arrayWithObject: obj]);

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

@implementation NSXMLElement(SetAttributeForName)
- (void) setAttribute: (NSString*) value forName: (NSString*) key
{
    if ([self attributeForName: key]) {
        [self removeAttributeForName: key];
    }
    NSXMLNode* node;
    node = [NSXMLNode attributeWithName: key stringValue: value];
    [self addAttribute: node];
}

- (NSString*) attributeValueForName: (NSString*) key
{
    NSXMLNode* node = [self attributeForName: key];
    if (node)
        return [node stringValue];
    else
        return nil;
}
@end
