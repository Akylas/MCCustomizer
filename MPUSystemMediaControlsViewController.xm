#import "_MPUSystemMediaControlsView.h"
#import "TweakController.h"

@interface _MPUSystemMediaControlsView(gestures)
-(BOOL)gesturesEnabled;
@end

%hook MPUSystemMediaControlsViewController

%new
-(_MPUSystemMediaControlsView*)mediaControlsView
{
    return MSHookIvar<_MPUSystemMediaControlsView*>(self, "_mediaControlsView");
}

-(void)mediaControlsTitlesViewWasTapped:(id)arg1 
{
    if (![[self mediaControlsView] gesturesEnabled]) {
        %orig;
    }
    else {
        BOOL isCCControl = [[self mediaControlsView] isCCSection];
        if ((isCCControl && !BOOL_PROP(ccShowButtons) ) || (!isCCControl && !BOOL_PROP(lsShowButtons))) {
            [[%c(SBMediaController) sharedInstance] togglePlayPause];
        }
    }
}

-(void)viewWillAppear:(BOOL)arg1
{
    UIView* superview = [self.view superview];
    if ([superview isKindOfClass:%c(SBControlCenterSectionView)]) {
        [self.mediaControlsView setIsCCSection:YES];
    }
    %orig;
}

%new
-(UIView*)volumeView
{
    return (UIView*)[self.mediaControlsView volumeView];
}
%end
