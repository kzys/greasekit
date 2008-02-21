//
//  GKGMObjectTest.m
//  GreaseKit
//
//  Created by Björn Dannemann on 14.02.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "GKGMObjectTest.h"
#import "GKGMObject.h"

@implementation GKGMObjectTest



- (void) testLog
{
	GKGMObject* myObject;
	
	myObject = [[GKGMObject alloc] init];	
	[myObject gmLog:@"Hallo"];
}

- (void) testValueForKeyWithSetBefore
{
    GKGMObject* myObject;
	
	myObject = [[GKGMObject alloc] init];	
	STAssertNotNil(myObject, @"was nil");
	// set values
	STAssertNil([myObject gmSetValue: @"newValue1" forKey: @"key1" scriptName: @"script" namespace: @"ns" ], @"should be nil, cause this method should never return a vale");
	STAssertNil([myObject gmSetValue: @"newValue2" forKey: @"key2" scriptName: @"script" namespace: @"ns" ], @"should be nil, cause this method should never return a vale");

	STAssertEqualObjects([myObject gmValueForKey: @"key1" defaultValue: @"def" scriptName: @"script" namespace: @"ns" ], @"newValue1", @"wrong return value");	
	STAssertEqualObjects([myObject gmValueForKey: @"key2" defaultValue: @"def" scriptName: @"script" namespace: @"ns" ], @"newValue2", @"wrong return value");
	[myObject release];
	
	myObject = [[GKGMObject alloc] init];	
	STAssertNotNil(myObject, @"was nil");

	STAssertEqualObjects([myObject gmValueForKey: @"key1" defaultValue: @"def" scriptName: @"script" namespace: @"ns" ], @"newValue1", @"wrong return value");	
	STAssertEqualObjects([myObject gmValueForKey: @"key2" defaultValue: @"def" scriptName: @"script" namespace: @"ns" ], @"newValue2", @"wrong return value");

	[myObject release];

}

- (void) testValueForKeyWithoutData
{
    GKGMObject* myObject;
	
	myObject = [[GKGMObject alloc] init];	
	STAssertNotNil(myObject, @"was nil");
	// set values
	STAssertNil([myObject gmSetValue: @"newValue2" forKey: @"key1" scriptName: @"script" namespace: @"ns" ], @"should be nil, cause this method should never return a vale");

	STAssertEqualObjects([myObject gmValueForKey: @"key1" defaultValue: @"def1" scriptName: @"script2" namespace: @"ns" ], @"def1", @"wrong return value");	
	STAssertEqualObjects([myObject gmValueForKey: @"key9" defaultValue: @"def2" scriptName: @"script" namespace: @"ns" ], @"def2", @"wrong return value");
	STAssertEqualObjects([myObject gmValueForKey: @"key10" defaultValue: @"" scriptName: @"script" namespace: @"ns" ], @"", @"wrong return value");


}

@end
