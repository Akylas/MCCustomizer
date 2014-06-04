#import "MCCTweakController.h"
#import "PrivateHeaders.h"


%hook NowPlayingArtPluginController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [[MCCTweakController sharedInstance] dataProviderDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [[MCCTweakController sharedInstance] dataProviderDidLoad];
}

%end