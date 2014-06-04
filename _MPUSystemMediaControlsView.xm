
#import "_MPUSystemMediaControlsView.h"
#import "MCCTweakController.h"
#import <objc/runtime.h>
#import <MediaPlayer/MPVolumeView.h>

@interface MPVolumeView()
@property(nonatomic) BOOL showsVolumeSlider;
@end

// static char const * const IsCCSectionKey = "IsCCSection";
static char const * const FirstLayoutKey = "FirstLayout";
static char const * const AirPlayButtonKey = "AirPlayButton";

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
    else {
        height += 10;
    }
    return height;
}

static CGRect originalTrackInformationViewFrame;
static CGRect originalTransportControlsViewFrame;
static CGRect originalTimeInformationViewFrame;
static CGRect originalVolumeViewFrame;

@interface _MPUSystemMediaControlsView()
-(BOOL)gesturesEnabled ;
-(BOOL)gesturesInversed ;
-(void)afterLayoutSubviews;
-(float)getMediaControlsHeight;
@end

@implementation _MPUSystemMediaControlsView (Additions)
@dynamic isCCSection;
@dynamic firstLayout;

- (BOOL)isCCSection {
    return ([self style] == 1);
}


- (BOOL)firstLayout {
    NSNumber *number = objc_getAssociatedObject(self, FirstLayoutKey);
    return number?[number boolValue]:TRUE; //default is true
}

- (void)setFirstLayout:(BOOL)value {
    objc_setAssociatedObject(self, FirstLayoutKey,  [NSNumber numberWithBool: value], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (MPVolumeView*)airplayButton {
    return objc_getAssociatedObject(self, AirPlayButtonKey);
}

- (void)setAirplayButton:(MPVolumeView*)value {
    objc_setAssociatedObject(self, AirPlayButtonKey, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

%hook _MPUSystemMediaControlsView

%new
-(void)afterLayoutSubviews
{
    MPVolumeView* volumeView = [self airplayButton];
    if (!SHOULD_HOOK()) {
        if (![self firstLayout]) {
            [self.volumeView setHidden:NO];
            [self.timeInformationView setHidden:NO];
            [self.trackInformationView setHidden:NO];
            [self.transportControlsView setHidden:NO];
            self.trackInformationView.frame = originalTrackInformationViewFrame;
            self.transportControlsView.frame = originalTransportControlsViewFrame;
            self.timeInformationView.frame = originalTimeInformationViewFrame;
            self.volumeView.frame = originalVolumeViewFrame;
            [volumeView setHidden:YES];
            self.firstLayout = YES;
        }
        return;
    }
    if ([self firstLayout]) {
        originalTrackInformationViewFrame = self.trackInformationView.frame;
        originalTransportControlsViewFrame = self.transportControlsView.frame;
        originalTimeInformationViewFrame = self.timeInformationView.frame;
        originalVolumeViewFrame = self.volumeView.frame;
        self.firstLayout = NO;
    }
    BOOL hideVolume, hideInfo, hideTime, hideButtons, hideAirPlay;
    BOOL isCCControl = [self isCCSection];
    MPUNowPlayingTitlesView* trackInformationView = ((MPUNowPlayingTitlesView*)self.trackInformationView);

    if (trackInformationView.titleText == nil) {
        [trackInformationView setTitleText:isCCControl?STRING_PROP(ccNoPlayingText):STRING_PROP(lsNoPlayingText)];
        BOOL oneTapToOpen = (isCCControl && BOOL_PROP(ccOneTapToOpenNoMusic)) || (!isCCControl && BOOL_PROP(lsOneTapToOpenNoMusic));
        SBApplication* app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:STRING_PROP(DefaultApp)];  
        [trackInformationView setArtistText:[NSString stringWithFormat:oneTapToOpen?@"Tap to open %@":@"Long press to open %@", [app displayName]]];
    }

    
    if (isCCControl) {
        hideVolume = !BOOL_PROP(ccShowVolume);
        hideInfo = !BOOL_PROP(ccShowInfo);
        hideTime = !BOOL_PROP(ccShowTime);
        hideButtons = !BOOL_PROP(ccShowButtons);
        hideAirPlay = !BOOL_PROP(ccShowAirplay);
    } else {
        hideVolume = !BOOL_PROP(lsShowVolume);
        hideInfo = !BOOL_PROP(lsShowInfo);
        hideTime = !BOOL_PROP(lsShowTime);
        hideButtons = !BOOL_PROP(lsShowButtons);
        hideAirPlay = !BOOL_PROP(lsShowAirplay);
    }
    [self.volumeView setHidden:hideVolume];
    [self.timeInformationView setHidden:hideTime];
    [self.trackInformationView setHidden:hideInfo];
    [self.transportControlsView setHidden:hideButtons];

    CGFloat top = timeInformationViewTop;
    CGRect frame;
    if (!hideTime) {
        top += (trackInformationViewTop - timeInformationViewTop);
    }

    if (!hideInfo) {
        frame = self.trackInformationView.frame;
        frame.origin.y = top;
        frame.size.height = trackInformationViewHeight;
        self.trackInformationView.frame = frame;
        top += (transportControlsViewTop - trackInformationViewTop);
    }

    if (!hideButtons) {
        frame = self.transportControlsView.frame;
        frame.origin.y = top;
        frame.size.height = transportControlsViewHeight;
        self.transportControlsView.frame = frame;
        top += (volumeViewTop - transportControlsViewTop);
    }
    else {
        //to add a little padding between info and volume
        top += 5;
    }
    if (!hideVolume) {
        frame = self.volumeView.frame;
        frame.origin.y = top;
        frame.size.height = volumeViewHeight;
        self.volumeView.frame = frame;
    }
    if (!hideAirPlay && volumeView) {
        [volumeView sizeToFit];
        BOOL airplayHidden = NO;
        CGRect airplayFrame = volumeView.frame;
        CGFloat width = airplayFrame.size.width + 2; //for a little right padding
        CGFloat height = airplayFrame.size.height;
        CGRect myFrame = self.bounds;
        if (!hideButtons) {
            CGRect buttonsFrame = self.transportControlsView.frame;
            airplayFrame.origin.x = CGRectGetMaxX(myFrame) - width;
            airplayFrame.origin.y = CGRectGetMidY(buttonsFrame) - height/2.0f + 10.0f; //why is not centered without the 5?
        }
        else if (!hideInfo) {
            CGRect infoFrame = self.trackInformationView.frame;
            airplayFrame.origin.x = CGRectGetMaxX(myFrame) - width;
            airplayFrame.origin.y = CGRectGetMidY(infoFrame) - height/2.0f;
            infoFrame.size.width -= 2*width;
            infoFrame.origin.x = width;
            self.trackInformationView.frame = infoFrame;
        }
        else {
            airplayHidden = YES;
        }
        volumeView.hidden = airplayHidden;        
        volumeView.frame = airplayFrame;
    }
    else {
        [volumeView setHidden:YES];    
    }
}

// -(void)setFrame:(CGRect)frame {
//     if (SHOULD_HOOK()) {
//         frame.size.height = [self getMediaControlsHeight];
//     }
//     %orig(frame);

//     Log(@"setFrame %@ %@", BOOL_TO_STRING([self isCCSection]), NSStringFromCGRect(frame));
// }

// -(CGRect)frame {
//     CGRect result = %orig;
//     if (SHOULD_HOOK()) {
//         result.size.height = [self getMediaControlsHeight];
//     }
//     Log(@"getFrame %@", NSStringFromCGRect(result));
//     return result;
// }

%new
-(float)getMediaControlsHeight
{
    return getMediaControlsHeight(![self isCCSection]);
}

// - (void)setFrame:(CGRect)frame {
//     frame.size.height =  [self getMediaControlsHeight];
//     %orig(frame);
//     Log(@"setFrame %@", NSStringFromCGRect(frame));
// }

- (void)layoutSubviews {
    %orig;
    Log(@"layoutSubviews");
    [self afterLayoutSubviews];
}

- (void)_layoutSubviewsControlCenteriPad {
    %orig;
    [self afterLayoutSubviews];
}

-(id)initWithStyle:(int)arg1 {
    UIView* view = %orig;
    UISwipeGestureRecognizer *swipeReco = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftGesture:)];
    [swipeReco setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [view addGestureRecognizer:swipeReco];

    swipeReco = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightGesture:)];
    [swipeReco setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [view addGestureRecognizer:swipeReco];

    UILongPressGestureRecognizer *longPressReco = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
    longPressReco.delegate = (id<UILongPressGestureRecognizerDelegate>)self;
    [view addGestureRecognizer:longPressReco];

    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    [volumeView setShowsVolumeSlider:NO];
    [volumeView setHidden:!SHOULD_HOOK()];
    [volumeView sizeToFit];
    [view addSubview:volumeView];
    [self setAirplayButton:volumeView];
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
-(BOOL)gesturesInversed 
{
    return BOOL_PROP(gesturesInversed);
}

%new
- (void) handleDoubleTap:(UIGestureRecognizer*) sender
{
    if (![self gesturesEnabled]) return;
}

%new
-(void)handleSwipeLeftGesture:(UISwipeGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    [[%c(SBMediaController) sharedInstance] changeTrack:[self gesturesInversed]?-1:1];
}

%new
-(void)handleSwipeRightGesture:(UISwipeGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    [[%c(SBMediaController) sharedInstance] changeTrack:[self gesturesInversed]?1:-1];
}

%new
-(void)handleLongPressGesture:(UILongPressGestureRecognizer*)sender
{
    if (![self gesturesEnabled]) return;
    if (sender.state == UIGestureRecognizerStateEnded) {
    } else if (sender.state == UIGestureRecognizerStateBegan) {
        SBApplication* app = [[%c(SBMediaController) sharedInstance] nowPlayingApplication];
        NSString* defaultApp = STRING_PROP(DefaultApp);
        if (BOOL_PROP(alwaysUseDefaultApp) || !app) {
            [[%c(SBUIController) sharedInstance] activateApplicationAnimated:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:defaultApp]];
        }
        else {
            [[%c(SBUIController) sharedInstance] activateApplicationAnimated:app];
        }
    }
}
%end
