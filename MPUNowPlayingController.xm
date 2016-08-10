#import "MCCTweakController.h"
#import "PrivateHeaders.h"



%hook MPUNowPlayingController

-(id)init{
    id result = %orig;
    [MCCTweakController sharedInstance].npController = result;
    return result;
}

// -(void)_updateCurrentNowPlaying
// {
//     %orig;
//    Log(@"_updateCurrentNowPlaying");
//     // NSDictionary* dict = MSHookIvar<NSDictionary*>(self, "_currentNowPlayingInfo");
//     [MCCTweakController sharedInstance].npController = self;
//     // [[MCCTweakController sharedInstance] currentSongChanged];
//     // [[MCCTweakController sharedInstance] updateNowPlaying:dict withController:self];
//     // Log(@"_updateCurrentNowPlaying art %p", [self currentNowPlayingArtwork]);

// }

// -(void)_updatePlaybackState{
//     %orig;
//    Log(@"_updatePlaybackState");
//     // [[MCCTweakController sharedInstance] currentSongChanged];
// }
%end