#import "JSUtils.h"

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
