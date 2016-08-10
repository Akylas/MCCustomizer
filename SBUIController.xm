#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "MediaRemote.h"
dispatch_queue_t backgroundQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.something.myapp.backgroundQueue", 0);
    });
    return queue;
}
%hook SBUIController

- (id)init {
    SBUIController *controller = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self
       selector:@selector(currentSongChanged:)
       name:@"SBMediaNowPlayingChangedNotification"
       object:nil];
    MRMediaRemoteRegisterForNowPlayingNotifications(backgroundQueue());
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            // Log(@"kMRMediaRemoteNowPlayingInfoDidChangeNotification %@", NSStringFromClass([notification.userInfo class]));
        [[MCCTweakController sharedInstance] playingInfoChanged];
        }];
    // [center addObserverForName:(__bridge NSString *)kMRMediaRemoteNowPlayingPlaybackQueueDidChangeNotification
    //     object:nil
    //     queue:[NSOperationQueue mainQueue]
    //     usingBlock:^(NSNotification *notification) {
    //         Log(@"kMRMediaRemoteNowPlayingPlaybackQueueDidChangeNotification");
    //         [[MCCTweakController sharedInstance] currentSongChanged];
    //     }];
    //     [center addObserverForName:(__bridge NSString *)kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification
    //     object:nil
    //     queue:[NSOperationQueue mainQueue]
    //     usingBlock:^(NSNotification *notification) {
    //         Log(@"kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification");
    //     }];
    return controller;
}

%new
- (void)currentSongChanged:(NSNotification *)notification {
    Log(@"SBMediaNowPlayingChangedNotification %@", NSStringFromClass([notification.userInfo class]));
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
