#import "XMLHttpRequest.h"
#import "JSUtils.h"

@implementation XMLHttpRequest

- (id) initWithDetails: (WebScriptObject*) details
              delegate: (id) delegate
{
    NSLog(@"%@ - init", self);

    self = [super init];
    if (! self)
        return nil;
    
    // url
    NSURL* url = [NSURL URLWithString: [details valueForKeyJS: @"url"]];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL: url];
    
    // method
    [req setHTTPMethod: [[details valueForKeyJS: @"method"] uppercaseString]];
    if ([[req HTTPMethod] isEqualTo: @"POST"]) {
        NSString* s = [details valueForKeyJS: @"data"];
        if (! s)
            s = @"";
        [req setHTTPBody: [s dataUsingEncoding: NSUTF8StringEncoding]];
    }

    // headers
    WebScriptObject* headers = [details valueForKeyJS: @"headers"];
    
    if (headers) {
        NSArray* keys = JSObjectKeys(headers);
        
        size_t i;
        for (i = 0; i < [keys count]; i++) {
            NSString* key = [keys objectAtIndex: i];
            [req setValue: [headers valueForKey: key] forHTTPHeaderField: key];
        }
    }
    
    // onload
    onLoad_ = [[details valueForKeyJS: @"onload"] retain];
    // onerror
    onError_ = [[details valueForKeyJS: @"onerror"] retain];
    // onreadystatechange
    onReadyStateChange_ = [[details valueForKeyJS: @"onreadystatechange"] retain];
    
    data_ = [[NSMutableData alloc] init];
    response_ = [[details evaluateWebScript: @"new Object"] retain];
    NSArray* args = [NSArray arrayWithObjects: response_, nil];
    
    // call onreadystate 1
    [response_ setValue: [NSNumber numberWithInt: 1]
                  forKey: @"readyState"];
    JSFunctionCall(onReadyStateChange_, args);

    // send
    [[NSURLConnection alloc] initWithRequest: req
                                    delegate: self];
    
    // call onreadystate 2
    [response_ setValue: [NSNumber numberWithInt: 2]
                  forKey: @"readyState"];
    JSFunctionCall(onReadyStateChange_, args);    
    
    return self;
}

- (void) connection: (NSURLConnection*) connection 
 didReceiveResponse: (NSURLResponse*) resp
{    
    NSHTTPURLResponse* http = (NSHTTPURLResponse*) resp;
    [response_ setValue: [NSNumber numberWithInt: [http statusCode]] 
                  forKey: @"status"];
    [response_ setValue: [NSHTTPURLResponse localizedStringForStatusCode: [http statusCode]] 
                  forKey: @"statusText"];
    [response_ setValue: [http allHeaderFields]
                  forKey: @"responseHeaders"];
    
    [data_ setLength: 0];
}

- (void) connection: (NSURLConnection*) connection
     didReceiveData: (NSData*) data
{
    [data_ appendData:data];

    [response_ setValue: [NSNumber numberWithInt: 3]
                  forKey: @"readyState"];
    JSFunctionCall(onReadyStateChange_, [NSArray arrayWithObject: response_]);    
}

- (void) connectionDidFinishLoading: (NSURLConnection*) connection
{
    NSString* s = [[NSString alloc] initWithData: data_
                                        encoding: NSUTF8StringEncoding];
    [response_ setValue: s
                  forKey: @"responseText"];
    [s release];
    
    [response_ setValue: [NSNumber numberWithInt: 4]
                  forKey: @"readyState"];
    
    NSArray* args = [NSArray arrayWithObject: response_];
    JSFunctionCall(onReadyStateChange_, args);
    JSFunctionCall(onLoad_, args);
    
    [connection release];

    [self release]; // FIXME
}

- (void) dealloc
{
    [response_ release];
    [data_ release];

    [onLoad_ release];
    [onError_ release];
    [onReadyStateChange_ release];
    
    NSLog(@"%@ - dealloc", self);
    [super dealloc];
}

@end
