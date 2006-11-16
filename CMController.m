#import "CMController.h"
#import "CMUserScript.h"


@implementation CMController

- (void) loadUserScripts
{
	NSFileManager* manager;
	manager = [NSFileManager defaultManager];
	
	NSString* dirPath = [@"~/Library/Application Support/CreamMonkey/" stringByExpandingTildeInPath];
	
	NSArray* files;
	files = [manager directoryContentsAtPath: dirPath];
	
	if (! files)
		return;
	
	int i;
	for (i = 0; i < [files count]; i++) {
		NSString* path = [NSString stringWithFormat: @"%@/%@", dirPath, [files objectAtIndex: i]];
		
		if (! [path hasSuffix: @".user.js"]) {
			continue;
		}
		
		CMUserScript* script;
		script = [[CMUserScript alloc] initWithContentsOfFile: path];
		
		[scripts_ addObject: script];
	}
}

- (NSArray*) matchedScripts: (NSURL*) url
{
	NSMutableArray* result = [[NSMutableArray alloc] init];
	[result autorelease];
	
	int i;
	for (i = 0; i < [scripts_ count]; i++) {
		CMUserScript* script = [scripts_ objectAtIndex: i];
		if ([script isIncluded: url]) {
			[result addObject: [script script]];
		}
	}
	
	return result;
}

- (void) progressFinished: (NSNotification*) n
{
	WebView* webView = [n object];
	WebDataSource* dataSource = [[webView mainFrame] dataSource];
	NSURL* url = [[dataSource request] URL];
	
	NSArray* ary = [self matchedScripts: url];
	int i;
	for (i = 0; i < [ary count]; i++) {
		NSString* script = [ary objectAtIndex: i];
		[webView stringByEvaluatingJavaScriptFromString: script];
	}
}

#pragma mark Override
- (id) init
{
	// Safari?
	NSString* identifier = [[NSBundle mainBundle] bundleIdentifier];
	if (! [identifier isEqual: @"com.apple.Safari"]) {
		return nil;
	}

	NSLog(@"CMController - init");
	
	self = [super init];
	if (! self) {
		return nil;
	}
	
	scripts_ = [[NSMutableArray alloc] init];
	[self loadUserScripts];
	
	[NSBundle loadNibNamed: @"Menu.nib" owner: self];
	
	return self;
}

- (void) dealloc
{
	NSLog(@"CMController - dealloc");
	
	[scripts_ release];
	[super dealloc];
}

- (void) awakeFromNib
{
	// Menu
	NSMenuItem* item;
	
	[menu setTitle: @"'_'"];
	
	item = [[NSMenuItem alloc] init];
	[item setSubmenu: menu];
	
	[[NSApp mainMenu] addItem: item];
	[item autorelease];
	
	// Notification
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver: self
			   selector: @selector(progressFinished:)
				   name: WebViewProgressFinishedNotification
				 object: nil];
}


@end
