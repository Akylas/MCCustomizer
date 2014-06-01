#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "_MPUSystemMediaControlsView.h"

%hook SBLockScreenView

%new
-(_UIBackdropView*) wallpaperBlurView
{
    return MSHookIvar<_UIBackdropView*>(self, "_wallpaperBlurView");
}

// - (void)layoutSubviews {
    // %orig;
    // Log(@"_mediaControlsContainerView parent %p", _mediaControlsContainerView.superview);
    // Log(@"_mediaControlsView parent %p", _mediaControlsView.superview);
//     UIImageView* artworkView = [TweakController sharedInstance].lsArtworkView;
//     if (!SHOULD_HOOK() || !BOOL_PROP(lsArtworkEnabled)) {
//         if (artworkView.superview != nil)
//                 [artworkView removeFromSuperview];
//         return;
//     }
//     SBFWallpaperView * _lockscreenWallpaperView = MSHookIvar<SBFWallpaperView *>([%c(SBWallpaperController) sharedInstance], "_lockscreenWallpaperView");

//     // _UIBackdropView * backdrop = MSHookIvar<_UIBackdropView *>(self, "_wallpaperBlurView");
//     CGRect frame = _lockscreenWallpaperView.bounds;
//     if (!CGRectIsEmpty(frame)) {
//         artworkView.frame = [UIScreen mainScreen].bounds;

//         if (artworkView.image == nil) {
//             artworkView.hidden = YES;
//         }
//         else {
//              artworkView.hidden = NO;
//             if (artworkView.superview != self)
//                 [artworkView removeFromSuperview];
//             //1 to make sure we are above the wallpaper
//             [_lockscreenWallpaperView insertSubview:artworkView atIndex:1];
//         }
//     }
// }

-(float)_mediaControlsHeight
{
    CGFloat result = %orig;
    if (!SHOULD_HOOK()) return result;
    result = getMediaControlsHeight(YES);
    // Log (@"_mediaControlsHeight %f", result);
    return result;
}

-(void)_layoutMediaControlsView 
{
    %orig;
    if (!SHOULD_HOOK()) return;
    CGRect frame = self.mediaControlsView.frame;
    frame.size.height = getMediaControlsHeight(YES);
    self.mediaControlsView.frame = frame;
    // Log (@"_layoutMediaControlsView %@", NSStringFromCGRect(frame));
}

%end
