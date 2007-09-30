#import "GKLoader.h"
#import "CMController.h"

static NSString* APPS_PATH = @"~/Library/Application Support/GreaseKit/apps.plist";

@implementation GKLoader
+ (NSArray*) createDefaultApplicationList
{
    NSString* path = [APPS_PATH stringByExpandingTildeInPath];

    NSFileManager* manager;
    manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath: [path stringByDeletingLastPathComponent]
                        attributes: nil];

    return [NSArray arrayWithObject: @"com.apple.Safari"];
}

+ (void) saveApplicationList: (NSArray*) apps
{
    NSString* path = [APPS_PATH stringByExpandingTildeInPath];

    NSFileManager* manager;
    manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath: [path stringByDeletingLastPathComponent]
                        attributes: nil];

    [apps writeToFile: path atomically: YES];
}

+ (void) load
{
    NSString* path = [APPS_PATH stringByExpandingTildeInPath];
    NSArray* apps = [NSArray arrayWithContentsOfFile: path];
    if (! apps) {
        apps = [self createDefaultApplicationList];
    }

    NSString* identifier = [[NSBundle mainBundle] bundleIdentifier];

    if ([apps containsObject: identifier]) {
        [[CMController alloc] init];
    }
}
@end
