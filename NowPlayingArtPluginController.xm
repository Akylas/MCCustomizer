#import "TweakController.h"

%hook NowPlayingArtPluginController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [[TweakController sharedInstance] dataProviderDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    [[TweakController sharedInstance] dataProviderDidLoad];
}
%end