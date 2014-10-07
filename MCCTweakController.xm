#import <CommonCrypto/CommonDigest.h>
#import "MCCTweakController.h"
#import "PrivateHeaders.h"
#import <libactivator/libactivator.h>
#import "UIAlertView+Blocks.h"

#define MAX_COVER_TEST 1
#define SPOTIFY_DEFAULT_COVER_MD5 @"678514434ad5b105fa6f12148daeca8c"



static CGPoint lastTapCentroid;
%hook SBHandMotionExtractor

- (void)extractHandMotionForActiveTouches:(void *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid
{
    if (count && !isnan(centroid.x) && !isnan(centroid.y))
        lastTapCentroid = centroid;
    %orig;
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

    SBLockScreenView* _lockscreenView;

    float _ccArtworkViewAlpha;
    float _lsArtworkViewAlpha;

    BOOL _coverArtShouldChange;
    BOOL _playing;
    int _coverArtTestCount;
    NSArray* _supportedActions;
    NSArray* _timerTimes;

    UIActionSheet *_actionSheet;
    UIWindow *_alertWindow;
    NSTimer* _sleepTimer;
    NSString* _currentCoverMD5;
}
@synthesize nowPlayingImage = _nowPlayingImage;

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
        _ccArtworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _ccArtworkView.contentMode = UIViewContentModeScaleAspectFill;
        _ccArtworkViewAlpha = 1.0f;

        _lsArtworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _lsArtworkView.contentMode = UIViewContentModeScaleAspectFill;
        _lsArtworkViewAlpha = 1.0f;
        _settings = [NSMutableDictionary dictionaryWithDictionary:@{
            @"TweakEnabled":@(YES),
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

-(void)showTimerAlert
{
    UIActionSheet *actionSheet = _actionSheet = [[UIActionSheet alloc] init];
    actionSheet.title = @"Define sleep timer duration";
    actionSheet.delegate = (id<UIActionSheetDelegate>)self;

    // ObjC Fast Enumeration
    for (NSNumber *timeInMinutes in _timerTimes) {
        [actionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@ min", timeInMinutes]];
    }

    NSInteger cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];

    if (!_alertWindow) {
        _alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _alertWindow.windowLevel = 1050.1f /*UIWindowLevelStatusBar*/;
    }
    _alertWindow.hidden = NO;
    _alertWindow.rootViewController = [[UIViewController alloc] init];
    if ([_alertWindow respondsToSelector:@selector(_updateToInterfaceOrientation:animated:)])
        [_alertWindow _updateToInterfaceOrientation:[(SpringBoard*)[NSClassFromString(@"SpringBoard") sharedApplication] _frontMostAppOrientation] animated:NO];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        CGRect bounds;
        if ((lastTapCentroid.x == 0.0f) || (lastTapCentroid.y == 0.0f) || isnan(lastTapCentroid.x) || isnan(lastTapCentroid.y)) {
            bounds = _alertWindow.rootViewController.view.bounds;
            bounds.origin.y += bounds.size.height;
            bounds.size.height = 0.0f;
        } else {
            bounds.origin.x = lastTapCentroid.x - 1.0f;
            bounds.origin.y = lastTapCentroid.y - 1.0f;
            bounds.size.width = 2.0f;
            bounds.size.height = 2.0f;
        }
        [actionSheet showFromRect:bounds inView:_alertWindow.rootViewController.view animated:YES];
    } else {
        actionSheet.cancelButtonIndex = cancelButtonIndex;
        [actionSheet showInView:_alertWindow.rootViewController.view];
    }
}

-(void)runAction:(NSString*)action withObject:(id)object {
    Log(@"runAction %@", action);
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
        int repeatMode = [controller repeatMode];
        statusText = [NSString stringWithFormat:@"Repeat %d", repeatMode];
        [controller toggleRepeat];
    } else if ([action isEqualToString:kMCCActionToggleShuffle]) {
        int shuffleMode = [controller toggleRepeat];
        statusText = [NSString stringWithFormat:@"Shuffle %d", shuffleMode];
        [controller toggleShuffle];
    } else if ([action isEqualToString:kMCCActionStartTimer]) {

        if (_sleepTimer) {
            [UIAlertView showWithTitle:@"Cancel Sleep Timer?"
                message:@"There is sleep timer currently set. Do you want to cancel it?"
                cancelButtonTitle:@"Cancel"
                otherButtonTitles:@[@"OK"]
                tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    if (buttonIndex == [alertView cancelButtonIndex]) {
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

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex >= 0 && buttonIndex != actionSheet.cancelButtonIndex && buttonIndex < [_timerTimes count]) {
        NSNumber* duration = [_timerTimes objectAtIndex:buttonIndex];

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
    _actionSheet.delegate = nil;
    _actionSheet = nil;
    _alertWindow.hidden = YES;
    _alertWindow.rootViewController = nil;
    _alertWindow = nil;
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
    [self setView:_ccArtworkView hidden:hidden && BOOL_PROP(ccArtworkEnabled) alpha:_ccArtworkViewAlpha];
    [self setView:_lsArtworkView hidden:hidden && BOOL_PROP(lsArtworkEnabled) alpha:_lsArtworkViewAlpha];
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
        SBControlCenterController *ccController = [%c(SBControlCenterController) sharedInstanceIfExists];
        if (ccController) {
            SBControlCenterContentContainerView* containerView = ccController.viewController.containerView.contentContainerView;
            _UIBackdropView * backdrop = MSHookIvar<_UIBackdropView *>(containerView, "_backdropView");
            int index = [[containerView subviews] indexOfObject:(artworkView.superview != containerView)?backdrop:artworkView];
            [self attachView:artworkView toParent:containerView atIndex:index enabled:enabled];
        }
    }
    else if (artworkView == _lsArtworkView){
        SBFWallpaperView * _lockscreenWallpaperView = MSHookIvar<SBFWallpaperView *>([%c(SBWallpaperController) sharedInstance], "_lockscreenWallpaperView");
        int index = (artworkView.superview == _lockscreenWallpaperView)?[[_lockscreenWallpaperView subviews] indexOfObject:artworkView]:1;
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

- (void)setNowPlayingImage:(UIImage *)image {
    [NSObject cancelPreviousPerformRequestsWithTarget:self
       selector:@selector(setNowPlayingImage:)
       object:nil];
    _coverArtShouldChange = NO;
    if (!image) {
        _currentCoverMD5 = nil;
    }
    _nowPlayingImage = image;
    [self setNowPlayingImage:image forArtworkView:_ccArtworkView enabled:BOOL_PROP(ccArtworkEnabled)];
    [self setNowPlayingImage:image forArtworkView:_lsArtworkView enabled:BOOL_PROP(lsArtworkEnabled)];
}

-(NSString*)dataMD5:(NSData*) data {
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
    NSString *title = mc.nowPlayingTitle;
    if ((title != nowPlayingTitle) && ![title isEqualToString:nowPlayingTitle]) {
        nowPlayingTitle = [title copy];
        hasChanges = YES;
    }
    NSString *artist = mc.nowPlayingArtist;
    if ((artist != nowPlayingArtist) && ![artist isEqualToString:nowPlayingArtist]) {
        nowPlayingArtist = [artist copy];
        hasChanges = YES;
    }
    NSString *album = mc.nowPlayingAlbum;
    if ((album != nowPlayingArtist) && ![album isEqualToString:nowPlayingAlbum]) {
        nowPlayingAlbum = [album copy];
        hasChanges = YES;
    }
    if (hasChanges) {
        NSData *coverData = [[mc _nowPlayingInfo] objectForKey:@"artworkData"];
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
        NSData *coverData = [[mc _nowPlayingInfo] objectForKey:@"artworkData"];
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
    SBMediaController *mc = [%c(SBMediaController) sharedInstance];
    [self dataProviderDidLoad];
    [self playbackStateChanged:mc.isPlaying];
}

- (void)settingsDidChange {
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
}

//  Load settings from settings dictionary
- (void)applySettings:(NSDictionary *)settings {

    _didLoadSettings = YES;
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

@end
