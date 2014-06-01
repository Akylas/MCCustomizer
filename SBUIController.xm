#import "MCCTweakController.h"
#import "PrivateHeaders.h"

%hook SBUIController

- (id)init {
    SBUIController *controller = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(currentSongChanged:)
                                                 name:@"SBMediaNowPlayingChangedNotification"
                                               object:nil];

    return controller;
}

%new
- (void)currentSongChanged:(NSNotification *)notification {
    [[MCCTweakController sharedInstance] currentSongChanged];
}

// Fix for the original lockscreen wallpaper not showing when locked and paused
- (void)cleanUpOnFrontLocked {
    %orig;

    SBMediaController *mediaController = [%c(SBMediaController) sharedInstance];
    if (!mediaController.isPlaying) {
        [MCCTweakController sharedInstance].nowPlayingImage = nil;
    }
}

%end
