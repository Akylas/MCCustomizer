#import "TweakController.h"
#import "PrivateHeaders.h"


#define MAX_COVER_TEST 1


@implementation TweakController
{
    UIImageView *_ccArtworkView;
    UIImageView *_lsArtworkView;
    BOOL _didLoadSettings;

    NSString *nowPlayingTitle;
    NSString *nowPlayingArtist;
    NSString *nowPlayingAlbum;
    UIImage *_nowPlayingImage;

    float _ccArtworkViewAlpha;
    float _lsArtworkViewAlpha;

    BOOL _coverArtShouldChange;
    BOOL _playing;
    int _coverArtTestCount;
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
            @"ccNoPlayingText":@"No Music playing",
            @"lsNoPlayingText":@"No Music playing",
            @"ccArtworkOpacity":@(1.0),
            @"lsArtworkOpacity":@(1.0),
            @"ccArtworkScaleToFit":@(NO),
            @"lsArtworkScaleToFit":@(NO),
            @"ccOneTapToOpenNoMusic":@(YES),
            @"lsOneTapToOpenNoMusic":@(YES),
            @"ccHideOnPlayPause":@(NO),
            @"DefaultApp":@"com.apple.Music"
        }];
        _didLoadSettings = NO;
    }

    return self;
}

+(id)getProp:(NSString*)key{
    return [[[TweakController sharedInstance] settings] objectForKey:key];
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
    if (!SHOULD_HOOK()) return;
    Log(@"setHidden");
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
    // in both cases "lockscreen" and "controlcenter" we need to be fullscreen
    view.frame = [UIScreen mainScreen].bounds;
    view.hidden = NO;
    if (view.superview != toParent || [[toParent subviews] indexOfObject:view] != index)
    {
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
            int index = [[containerView subviews] indexOfObject:backdrop];
            [self attachView:artworkView toParent:containerView atIndex:index enabled:enabled];
        }
    }
    else if (artworkView == _lsArtworkView){
       //Lockscreen
        SBFWallpaperView * _lockscreenWallpaperView = MSHookIvar<SBFWallpaperView *>([%c(SBWallpaperController) sharedInstance], "_lockscreenWallpaperView");
        [self attachView:_lsArtworkView toParent:_lockscreenWallpaperView atIndex:1 enabled:enabled];
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _coverArtShouldChange = NO;
    _nowPlayingImage = image;
    [self setNowPlayingImage:image forArtworkView:_ccArtworkView enabled:BOOL_PROP(ccArtworkEnabled)];
    [self setNowPlayingImage:image forArtworkView:_lsArtworkView enabled:BOOL_PROP(lsArtworkEnabled)];
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
        // Log(@"dataProviderDidLoad hasChanges");
       NSDictionary* info = [mc _nowPlayingInfo];

        NSData *data = [info objectForKey:@"artworkData"];
        if (data) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            self.nowPlayingImage = image;
       } else {
            _coverArtShouldChange = YES;
            _coverArtTestCount = 0;
            [self performSelector:@selector(setNowPlayingImage:) withObject:nil afterDelay:2.0f];
        }
    } else if (_coverArtShouldChange) {
        NSData *data = [[mc _nowPlayingInfo] objectForKey:@"artworkData"];
        if (data) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            self.nowPlayingImage = image;
       }
        else if (_coverArtTestCount < MAX_COVER_TEST) {
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
    _ccArtworkViewAlpha = _ccArtworkView.alpha = FLOAT_PROP(ccArtworkOpacity);
    _lsArtworkViewAlpha = _lsArtworkView.alpha = FLOAT_PROP(lsArtworkOpacity);
    _ccArtworkView.contentMode = BOOL_PROP(ccArtworkScaleToFit)?UIViewContentModeScaleAspectFit:UIViewContentModeScaleAspectFill;
    _lsArtworkView.contentMode = BOOL_PROP(lsArtworkScaleToFit)?UIViewContentModeScaleAspectFit:UIViewContentModeScaleAspectFill;
}

//  Load settings from settings dictionary
- (void)applySettings:(NSDictionary *)settings {

    _didLoadSettings = YES;
    [_settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        id newValue = [settings objectForKey:key];
         if (newValue) {
            [_settings setValue:newValue forKey:key];
         }
    }]; 
    Log(@"applySettings %@", _settings);
}

@end