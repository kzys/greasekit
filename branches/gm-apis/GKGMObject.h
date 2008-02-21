#import <Cocoa/Cocoa.h>

#define GKGMObject Info8_pGkGMObject
@interface GKGMObject : NSObject {
    NSMutableDictionary* scriptValues_;
}


- (id) gmLog: (NSString*) s;
- (id) gmValueForKey: (NSString*) key
        defaultValue: (NSString*) defaultValue
          scriptName: (NSString*) name
           namespace: (NSString*) ns;
- (id) gmSetValue: (NSString*) value
           forKey: (NSString*) key
       scriptName: (NSString*) name
        namespace: (NSString*) ns;

@end
