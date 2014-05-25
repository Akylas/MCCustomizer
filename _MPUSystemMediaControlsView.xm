
#import "_MPUSystemMediaControlsView.h"
#import "TweakController.h"
#import <objc/runtime.h>

static char const * const IsCCSectionKey = "IsCCSection";

#define volumeViewHeight 49.000000
#define timeInformationViewHeight 34.000000
#define trackInformationViewHeight 40.000000
#define transportControlsViewHeight 52.000000

#define volumeViewTop 101.000000
#define timeInformationViewTop 3.000000
#define trackInformationViewTop 31.000000
#define transportControlsViewTop 58.000000

float getMediaControlsHeight(BOOL isLS)
{
    BOOL hideVolume, hideInfo, hideTime, hideButtons;
    if (isLS) {
        hideVolume = !BOOL_PROP(lsShowVolume);
        hideInfo = !BOOL_PROP(lsShowInfo);
        hideTime = !BOOL_PROP(lsShowTime);
        hideButtons = !BOOL_PROP(lsShowButtons);
    } else {
        hideVolume = !BOOL_PROP(ccShowVolume);
        hideInfo = !BOOL_PROP(ccShowInfo);
        hideTime = !BOOL_PROP(ccShowTime);
        hideButtons = !BOOL_PROP(ccShowButtons);
        
        
    }

    CGFloat height = 0;
    CGFloat top = timeInformationViewTop;
    if (!hideTime) {
        height = MAX(height, top + timeInformationViewHeight);
        top += (trackInformationViewTop - timeInformationViewTop);
    }
    if (!hideInfo) {
        height = MAX(height, top + trackInformationViewHeight);
        top += (transportControlsViewTop - trackInformationViewTop);
    }
    if (!hideButtons) {
        height = MAX(height, top + transportControlsViewHeight);
        top += (volumeViewTop - transportControlsViewTop);
    }
    if (!hideVolume) {
        height = MAX(height, top + volumeViewHeight);
    }
    return height;
}


@interface _MPUSystemMediaControlsView()
-(BOOL)gesturesEnabled ;
-(void)afterLayoutSubviews;
@end

@implementation _MPUSystemMediaControlsView (Additions)
@dynamic isCCSection;

- (BOOL)isCCSection {
    NSNumber *number = objc_getAssociatedObject(self, IsCCSectionKey);
    return number?[number boolValue]:FALSE; 
}

- (void)setIsCCSection:(BOOL)value {
    objc_setAssociatedObject(self, IsCCSectionKey,  [NSNumber numberWithBool: value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

%hook _MPUSystemMediaControlsView

%new
-(void)afterLayoutSubviews
{
    if (!SHOULD_HOOK()) return;
    BOOL hideVolume, hideInfo, hideTime, hideButtons;
    BOOL isCCControl = [self isCCSection];
    MPUNowPlayingTitlesView* trackInformationView = ((MPUNowPlayingTitlesView*)self.trackInformationView);

    if (trackInformationView.titleText == nil) {
        [trackInformationView setTitleText:isCCControl?STRING_PROP(ccNoPlayingText):STRING_PROP(lsNoPlayingText)];
    }

    
    if (isCCControl) {
        hideVolume = !BOOL_PROP(ccShowVolume);
        hideInfo = !BOOL_PROP(ccShowInfo);
        hideTime = !BOOL_PROP(ccShowTime);
        hideButtons = !BOOL_PROP(ccShowButtons);
    } else {
        hideVolume = !BOOL_PROP(lsShowVolume);
        hideInfo = !BOOL_PROP(lsShowInfo);
        hideTime = !BOOL_PROP(lsShowTime);
        hideButtons = !BOOL_PROP(lsShowButtons);
        
    }
    [self.volumeView setHidden:hideVolume];
    [self.timeInformationView setHidden:hideTime];
    [self.trackInformationView setHidden:hideInfo];
    [self.transportControlsView setHidden:hideButtons];

    CGFloat top = timeInformationViewTop;
    if (!hideTime) {
        top += (trackInformationViewTop - timeInformationViewTop);
    }
    CGRect frame = self.trackInformationView.frame;
    frame.origin.y = top;
    frame.size.height = trackInformationViewHeight;
    self.trackInformationView.frame = frame;

    if (!hideInfo) {
        top += (transportControlsViewTop - trackInformationViewTop);
    }
    frame = self.transportControlsView.frame;
    frame.origin.y = top;
    frame.size.height = transportControlsViewHeight;
    self.transportControlsView.frame = frame;

    if (!hideButtons) {
        top += (volumeViewTop - transportControlsViewTop);
    }
    frame = self.volumeView.frame;
    frame.origin.y = top;
    frame.size.height = volumeViewHeight;
    self.volumeView.frame = frame;
}

- (void)layoutSubviews {
    %orig;
    [self afterLayoutSubviews];
}

- (void)_layoutSubviewsControlCenteriPad {
    %orig;
    [self afterLayoutSubviews];
}

-(id)initWithStyle:(int)arg1 {
    id view = %orig;

    UISwipeGestureRecognizer *swipeReco = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftGesture:)];
    [swipeReco setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [view addGestureRecognizer:swipeReco];

    swipeReco = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightGesture:)];
    [swipeReco setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [view addGestureRecognizer:swipeReco];

    UITapGestureRecognizer* singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.cancelsTouchesInView = NO;
    singleTap.delaysTouchesBegan = YES;
    singleTap.delaysTouchesEnded = YES;
    [singleTap setNumberOfTapsRequired:1];

    UILongPressGestureRecognizer *longPressReco = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    [view addGestureRecognizer:longPressReco];
    [singleTap requireGestureRecognizerToFail:longPressReco];

    MPUNowPlayingTitlesView* trackInformationView = ((MPUNowPlayingTitlesView*)self.trackInformationView);
    
    trackInformationView.userInteractionEnabled = YES;
    [trackInformationView addGestureRecognizer:singleTap];

    
    return view;
}

%new
-(BOOL)gesturesEnabled 
{
    if (!SHOULD_HOOK()) return false;
    BOOL isCCControl = [self isCCSection];
    return ((isCCControl && BOOL_PROP(ccGesturesEnabled)) || (!isCCControl && BOOL_PROP(lsGesturesEnabled)));
}


%new
- (void) handleDoubleTap:(UIGestureRecognizer*) sender
{
    if (![self gesturesEnabled]) return;
}

%new
- (void) handleSingleTap:(UIGestureRecognizer*) sender
{
    if (!SHOULD_HOOK()) return;
    BOOL isCCControl = [self isCCSection];
    if ((isCCControl && !BOOL_PROP(ccShowButtons) ) || (!isCCControl && !BOOL_PROP(lsShowButtons))) {
        // Log(@"handleSingleTap");
        [[%c(SBMediaController) sharedInstance] togglePlayPause];
    }
}

%new
-(void)handleSwipeLeftGesture:(UISwipeGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    [[%c(SBMediaController) sharedInstance] changeTrack:1];
}

%new
-(void)handleSwipeRightGesture:(UISwipeGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    [[%c(SBMediaController) sharedInstance] changeTrack:-1];
}

%new
-(void)handleLongPressGesture:(UILongPressGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    if (sender.state == UIGestureRecognizerStateEnded) {
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        SBApplication* app = [[%c(SBMediaController) sharedInstance] nowPlayingApplication];
        if (app) {
            [[%c(SBUIController) sharedInstance] activateApplicationAnimated:app];
        }
        else {
            NSString* defaultApp = STRING_PROP(DefaultApp);
            Log(@"handleLongPressGesture %@", defaultApp);
            [[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:defaultApp]];
        }
    }
}
%end
