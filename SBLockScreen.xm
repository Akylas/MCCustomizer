#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "_MPUSystemMediaControlsView.h"

%hook SBLockScreenPlugin

-(void)setOverlay:(id)arg1
{
    if (SHOULD_HOOK() && BOOL_PROP(lsArtworkEnabled) && [MSHookIvar<NSString*>(self, "_bundleName") isEqualToString:@"NowPlayingArtLockScreen"]) {
        return;
    }
    %orig;
}
%end

%hook SBLockScreenView

-(void)_layoutMediaControlsView
{
    %orig;
    if (!(SHOULD_HOOK() && BOOL_PROP(lsCustomLayout)))  return;
    float height = getMediaControlsHeight(YES);
    UIView* view = MSHookIvar<UIView*>(self, "_mediaControlsContainerView");
    CGRect frame = view.frame;
    frame.size.height = height;
    view.frame = frame;
}
%new
-(_UIBackdropView*) wallpaperBlurView
{
    return MSHookIvar<_UIBackdropView*>(self, "_wallpaperBlurView");
}

%end
