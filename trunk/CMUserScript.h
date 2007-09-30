/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>

@interface CMUserScript : NSObject {
	NSDictionary* metadata_;
	NSString* script_;
	
	NSMutableArray* include_;
	NSMutableArray* exclude_;
	
	NSString* fullPath_;
    
    BOOL enabled_;
}

+ (NSDictionary*) parseMetadata: (NSString*) script;

- (id) initWithString: (NSString*) script;
- (id) initWithContentsOfFile: (NSString*) path;

- (NSXMLElement*) XMLElement;
- (void) configureWithXMLElement: (NSXMLElement*) element;

- (NSMutableArray*) include;
- (NSMutableArray*) exclude;

// Getter
- (NSString*) name;
- (NSString*) namespace;
- (NSString*) description;
- (NSString*) script;
- (NSString*) basenameFromName;

- (BOOL) isInstalled: (NSString*) path;
- (BOOL) install: (NSString*) path;
- (BOOL) uninstall;

- (BOOL) isEnabled;
- (void) setEnabled: (BOOL) flag;

- (BOOL) isMatched: (NSURL*) url;

+ (NSString*) fileNameFromString: (NSString*) s;
+ (NSString*) uniqueName: (NSString*) name others: (NSArray*) others;

@end
