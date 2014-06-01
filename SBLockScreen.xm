#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "_MPUSystemMediaControlsView.h"

%hook SBLockScreenPlugin

-(void)setOverlay:(id)arg1
{
    if (BOOL_PROP(lsArtworkEnabled) && [MSHookIvar<NSString*>(self, "_bundleName") isEqualToString:@"NowPlayingArtLockScreen"]) {
        return;
    }
    %orig;
}
%end

%hook SBLockScreenViewController
-(void)_setNowPlayingControllerEnabled:(BOOL)arg1 
{
    if (!BOOL_PROP(lsHideDefaultArtwork)) {
        %orig;
    }
}
%end
%hook SBLockScreenView

%new
-(_UIBackdropView*) wallpaperBlurView
{
    return MSHookIvar<_UIBackdropView*>(self, "_wallpaperBlurView");
}

%end
