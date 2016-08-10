#import <CommonCrypto/CommonDigest.h>
#import <MediaPlayer/MPVolumeView.h>
#import <libactivator/libactivator.h>
#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import "UIAlertController+Blocks.h"
#import "ColorArt/SLColorArt.h"
#import "FSSwitchPanel.h"
#import "FSSwitchState.h"

#define MAX_COVER_TEST 3
// #define SPOTIFY_DEFAULT_COVER_MD5 @"678514434ad5b105fa6f12148daeca8c"
#define SPOTIFY_DEFAULT_COVER_MD5 @"6d6f147ee0dd1280d71112d79e5e20d2"

extern "C" void                      _SBControlCenterControlSettingsDidChangeForKey(NSString * key);


@interface MPVolumeView() 
- (UIImage *)routeButtonImageForState:(UIControlState)state;
- (UIImage *)_defaultRouteButtonImageAsSelected:(BOOL)selected;
- (void)setRouteButtonImage:(UIImage *)image
                   forState:(UIControlState)state;
@end

static CGPoint lastTapCentroid;
%hook SBHandMotionExtractor

- (void)extractHandMotionForActiveTouches:(void *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid
{
    if (count && !isnan(centroid.x) && !isnan(centroid.y))
        lastTapCentroid = centroid;
    %orig;
}

%end

%hook MPVolumeView
- (void)setRouteButtonImage:(UIImage *)image
                   forState:(UIControlState)state {

    if (state == UIControlStateNormal) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    %orig(image, state);
}


-(void)_createSubviews {
    %orig;
    // Log(@"MPVolumeView didMoveToWindow");
    UIImage* image = [self _defaultRouteButtonImageAsSelected:NO];
    // Log(@"MPVolumeView test %p", image);
    if (image) {
        [self setRouteButtonImage:image forState:UIControlStateNormal];
    }
}
%end

%hook FSSwitchPanel
- (UIImage *)imageOfSwitchState:(FSSwitchState)state controlState:(UIControlState)controlState scale:(CGFloat)scale forSwitchIdentifier:(NSString *)switchIdentifier usingLayerSet:(NSString *)layerSet inTemplate:(NSBundle *)templateBundle
{
    UIImage* image = %orig;
    if (state == FSSwitchStateOn) {
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return image;
}
%end

%hook SBUIControlCenterSlider
+ (id)_knobImage {
    id image = %orig;
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}
%end


@implementation MCCTweakController
{
    UIImageView *_ccArtworkView;
    UIImageView *_lsArtworkView;
    BOOL _didLoadSettings;

    NSString *nowPlayingTitle;
    NSString *nowPlayingArtist;
    NSString *nowPlayingAlbum;
    UIImage *_nowPlayingImage;
    SLColorArt *_nowPlayingColorArt;
    NSString* _currentCoverMD5;
    BOOL _currentlyHidden;

    SBLockScreenView* _lockscreenView;

    CGFloat _ccArtworkViewAlpha;
    CGFloat _lsArtworkViewAlpha;

    BOOL _coverArtShouldChange;
    BOOL _playing;
    NSInteger _coverArtTestCount;
    NSArray* _supportedActions;
    NSArray* _timerTimes;

    UIWindow *_alertWindow;
    UIAlertController *_alertController;
    NSTimer* _sleepTimer;
    MPUNowPlayingController* _npController;
}
@synthesize nowPlayingImage = _nowPlayingImage;
@synthesize npController = _npController;

+ (instancetype)sharedInstance {

    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;

}

- (NSDictionary*)settings {

    if (!_didLoadSettings) {

        //  Load settings plist
        NSDictionary * settings = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];

        if (!settings)
            return _settings;

        [self applySettings:settings];

    }

    return _settings;
}

- (instancetype)init {

    self = [super init];

    if (self) {
        _supportedActions = @[kMCCActionStartTimer,
            kMCCActionTogglePlayPause,
            kMCCActionPlay,
            kMCCActionPause,
            kMCCActionStop,
            kMCCActionNextTrack,
            kMCCActionPreviousTrack,
            kMCCActionToggleRepeat,
            kMCCActionToggleShuffle];
        _timerTimes = @[@(1), @(10), @(20), @(30), @(40), @(50), 
            @(60), @(70), @(80), @(90), @(100), @(110), 
            @(120), @(130), @(140), @(150), @(160), @(170), @(180)];
        id<LAListener> listener = (id<LAListener>)self;
        for (NSString* key in _supportedActions)
        {
            [LASharedActivator registerListener:listener forName:key];
        }
        _coverArtShouldChange = NO;
        _playing = NO;
        _currentlyHidden = YES;
        _ccArtworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _ccArtworkView.contentMode = UIViewContentModeScaleAspectFill;
        _ccArtworkViewAlpha = 1.0f;

        _lsArtworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _lsArtworkView.contentMode = UIViewContentModeScaleAspectFill;
        _lsArtworkViewAlpha = 1.0f;
        _settings = [NSMutableDictionary dictionaryWithDictionary:@{
            @"TweakEnabled":@(YES),
            @"ColorArtEnabled":@(YES),
            @"ccArtworkEnabled":@(YES),
            @"lsArtworkEnabled":@(YES),
            @"ccCustomLayout":@(YES),
            @"lsCustomLayout":@(YES),
            @"lsShowVolume":@(YES),
            @"lsShowTime":@(YES),
            @"lsShowButtons":@(YES),
            @"lsShowInfo":@(YES),
            @"ccShowVolume":@(YES),
            @"ccShowTime":@(YES),
            @"ccShowButtons":@(YES),
            @"ccShowInfo":@(YES),
            @"ccGesturesEnabled":@(YES),
            @"lsGesturesEnabled":@(YES),
            @"gesturesInversed":@(NO),
            @"ccNoPlayingText":@"No Music playing",
            @"lsNoPlayingText":@"No Music playing",
            @"ccArtworkOpacity":@(1.0),
            @"lsArtworkOpacity":@(1.0),
            @"ccArtworkScaleToFit":@(NO),
            @"lsArtworkScaleToFit":@(NO),
            @"ccOneTapToOpenNoMusic":@(YES),
            @"lsOneTapToOpenNoMusic":@(YES),
            @"ccHideOnPlayPause":@(NO),
            @"lsHideDefaultArtwork":@(NO),
            @"ccShowAirplay":@(NO),
            @"lsShowAirplay":@(NO),
            @"ccShowMenuButton":@(NO),
            @"lsShowMenuButton":@(NO),
            @"DefaultApp":@"com.apple.Music",
            @"alwaysUseDefaultApp":@(NO),
        }];
        _didLoadSettings = NO;
}

return self;
}

-(void)updateStatusText:(NSString*)text {
    SBControlCenterController *ccController = [%c(SBControlCenterController) sharedInstanceIfExists];
    if (ccController) {
        [ccController updateStatusText:text];
    }
}

-(void)showAlertController:(UIAlertController*)controller {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController* presentationController =  controller.popoverPresentationController;
        presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        presentationController.delegate = self;
    }
    // [controller showAlertInViewController:[self alertWindow].rootViewController];
    [[self alertWindow].rootViewController presentViewController:controller animated:YES completion:nil];
}

-(UIWindow*)alertWindow {
    if (!_alertWindow) {
        _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _alertWindow.windowLevel = 10500.1f /*UIWindowLevelStatusBar*/;
        _alertWindow.hidden = NO;
        _alertWindow.rootViewController = [[UIViewController alloc] init];
    }
    if ([_alertWindow respondsToSelector:@selector(_updateToInterfaceOrientation:animated:)]) {
        [_alertWindow _updateToInterfaceOrientation:[(SpringBoard*)[NSClassFromString(@"SpringBoard") sharedApplication] _frontMostAppOrientation] animated:NO];
    }
    return _alertWindow;
}

-(void)showTimeAlertController 
{
    // Log(@"showTimeAlertController");
    _alertController = [UIAlertController alertControllerWithTitle:@"Define sleep timer duration"
      message:nil
      preferredStyle:UIAlertControllerStyleActionSheet];

    // ObjC Fast Enumeration
    for (NSNumber *timeInMinutes in _timerTimes) {
        UIAlertAction* theAction = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ min", timeInMinutes]
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * action){
              [self fireClickEventWithAction:action];
              [self cleanAlertWindow];
          }];
        [_alertController addAction:theAction];
    }
    [_alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel
        handler:^(UIAlertAction * action){
            // Log(@"cancel button");
          // [_alertController dismissViewControllerAnimated:YES completion:^{
            [self cleanAlertWindow];
        // }];
        }]];
    [self showAlertController:_alertController];

}

-(void)showTimerAlert
{
    // Log(@"showTimerAlert");
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [self showTimeAlertController];
        return;
    }
    // Log(@"showTimerAlert real");
    // UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    // actionSheet.title = @"Define sleep timer duration";
    // actionSheet.delegate = (id<UIActionSheetDelegate>)self;

    // // ObjC Fast Enumeration
    // for (NSNumber *timeInMinutes in _timerTimes) {
    //     [actionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@ min", timeInMinutes]];
    // }

    // NSInteger cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];

    // if (!_alertWindow) {
    //     _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    //     _alertWindow.windowLevel = 1050.1f /*UIWindowLevelStatusBar*/;
    //     _alertWindow.hidden = NO;
    //     _alertWindow.rootViewController = [[UIViewController alloc] init];
    // }
    
    // if ([_alertWindow respondsToSelector:@selector(_updateToInterfaceOrientation:animated:)]) {
    //     [_alertWindow _updateToInterfaceOrientation:[(SpringBoard*)[NSClassFromString(@"SpringBoard") sharedApplication] _frontMostAppOrientation] animated:NO];
    // }
    // if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    //     CGRect bounds;
    //     if ((lastTapCentroid.x == 0.0f) || (lastTapCentroid.y == 0.0f) || isnan(lastTapCentroid.x) || isnan(lastTapCentroid.y)) {
    //         bounds = _alertWindow.rootViewController.view.bounds;
    //         bounds.origin.y += bounds.size.height;
    //         bounds.size.height = 0.0f;
    //     } else {
    //         bounds.origin.x = lastTapCentroid.x - 1.0f;
    //         bounds.origin.y = lastTapCentroid.y - 1.0f;
    //         bounds.size.width = 2.0f;
    //         bounds.size.height = 2.0f;
    //     }
    //     [actionSheet showFromRect:bounds inView:_alertWindow.rootViewController.view animated:YES];
    // } else {
    //     actionSheet.cancelButtonIndex = cancelButtonIndex;
    //     [actionSheet showInView:_alertWindow.rootViewController.view];
    // }
}

-(void)runAction:(NSString*)action withObject:(id)object {
    // Log(@"runAction %@", action);
    NSString* statusText;
    SBMediaController* controller = [%c(SBMediaController) sharedInstance];
    if ([action isEqualToString:kMCCActionTogglePlayPause]) {
        statusText = [controller isPaused]?@"Play":@"Pause";
        [controller togglePlayPause];
    } else if ([action isEqualToString:kMCCActionPlay]) {
        statusText = @"Play";
        [controller play];
    } else if ([action isEqualToString:kMCCActionPause]) {
        statusText = @"Pause";
        [controller pause];
    } else if ([action isEqualToString:kMCCActionStop]) {
        statusText = @"Stop";
        [controller stop];
    } else if ([action isEqualToString:kMCCActionNextTrack]) {
        statusText = @"Next track";
        [controller changeTrack:1];
    } else if ([action isEqualToString:kMCCActionPreviousTrack]) {
        statusText = @"Previous track";
        [controller changeTrack:-1];
    } else if ([action isEqualToString:kMCCActionToggleRepeat]) {
        NSInteger repeatMode = [controller repeatMode];
        statusText = [NSString stringWithFormat:@"Repeat %ld", (long)repeatMode];
        [controller toggleRepeat];
    } else if ([action isEqualToString:kMCCActionToggleShuffle]) {
        NSInteger shuffleMode = [controller toggleRepeat];
        statusText = [NSString stringWithFormat:@"Shuffle %ld", (long)shuffleMode];
        [controller toggleShuffle];
    } else if ([action isEqualToString:kMCCActionStartTimer]) {

        if (_sleepTimer) {
            [UIAlertController showAlertInViewController:[self alertWindow].rootViewController
                withTitle:@"Cancel Sleep Timer?"
                message:@"There is sleep timer currently set. Do you want to cancel it?"
                cancelButtonTitle:@"Cancel"
                destructiveButtonTitle:nil
                otherButtonTitles:@[@"OK"]
                tapBlock:^(UIAlertController *controller, UIAlertAction *action, NSInteger buttonIndex){
                    if (buttonIndex == [controller cancelButtonIndex]) {
                    } else {
                        if (_sleepTimer) {
                            [_sleepTimer invalidate];
                            _sleepTimer = nil;
                            [self updateStatusText:@"Sleep timer cancelled"];
                        }
                    }
                }];
        }
        else {
            [self showTimerAlert];
        }

        
    }
    if (statusText) {
        [self updateStatusText:statusText];
    }
}
-(void)runAction:(NSString*)action {
    [self runAction:action withObject:nil];
}

+(void)runAction:(NSString*)action withObject:(id)object {
    [[MCCTweakController sharedInstance] runAction:action withObject:object];
}

+(void)runAction:(NSString*)action {
    [[MCCTweakController sharedInstance] runAction:action];
}

-(void)onSleepTimerDone
{
    [_sleepTimer invalidate];
    _sleepTimer = nil;
    Log(kMCCEventSleepTimer);
    LAEvent *event = [[LAEvent alloc] initWithName:kMCCEventSleepTimer];
    [LASharedActivator sendEventToListener:event];
}

// - (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
// {
//     if (buttonIndex >= 0 && buttonIndex != actionSheet.cancelButtonIndex && buttonIndex < [_timerTimes count]) {
//         NSNumber* duration = [_timerTimes objectAtIndex:buttonIndex];

//         if (_sleepTimer) {
//             [_sleepTimer invalidate];
//             _sleepTimer = nil;
//         }
//         _sleepTimer = [[NSTimer alloc] initWithFireDate:[[NSDate date] dateByAddingTimeInterval:([duration intValue]*60)] interval:0 target:self selector:@selector(onSleepTimerDone) userInfo:nil repeats:NO];
//         [[NSRunLoop currentRunLoop] addTimer:_sleepTimer forMode:NSRunLoopCommonModes];
//         [self updateStatusText:[NSString stringWithFormat:@"Starting sleep timer: %@ min", duration]];

//         // NSURL *adjustedURL = _url;
//         // NSString *displayIdentifier = [_orderedDisplayIdentifiers objectAtIndex:buttonIndex];
//         // BCApplySchemeReplacementForDisplayIdentifierOnURL(displayIdentifier, adjustedURL, &adjustedURL);
//         // suppressed++;
//         // if ([UIApp respondsToSelector:@selector(applicationOpenURL:withApplication:sender:publicURLsOnly:animating:needsPermission:additionalActivationFlags:activationHandler:)]) {
//         //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL publicURLsOnly:NO];
//         // } else if ([UIApp respondsToSelector:@selector(applicationOpenURL:publicURLsOnly:animating:sender:additionalActivationFlag:)]) {
//         //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL publicURLsOnly:NO animating:YES sender:_sender additionalActivationFlag:_additionalActivationFlag];
//         // } else {
//         //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL withApplication:nil sender:_sender publicURLsOnly:NO animating:YES needsPermission:NO additionalActivationFlags:nil];
//         // }
//         // suppressed--;
//     }
//     [self cleanAlertWindow];
// }

-(void) fireClickEventWithAction:(UIAlertAction*)theAction
{
    Log(@"fireClickEventWithAction");
    NSArray* actions = [_alertController actions];
    NSUInteger indexOfAction = [actions indexOfObject:theAction];

    if (indexOfAction < ([actions count] - 1) && indexOfAction < [_timerTimes count]) {
        NSNumber* duration = [_timerTimes objectAtIndex:indexOfAction];

        if (_sleepTimer) {
            [_sleepTimer invalidate];
            _sleepTimer = nil;
        }
        _sleepTimer = [[NSTimer alloc] initWithFireDate:[[NSDate date] dateByAddingTimeInterval:([duration intValue]*60)] interval:0 target:self selector:@selector(onSleepTimerDone) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:_sleepTimer forMode:NSRunLoopCommonModes];
        [self updateStatusText:[NSString stringWithFormat:@"Starting sleep timer: %@ min", duration]];

        // NSURL *adjustedURL = _url;
        // NSString *displayIdentifier = [_orderedDisplayIdentifiers objectAtIndex:buttonIndex];
        // BCApplySchemeReplacementForDisplayIdentifierOnURL(displayIdentifier, adjustedURL, &adjustedURL);
        // suppressed++;
        // if ([UIApp respondsToSelector:@selector(applicationOpenURL:withApplication:sender:publicURLsOnly:animating:needsPermission:additionalActivationFlags:activationHandler:)]) {
        //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL publicURLsOnly:NO];
        // } else if ([UIApp respondsToSelector:@selector(applicationOpenURL:publicURLsOnly:animating:sender:additionalActivationFlag:)]) {
        //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL publicURLsOnly:NO animating:YES sender:_sender additionalActivationFlag:_additionalActivationFlag];
        // } else {
        //     [(SpringBoard *)UIApp applicationOpenURL:adjustedURL withApplication:nil sender:_sender publicURLsOnly:NO animating:YES needsPermission:NO additionalActivationFlags:nil];
        // }
        // suppressed--;
    }
    // [_alertController dismissViewControllerAnimated:YES completion:^{
        // [self cleanAlertWindow];
    // }];
}

-(void)cleanAlertWindow {
    // Log(@"cleanAlertWindow1");
    if (!_alertWindow) return;
    // Log(@"cleanAlertWindow2");
    // [_alertWindow.rootViewController dismissViewControllerAnimated:NO completion:^{
    // Log(@"cleanAlertWindow3");
    _alertWindow.hidden = YES;
    _alertWindow.rootViewController = nil;
    _alertWindow = nil;
    _alertController = nil;
    // }];

}

+(id)getProp:(NSString*)key{
    return [[[MCCTweakController sharedInstance] settings] objectForKey:key];
}

-(void)setView:(UIView*)view hidden:(BOOL)hidden alpha:(float)alpha {
    if (view.superview == nil) {
        view.hidden = hidden;
        view.alpha = alpha;
        return;
    }
    [UIView animateWithDuration:0.5
        delay:0.0
        options: UIViewAnimationCurveEaseOut
        animations:^
        {
            if (hidden) {
                view.alpha = 0;
            } else {
                view.hidden = NO;
                view.alpha = alpha;
            }
        }
        completion:^(BOOL b)
        {
            if (hidden) {
                view.hidden = YES;
            }
        }
        ];
}

-(void)setHidden:(BOOL)hidden{
    if (_currentlyHidden == hidden) return;
    _currentlyHidden = hidden;
    [self setView:_ccArtworkView hidden:hidden && BOOL_PROP(ccArtworkEnabled) alpha:_ccArtworkViewAlpha];
    [self setView:_lsArtworkView hidden:hidden && BOOL_PROP(lsArtworkEnabled) alpha:_lsArtworkViewAlpha];

    if (BOOL_PROP(ColorArtEnabled))
    {
        _SBControlCenterControlSettingsDidChangeForKey(@"highlightColor");
        if (!hidden && _nowPlayingColorArt) {
            [_ccArtworkView setBackgroundColor:_nowPlayingColorArt.backgroundColor];
            [_lsArtworkView setBackgroundColor:_nowPlayingColorArt.backgroundColor];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMRMCCColorArtDidChangeNotification object:self userInfo:@{@"colorArt":_nowPlayingColorArt}]; 
        }
        else {
            [_ccArtworkView setBackgroundColor:nil];
            [_lsArtworkView setBackgroundColor:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:kMRMCCColorArtDidChangeNotification object:self userInfo:nil]; 
        }
    }
}

-(void)attachView:(UIImageView*)view toParent:(UIView*)toParent atIndex:(int)index enabled:(BOOL)enabled
{
    if (!enabled || !toParent || index < 0 || index > [[toParent subviews] count]) {
        //either disabled or something is wrong let's remove the artwork
        if (view.superview != nil)
            [view removeFromSuperview];
        return;
    }
    if (view.image == nil) {
        //no need to attach for now
        view.hidden = YES;
        return;
    }
    view.hidden = !_playing;

    // in both cases "lockscreen" and "controlcenter" we need to be fullscreen
    
    if (view.superview != toParent || [[toParent subviews] indexOfObject:view] != index)
    {
        view.frame = [UIScreen mainScreen].bounds;
        [view removeFromSuperview];
        [toParent insertSubview:view atIndex:index];
    }
}

-(void)setNowPlayingImage:(UIImage*)image forArtworkView:(UIImageView*)artworkView enabled:(BOOL)enabled
{
    artworkView.image = image;
    if (artworkView == _ccArtworkView){
        //ControlCenter
        SBControlCenterController *ccController = [%c(SBControlCenterController) _sharedInstanceCreatingIfNeeded:YES];
        if (ccController) {
            SBControlCenterContentContainerView* containerView = ccController.viewController.containerView.contentContainerView;
            _UIBackdropView * backdrop = MSHookIvar<_UIBackdropView *>(containerView, "_backdropView");
            NSInteger index = [[containerView subviews] indexOfObject:(artworkView.superview != containerView)?backdrop:artworkView];
            [self attachView:artworkView toParent:containerView atIndex:index enabled:enabled];
        }
    }
    else if (artworkView == _lsArtworkView){
        SBFWallpaperView * _lockscreenWallpaperView = MSHookIvar<SBFWallpaperView *>([%c(SBWallpaperController) sharedInstance], "_lockscreenWallpaperView");
        NSInteger index = (artworkView.superview == _lockscreenWallpaperView)?[[_lockscreenWallpaperView subviews] indexOfObject:artworkView]:1;
        [self attachView:artworkView toParent:_lockscreenWallpaperView atIndex:index enabled:enabled];
    }

    if (!enabled) return;

    // everything is ok lets animate to the new image (which might be null)
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;

    [artworkView.layer addAnimation:transition forKey:nil];
}

-(void)clearNowPlayingImage {
    // Log(@"clearNowPlayingImage");
    if (_coverArtShouldChange) {
        [self setNowPlayingImage:nil];
    }
}

- (UIImage *)applyAlpha:(CGFloat) alpha toImage:(UIImage *)image{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0f);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);

    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);

    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);

    CGContextSetAlpha(ctx, alpha);

    CGContextDrawImage(ctx, area, image.CGImage);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return newImage;
}

- (void)setNowPlayingImage:(UIImage *)image {
    _coverArtShouldChange = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self
     selector:@selector(clearNowPlayingImage)
     object:nil];
    if (image == nil) {
        Log(@"setNowPlayingImage nil");
        [self setNowPlayingColorArt:nil];
        _currentCoverMD5 = nil;
        _nowPlayingImage = nil;
   } else if (BOOL_PROP(ColorArtEnabled)) {
        [SLColorArt processImage:(UIImage *)image
            scaledToSize:CGSizeMake(120,120)
            onComplete:^(SLColorArt *colorArt)
            {
                [self setNowPlayingColorArt:colorArt];
            }];
        _nowPlayingImage = [self applyAlpha:0.5f toImage:image];
        // _nowPlayingImage = image;
    } else {
        _nowPlayingImage = image;
    }
    // _nowPlayingImage = image;
    [self setNowPlayingImage:_nowPlayingImage forArtworkView:_ccArtworkView enabled:BOOL_PROP(ccArtworkEnabled)];
    [self setNowPlayingImage:_nowPlayingImage forArtworkView:_lsArtworkView enabled:BOOL_PROP(lsArtworkEnabled)];
}

-(void)setNowPlayingColorArt:(SLColorArt *)colorArt {
    if (!BOOL_PROP(ColorArtEnabled) || [_nowPlayingColorArt isEqual:colorArt]) return;
    _nowPlayingColorArt = colorArt;
    // _SBControlCenterControlSettingsDidChangeForKey(@"highlight");
    _SBControlCenterControlSettingsDidChangeForKey(@"highlightColor");

    if (_nowPlayingColorArt) {
        [_ccArtworkView setBackgroundColor:_nowPlayingColorArt.backgroundColor];
        [_lsArtworkView setBackgroundColor:_nowPlayingColorArt.backgroundColor];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMRMCCColorArtDidChangeNotification object:self userInfo:@{@"colorArt":_nowPlayingColorArt}]; 
    }
    else {
        [_ccArtworkView setBackgroundColor:nil];
        [_lsArtworkView setBackgroundColor:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMRMCCColorArtDidChangeNotification object:self userInfo:nil]; 
    }
}

-(NSString*)dataMD5:(NSData*) data {
    if (!data) return nil;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( data.bytes, data.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
        @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
        result[0], result[1], result[2], result[3], 
        result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11],
        result[12], result[13], result[14], result[15]
        ];  
}

- (void)dataProviderDidLoad
{
    if (!SHOULD_HOOK()) return;
    BOOL hasChanges = NO;
    SBMediaController *mc = [%c(SBMediaController) sharedInstance];
    NSDictionary* info = [mc _nowPlayingInfo];
    // Log(@"testInfo %@", info);
    if (!info) return;
    // NSString *title = mc.nowPlayingTitle;
    // if ((title != nowPlayingTitle) && ![title isEqualToString:nowPlayingTitle]) {
    //     nowPlayingTitle = [title copy];
    //     hasChanges = YES;
    // }
    // NSString *artist = mc.nowPlayingArtist;
    // if ((artist != nowPlayingArtist) && ![artist isEqualToString:nowPlayingArtist]) {
    //     nowPlayingArtist = [artist copy];
    //     hasChanges = YES;
    // }
    // NSString *album = mc.nowPlayingAlbum;
    // if ((album != nowPlayingArtist) && ![album isEqualToString:nowPlayingAlbum]) {
    //     nowPlayingAlbum = [album copy];
    //     hasChanges = YES;
    // }
    if (hasChanges) {
        NSData *coverData = [info objectForKey:@"artworkData"];
        if (coverData) {
            NSString* md5 = [self dataMD5:coverData];
            if (![md5 isEqualToString:_currentCoverMD5]) {
                if (![md5 isEqualToString:SPOTIFY_DEFAULT_COVER_MD5]) {
                    _currentCoverMD5 = md5;
                    self.nowPlayingImage =  [[UIImage alloc] initWithData:coverData];            
                }
                else {
                    _coverArtShouldChange = YES;
                    _coverArtTestCount = 0;
                    [self performSelector:@selector(setNowPlayingImage:) withObject:nil afterDelay:2.0f];
                }
            }
        } else if (!coverData) {
            _coverArtShouldChange = YES;
            _coverArtTestCount = 0;
            [self performSelector:@selector(setNowPlayingImage:) withObject:nil afterDelay:2.0f];
        }
    } else if (_coverArtShouldChange) {
        NSData *coverData = [info objectForKey:@"artworkData"];
        if (coverData) {
            NSString* md5 = [self dataMD5:coverData];
            if (![md5 isEqualToString:_currentCoverMD5]) {
                if (![md5 isEqualToString:SPOTIFY_DEFAULT_COVER_MD5]) {
                    _currentCoverMD5 = md5;
                    self.nowPlayingImage =  [[UIImage alloc] initWithData:coverData];            
                }
                else {
                    if (_coverArtTestCount < MAX_COVER_TEST) {
                        _coverArtTestCount++;
                        [self performSelector:@selector(setNowPlayingImage:) withObject:nil afterDelay:1.0f];
                    }
                    else {
                        self.nowPlayingImage = nil;
                    }
                }
            }
        } else if (_coverArtTestCount < MAX_COVER_TEST) {
            _coverArtTestCount++;
            [self performSelector:@selector(setNowPlayingImage:) withObject:nil afterDelay:1.0f];
        }
        else {
            self.nowPlayingImage = nil;
        }
    }
}

- (void)playbackStateChanged:(BOOL)playing
{
    if (_playing == playing) return;
    _playing = playing;
    if (!SHOULD_HOOK()) return;
    // Log(@"playbackStateChanged %@", BOOL_TO_STRING(_playing));

    if (self.nowPlayingImage == nil) {
        SBMediaController *mc = [%c(SBMediaController) sharedInstance];
        NSData *data = [[mc _nowPlayingInfo] objectForKey:@"artworkData"];
        if (data) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            self.nowPlayingImage = image;
        }
    }
    [self setHidden:!_playing];
}

-(void)currentSongChanged
{
    // Log(@"currentSongChanged");
    SBMediaController *mc = [%c(SBMediaController) sharedInstance];
    // [self dataProviderDidLoad];
    if (_npController) {
        [self updateNowPlayingWithController:_npController];
    }
    [self playbackStateChanged:mc.isPlaying];
}

extern CFStringRef kMRMediaRemoteNowPlayingInfoAlbum;
extern CFStringRef kMRMediaRemoteNowPlayingInfoArtist;
extern CFStringRef kMRMediaRemoteNowPlayingInfoArtworkData;
extern CFStringRef kMRMediaRemoteNowPlayingInfoTitle;


-(void)updateNowPlayingWithController:(MPUNowPlayingController*)controller {
    // Log(@"updateNowPlayingWithController");
    NSDictionary* dict = MSHookIvar<NSDictionary*>(controller, "_currentNowPlayingInfo");
    [self updateNowPlaying:dict withController:controller];
}

-(void)playingInfoChanged {
    if (!SHOULD_HOOK()) return;
    
    if (_npController) {
        NSDictionary* dict = MSHookIvar<NSDictionary*>(_npController, "_currentNowPlayingInfo");
        BOOL hasChanges = NO;
        NSString *title = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
        if ((title != nowPlayingTitle) && ![title isEqualToString:nowPlayingTitle]) {
            nowPlayingTitle = [title copy];
            hasChanges = YES;
        }
        NSString *artist = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
        if ((artist != nowPlayingArtist) && ![artist isEqualToString:nowPlayingArtist]) {
            nowPlayingArtist = [artist copy];
            hasChanges = YES;
        }
        NSString *album = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
        if ((album != nowPlayingAlbum) && ![album isEqualToString:nowPlayingAlbum]) {
            nowPlayingAlbum = [album copy];
            hasChanges = YES;
        }
        _coverArtShouldChange |= hasChanges;
        if (hasChanges) {
            _coverArtTestCount = 0;
            [self setNowPlayingColorArt:nil];
        }
        if (!_coverArtShouldChange && !hasChanges) {
            return;
        }
        Log(@"playingInfoChanged %d, %d, %@", _coverArtShouldChange?1:0, hasChanges?1:0, nowPlayingTitle);
        NSData *coverData = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData];
        if (coverData) {
            NSString* md5 = [self dataMD5:coverData];
            if (![md5 isEqualToString:_currentCoverMD5]) {
                if (![md5 isEqualToString:SPOTIFY_DEFAULT_COVER_MD5]) {
                    Log(@"playingInfoChanged hasChanged cover data %@", md5);
                    UIImage* image = [[UIImage alloc] initWithData:coverData];
                    if (image) {
                        // Log(@"playingInfoChanged test %p %p", coverData, image);
                        _currentCoverMD5 = md5;
                        [self setNowPlayingImage: image];            
                        Log(@"playingInfoChanged hasChanged done");
                    } else if (_coverArtShouldChange){
                        if (_coverArtTestCount < MAX_COVER_TEST) {
                            _coverArtTestCount++;
                            [self performSelector:@selector(playingInfoChanged) withObject:nil afterDelay:0.5f];
                        }
                        else {
                            // Log(@"playingInfoChanged spotify nil");
                            [self setNowPlayingImage: nil]; 
                        }
                        //seems to take time to update
                    }
                // else {
                //     needsStartTimer = YES;
                // }
                } else if (_coverArtShouldChange){
                    if (_coverArtTestCount < MAX_COVER_TEST) {
                        _coverArtTestCount++;
                        [self performSelector:@selector(playingInfoChanged) withObject:nil afterDelay:0.5f];
                    }
                    else {
                        // Log(@"playingInfoChanged spotify nil");
                        [self setNowPlayingImage: nil]; 
                    }
                    //seems to take time to update
                }
            // else if (!_coverArtShouldChange) {
            //     needsStartTimer = YES;
            // }
            }
        }
        else if (_coverArtShouldChange) {
            // Log(@"playingInfoChanged nil");
            [self setNowPlayingImage: nil];            
        }
    }
}

-(void)updateNowPlaying:(NSDictionary*)dict withController:(MPUNowPlayingController*)controller
{
    // Log(@"updateNowPlaying");
    [NSObject cancelPreviousPerformRequestsWithTarget:self
     selector:@selector(updateNowPlayingWithController:)
     object:controller];
    if (!SHOULD_HOOK()) return;
    BOOL hasChanges = NO;
    NSString *title = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle];
    if ((title != nowPlayingTitle) && ![title isEqualToString:nowPlayingTitle]) {
        nowPlayingTitle = [title copy];
        hasChanges = YES;
    }
    NSString *artist = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist];
    if ((artist != nowPlayingArtist) && ![artist isEqualToString:nowPlayingArtist]) {
        nowPlayingArtist = [artist copy];
        hasChanges = YES;
    }
    NSString *album = [dict objectForKey:(__bridge NSString *)kMRMediaRemoteNowPlayingInfoAlbum];
    if ((album != nowPlayingAlbum) && ![album isEqualToString:nowPlayingAlbum]) {
        nowPlayingAlbum = [album copy];
        hasChanges = YES;
    }
    _coverArtShouldChange |= hasChanges;
    if (hasChanges) {
        _coverArtTestCount = 0;
        [self setNowPlayingColorArt:nil];
    }
    // Log(@"updateNowPlaying %d, %d, %@", _coverArtShouldChange?1:0, hasChanges?1:0, nowPlayingTitle);
    [self playbackStateChanged:[[%c(SBMediaController) sharedInstance] isPlaying]];
}

- (void)settingsDidChange {
    Log(@"settingsDidChange %@", [_settings objectForKey:@"TweakEnabled"]);
    Log(@"settingsDidChange SHOULD_HOOK %d", SHOULD_HOOK()?1:0);
    [self setHidden:!(_playing && SHOULD_HOOK())];
    if(_ccArtworkView.superview) {
        [_ccArtworkView.superview setNeedsLayout];
    }
    if(_lsArtworkView.superview) {
        //we need to request a layout if the change requires it
        [_lsArtworkView.superview setNeedsLayout];
    }
    _ccArtworkViewAlpha = _ccArtworkView.alpha = FLOAT_PROP(ccArtworkOpacity);
    _lsArtworkViewAlpha = _lsArtworkView.alpha = FLOAT_PROP(lsArtworkOpacity);
    _ccArtworkView.contentMode = BOOL_PROP(ccArtworkScaleToFit)?UIViewContentModeScaleAspectFit:UIViewContentModeScaleAspectFill;
    _lsArtworkView.contentMode = BOOL_PROP(lsArtworkScaleToFit)?UIViewContentModeScaleAspectFit:UIViewContentModeScaleAspectFill;
    [[NSNotificationCenter defaultCenter] postNotificationName:kMRMCCSettingsDidChangeNotification object:self userInfo:nil]; 
}

//  Load settings from settings dictionary
- (void)applySettings:(NSDictionary *)settings {

    _didLoadSettings = YES;
    Log(@"applySettings %@", [settings objectForKey:@"TweakEnabled"]);
    [settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        id newValue = [settings objectForKey:key];
        if (newValue) {
            [_settings setValue:newValue forKey:key];
        }
    }]; 
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName
{
    [self runAction:listenerName];
    event.handled = YES;
}
- (BOOL)activator:(LAActivator *)activator requiresNeedsPoweredDisplayForListenerName:(NSString *)listenerName {
    return [listenerName isEqualToString:kMCCActionStartTimer];
}


- (void)prepareForPopoverPresentation:(UIPopoverPresentationController *)popoverPresentationController
{
    CGRect dialogRect;
    if ((lastTapCentroid.x == 0.0f) || (lastTapCentroid.y == 0.0f) || isnan(lastTapCentroid.x) || isnan(lastTapCentroid.y)) {
        dialogRect = _alertWindow.rootViewController.view.bounds;
        dialogRect.origin.y += dialogRect.size.height;
        dialogRect.size.height = 0.0f;
    } else {
        dialogRect.origin.x = lastTapCentroid.x - 1.0f;
        dialogRect.origin.y = lastTapCentroid.y - 1.0f;
        dialogRect.size.width = 2.0f;
        dialogRect.size.height = 2.0f;
    }
    //Fell through.
    UIViewController* presentingController = [_alertController presentingViewController];
    popoverPresentationController.sourceView = [presentingController view];
    popoverPresentationController.sourceRect = (CGRectEqualToRect(CGRectZero, dialogRect)?CGRectMake(presentingController.view.bounds.size.width/2, presentingController.view.bounds.size.height/2, 1, 1):dialogRect);;
}

- (void)popoverPresentationController:(UIPopoverPresentationController *)popoverPresentationController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view
{
    CGRect dialogRect;
    if ((lastTapCentroid.x == 0.0f) || (lastTapCentroid.y == 0.0f) || isnan(lastTapCentroid.x) || isnan(lastTapCentroid.y)) {
        dialogRect = _alertWindow.rootViewController.view.bounds;
        dialogRect.origin.y += dialogRect.size.height;
        dialogRect.size.height = 0.0f;
    } else {
        dialogRect.origin.x = lastTapCentroid.x - 1.0f;
        dialogRect.origin.y = lastTapCentroid.y - 1.0f;
        dialogRect.size.width = 2.0f;
        dialogRect.size.height = 2.0f;
    }
    //This will never be called when using bar button item
    BOOL canUseDialogRect = !CGRectEqualToRect(CGRectZero, dialogRect);
    UIView* theSourceView = *view;
    BOOL shouldUseViewBounds = ([theSourceView isKindOfClass:[UIToolbar class]] || [theSourceView isKindOfClass:[UITabBar class]]);
    
    if (shouldUseViewBounds) {
        rect->origin = CGPointMake(theSourceView.bounds.origin.x, theSourceView.bounds.origin.y);
        rect->size = CGSizeMake(theSourceView.bounds.size.width, theSourceView.bounds.size.height);
    } else if (!canUseDialogRect) {
        rect->origin = CGPointMake(theSourceView.bounds.size.width/2, theSourceView.bounds.size.height/2);
        rect->size = CGSizeMake(1, 1);
    }
    
    popoverPresentationController.sourceRect = *rect;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self cleanAlertWindow];
}

-(UIColor*) controlCenterControlColorForState:(int) state {
    // Log(@"controlCenterControlColorForState: %d", state);
    if (!SHOULD_HOOK() || _currentlyHidden || !_nowPlayingColorArt) return nil;
    return _nowPlayingColorArt.primaryColor;
}

@end
