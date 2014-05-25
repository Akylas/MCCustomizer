#import "TweakController.h"
#import "PrivateHeaders.h"
#import "_MPUSystemMediaControlsView.h"

%hook SBControlCenterController
%new
- (SBControlCenterViewController*)viewController
{
    return MSHookIvar<SBControlCenterViewController *>(self, "_viewController");
}
%end

%hook SBControlCenterViewController
%new
-(id)containerView
{
    return MSHookIvar<UIView*>(self, "_containerView");
}
%end

%hook SBControlCenterContentContainerView
- (void)layoutSubviews {
    %orig;
    UIImageView* artworkView = [TweakController sharedInstance].ccArtworkView;
    if (!SHOULD_HOOK() || !BOOL_PROP(ccArtworkEnabled)) {
        if (artworkView.superview != nil)
                [artworkView removeFromSuperview];
        return;
    }

    _UIBackdropView * backdrop = MSHookIvar<_UIBackdropView *>(self, "_backdropView");
    // UIView* backView = ((UIView*)self.backdropView);
    CGRect frame = backdrop.bounds;
    if (!CGRectIsEmpty(frame)) {
        artworkView.frame = [UIScreen mainScreen].bounds;

        if (artworkView.image == nil) {
            artworkView.hidden = YES;
        }
        else {
             artworkView.hidden = NO;
            if (artworkView.superview != self)
                [artworkView removeFromSuperview];
            [self insertSubview:artworkView belowSubview:backdrop];
        }

        
    }
}

%end

%hook SBCCMediaControlsSectionController
- (struct CGSize)contentSizeForOrientation:(long long)arg1
{
    CGSize result = %orig;
    if (!SHOULD_HOOK()) return result;
    result.height = getMediaControlsHeight(NO);
    // Log (@"contentSizeForOrientation %@", NSStringFromCGSize(result));
    return result;
}

%end