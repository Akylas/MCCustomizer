#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "MPUSystemMediaControlsView.h"
#import "ColorArt/SLColorArt.h"


%hook SBControlCenterContentView

-(id)initWithFrame:(CGRect)arg1 {
    SBControlCenterContentView* view = %orig;
    view.tintColor = DEFAULT_TINT_COLOR;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:kMRMCCColorArtDidChangeNotification
        object:nil
        queue:[NSOperationQueue mainQueue]
        usingBlock:^(NSNotification *notification) {
            SLColorArt *colorArt = (SLColorArt*)[notification.userInfo objectForKey:@"colorArt"];
            Log(@"SBControlCenterContentView colorArt");

            if (colorArt) {
                view.tintColor =  colorArt.primaryColor;
            }
            else {
                view.tintColor = DEFAULT_TINT_COLOR;
            }
        }];

    return view;
}
%end

%hook SBControlCenterController
%new
- (SBControlCenterViewController*)viewController
{
    return MSHookIvar<SBControlCenterViewController *>(self, "_viewController");
}

%new
- (void)updateStatusText:(NSString*)text
{
    SBControlCenterGrabberView* grabberView = [self.viewController contentView].grabberView;
    if ([grabberView respondsToSelector:@selector(presentStatusUpdate:)])
    {
        [grabberView presentStatusUpdate:[%c(SBControlCenterStatusUpdate) statusUpdateWithString:text reason:kMCCId]];
    }
    else {
        [grabberView updateStatusText:text reason:kMCCId];
    }
}

// +(void)notifyControlCenterControl:(id)control didActivate:(BOOL)activate 
// {
//     Log(@"notifyControlCenterControl %@", control);
//     %orig;
// }

%end

%hook SBControlCenterViewController
%new
-(SBControlCenterContainerView*)containerView
{
    return MSHookIvar<SBControlCenterContainerView*>(self, "_containerView");
}
%new
-(SBControlCenterContentView*)contentView
{
    return MSHookIvar<SBControlCenterContentView*>(self, "_contentView");
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