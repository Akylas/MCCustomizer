#import "MCCTweakController.h"
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
-(SBControlCenterContainerView*)containerView
{
    return MSHookIvar<SBControlCenterContainerView*>(self, "_containerView");
}
%end

%hook SBCCMediaControlsSectionController
- (struct CGSize)contentSizeForOrientation:(long long)arg1
{
    CGSize result = %orig;
    if (!(SHOULD_HOOK() && BOOL_PROP(ccCustomLayout)))  return result;
    result.height = getMediaControlsHeight(NO);
    return result;
}

%end