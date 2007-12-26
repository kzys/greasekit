#import "XMLHttpRequest.h"
#import "Utils.h"
#import "TEC.h"
#import "JapaneseString.h"

static NSString*
japaneseStringFromData(NSData* data)
{
    NSStringEncoding from = [JapaneseString detectEncoding: data];
    TECConverter* converter = [[TECConverter alloc] initWithEncoding: from];
    NSString* s = [converter convertToString: data];
    [converter release];

    return s;
}

static NSString*
stringFromDataByTEC(NSData* data)
{
    static TECSniffer* sniffer = NULL;
    if (! sniffer) {
        sniffer = [[TECSniffer alloc] init];
    } else {
        [sniffer clear];
    }

    NSArray* ary = [sniffer sniff: data];
    if ([ary count] == 0) {
        return nil;
    }

    NSStringEncoding from = [[ary objectAtIndex: 0] intValue];

    TECConverter* converter = [[TECConverter alloc] initWithEncoding: from];
    NSString* s = [converter convertToString: data];
    [converter release];

    return s;
}

static NSString*
stringFromData(NSData* data, NSStringEncoding encoding)
{
    NSString* s = [[NSString alloc] initWithData: data
                                        encoding: encoding];
    if (s) {
        return [s autorelease];
    }

    NSArray* ary =
        [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    if ([ary count] > 0 && [[ary objectAtIndex: 0] isEqualTo: @"ja"]) {
        s = japaneseStringFromData(data);
    }

    if (! s) {
        s = stringFromDataByTEC(data);
    }

    return s;
}

@implementation XMLHttpRequest

+ (NSStringEncoding) encodingFromMimeType: (NSString*) s
{
    if ([s rangeOfString: @"charset=shift_jis"
                 options: NSCaseInsensitiveSearch].location != NSNotFound) {
        return NSShiftJISStringEncoding;
    } else if ([s rangeOfString: @"charset=iso-2022-jp"
                        options: NSCaseInsensitiveSearch].location != NSNotFound) {
        return NSISO2022JPStringEncoding;
    } else if ([s rangeOfString: @"charset=euc-jp"
                        options: NSCaseInsensitiveSearch].location != NSNotFound) {
        return NSJapaneseEUCStringEncoding;
    } else {
        return NSUTF8StringEncoding;
    }
}

- (id) initWithDetails: (WebScriptObject*) details
              delegate: (id) delegate
{
    // NSLog(@"%@ - init", self);

    self = [super init];
    if (! self)
        return nil;
    
    // url
    NSURL* url = [NSURL URLWithString: JSValueForKey(details, @"url")];
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL: url];
    
    // method
    NSString* method = [JSValueForKey(details, @"method") uppercaseString];
    [req setHTTPMethod: method];
    if ([method isEqualTo: @"POST"] || [method isEqualTo: @"PUT"]) {
        NSString* s = JSValueForKey(details, @"data");
        if (! s)
            s = @"";
        [req setHTTPBody: [s dataUsingEncoding: NSUTF8StringEncoding]];
    }

    // encoding
    encoding_ = NSUTF8StringEncoding;
    if (JSValueForKey(details, @"overrideMimeType")) {
        NSString* s = JSValueForKey(details, @"overrideMimeType");
        encoding_ = [[self class] encodingFromMimeType: s];
    }

    // headers
    WebScriptObject* headers = JSValueForKey(details, @"headers");
    
    if (headers) {
        NSArray* keys = JSObjectKeys(headers);
        
        size_t i;
        for (i = 0; i < [keys count]; i++) {
            NSString* key = [keys objectAtIndex: i];
            [req setValue: [headers valueForKey: key] forHTTPHeaderField: key];
        }
    }
    
    // onload
    onLoad_ = [JSValueForKey(details, @"onload") retain];
    // onerror
    onError_ = [JSValueForKey(details, @"onerror") retain];
    // onreadystatechange
    onReadyStateChange_ = [JSValueForKey(details, @"onreadystatechange") retain];
    
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
    NSString* s = stringFromData(data_, encoding_);
    [data_ release];
    data_ = nil;

    [response_ setValue: s
                  forKey: @"responseText"];
    
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
    NSLog(@"%@ - dealloc", self);

    [response_ release];
    [data_ release];

    [onLoad_ release];
    [onError_ release];
    [onReadyStateChange_ release];
    
    [super dealloc];
}

@end
