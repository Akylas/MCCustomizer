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

        _lsArtworkView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _lsArtworkView.contentMode = UIViewContentModeScaleAspectFill;
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
            @"DefaultApp":@"com.apple.Music"
        }];
        _didLoadSettings = NO;
    }

    return self;
}

+(id)getProp:(NSString*)key{
    return [[[TweakController sharedInstance] settings] objectForKey:key];
}

-(void)setView:(UIView*)view hidden:(BOOL)hidden{
    [UIView animateWithDuration:0.5
        delay:0.0
        options: UIViewAnimationCurveEaseOut
        animations:^
        {
            if (hidden) {
                view.alpha = 0;
            } else {
                view.hidden = NO;
                view.alpha = 1;
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
    [self setView:_ccArtworkView hidden:hidden && BOOL_PROP(ccArtworkEnabled)];
    [self setView:_lsArtworkView hidden:hidden && BOOL_PROP(lsArtworkEnabled)];
}

- (void)setNowPlayingImage:(UIImage *)image {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _coverArtShouldChange = NO;
    if (image) {
        _ccArtworkView.hidden = !BOOL_PROP(ccArtworkEnabled);
        _lsArtworkView.hidden = !BOOL_PROP(lsArtworkEnabled);
    }

    _ccArtworkView.image = _lsArtworkView.image = _nowPlayingImage = image;

    CATransition *transition = [CATransition animation];
    transition.duration = 0.5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;

    [_ccArtworkView.layer addAnimation:transition forKey:nil];
    [_lsArtworkView.layer addAnimation:transition forKey:nil];

    SBControlCenterController *ccController = [%c(SBControlCenterController) sharedInstanceIfExists];
    if (ccController) {
        [ccController.viewController.containerView setNeedsLayout];
    }
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
    _ccArtworkView.alpha = FLOAT_PROP(ccArtworkOpacity);
    _lsArtworkView.alpha = FLOAT_PROP(lsArtworkOpacity);
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