#import "_MPUSystemMediaControlsView.h"
#import "MCCTweakController.h"

@interface _MPUSystemMediaControlsView(gestures)
-(BOOL)gesturesEnabled;
-(UIView*)artworkView;
@end

%hook MPUSystemMediaControlsViewController

%new
-(_MPUSystemMediaControlsView*)mediaControlsView
{
    return MSHookIvar<_MPUSystemMediaControlsView*>(self, "_mediaControlsView");
}

-(void)mediaControlsTitlesViewWasTapped:(id)arg1 
{
    BOOL hasData = [[%c(SBMediaController) sharedInstance] nowPlayingApplication] != nil;
    BOOL isCCControl = [[self mediaControlsView] isCCSection];
    if (hasData) {
        if (![[self mediaControlsView] gesturesEnabled]) {
            %orig;
        }
        else if ((isCCControl && !BOOL_PROP(ccShowButtons) ) || (!isCCControl && !BOOL_PROP(lsShowButtons))) {
            [MCCTweakController runAction:kMCCActionTogglePlayPause];
            if (isCCControl && BOOL_PROP(ccHideOnPlayPause)) {
                [[%c(SBControlCenterController) sharedInstanceIfExists] dismissAnimated:YES];
            }
        }
    }
    else {
        if ((isCCControl && BOOL_PROP(ccOneTapToOpenNoMusic) ) || (!isCCControl && BOOL_PROP(lsOneTapToOpenNoMusic))) {
            NSString* defaultApp = STRING_PROP(DefaultApp);
            [[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:defaultApp]];
        }
    }
}
-(void)nowPlayingController:(id)arg1 nowPlayingInfoDidChange:(id)arg2
{
    %orig;
    BOOL current = [[self artworkView] isHidden];
    BOOL newHidden  = BOOL_PROP(lsHideDefaultArtwork);
    if (current != newHidden) {
        [[self artworkView] setHidden:newHidden];
    }
}
%end
