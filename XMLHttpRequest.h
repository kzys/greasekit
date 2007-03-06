#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface XMLHttpRequest : NSObject {
    NSMutableData* data_;
    id delegate_;
    
    WebScriptObject* onLoad_;
    WebScriptObject* onError_;
    WebScriptObject* onReadyStateChange_;
    
    NSMutableDictionary* response_;
}
- (id) initWithDetails: (WebScriptObject*) details
              delegate: (id) delegate;
@end
