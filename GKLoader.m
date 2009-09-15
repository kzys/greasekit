#import "GKLoader.h"
#import "CMController.h"

static NSString* APPS_PATH = @"~/Library/Application Support/GreaseKit/apps.plist";

@implementation GKLoader

+ (void) saveApplicationList: (NSArray*) apps
{
    NSString* path = [APPS_PATH stringByExpandingTildeInPath];
    [apps writeToFile: path atomically: YES];
}

+ (void) load
{
    NSString* path = [APPS_PATH stringByExpandingTildeInPath];

    // load application list
    NSArray* apps = [[NSArray alloc] initWithContentsOfFile: path];
    if (apps && [apps count] > 0) {
        ;
    } else {
        [apps release];
        apps = [[NSArray alloc] initWithObjects: @"com.apple.Safari", @"com.factorycity.DietPibb", @"com.mailplaneapp.Mailplane", nil];
    }

    NSString* identifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([apps containsObject: identifier]) {
        [[CMController alloc] initWithApplications: apps];
    }

    [apps release];
}
@end
