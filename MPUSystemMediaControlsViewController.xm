#import "_MPUSystemMediaControlsView.h"

%hook MPUSystemMediaControlsViewController

%new
-(_MPUSystemMediaControlsView*)mediaControlsView
{
    return MSHookIvar<_MPUSystemMediaControlsView*>(self, "_mediaControlsView");
}

// -(void)mediaControlsTitlesViewWasTapped:(id)arg1 
// {
//     %log;
// }
// -(void)trackActioningObject:(id)arg1 didSelectAction:(int)arg2 atIndex:(int)arg3
// {
//     %log;
// }

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
