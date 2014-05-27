#define VARIANT_LOCKSCREEN 0
#define VARIANT_HOMESCREEN 1

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;

- (void)setLockscreenOnlyWallpaperAlpha:(float)alpha;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image;
- (id)_newWallpaperViewForProcedural:(id)proceduralWallpaper orImage:(UIImage *)image forVariant:(int)variant; //iOS 7.1
- (id)_clearWallpaperView:(id *)wallpaperView;
- (void)_handleWallpaperChangedForVariant:(NSUInteger)variant;
- (void)_updateSeparateWallpaper;
- (void)_updateSharedWallpaper;
- (void)_reconfigureBlurViewsForVariant:(NSUInteger)variant;
- (void)_updateBlurImagesForVariant:(NSUInteger)variant;
@end

@interface NowPlayingArtPluginController : NSObject
@end

@interface _UIBackdropViewSettings : NSObject
-(int)style;
- (float)blurRadius;
- (int)blurHardEdges;
- (id)blurQuality;
-(float)scale;
- (BOOL)blursWithHardEdges;
- (float)grayscaleTintAlpha;
- (float)grayscaleTintLevel;
- (float)saturationDeltaFactor;
- (BOOL)darkenWithSourceOver;
// - (float)darkeningTintAlpha;
// - (float)darkeningTintBrightness;
// - (float)darkeningTintHue;

- (void)setColorTintAlpha:(CGFloat)alpha;
- (void)setColorTint:(UIColor *)tint;

- (void)setBlurHardEdges:(int)arg1;
- (void)setBlurQuality:(id)arg1;
- (void)setBlurRadius:(float)arg1;

// - (void)setDarkenWithSourceOver:(BOOL)arg1;
// - (void)setDarkeningTintAlpha:(float)arg1;
// - (void)setDarkeningTintBrightness:(float)arg1;

- (void)setGrayscaleTintAlpha:(float)arg1;
- (void)setGrayscaleTintLevel:(float)arg1;

- (void)setSaturationDeltaFactor:(float)arg1;

- (BOOL)appliesTintAndBlurSettings;
@end

@interface _UIBackdropViewSettingsNone: _UIBackdropViewSettings
@end

@class CAFilter;
@interface _UIBackdropView : UIView

- (_UIBackdropViewSettings *)outputSettings;
- (_UIBackdropViewSettings *)inputSettings;

- (instancetype)initWithPrivateStyle:(NSInteger)style;

- (void)setAppliesOutputSettingsAnimationDuration:(CGFloat)duration;

- (void)setComputesColorSettings:(BOOL)val;
- (void)setSimulatesMasks:(BOOL)val;
-(void)applySettings:(id)arg1 ;
-(void)transitionToSettings:(id)arg1 ;
-(void)_updateFilters;

- (NSString *)groupName;
- (void)setGroupName:(NSString *)groupName;
- (UIView*)grayscaleTintView;
- (UIView*)colorTintView;
-(void)setBlurQuality:(id)arg1 ;
-(void)setBlurRadius:(float)arg1 ;
-(void)setSaturationDeltaFactor:(float)arg1 ;

-(float)colorMatrixGrayscaleTintLevel;
-(float)colorMatrixGrayscaleTintAlpha;
-(void)setColorMatrixGrayscaleTintLevel:(float)arg1 ;
-(void)setBlurFilterWithRadius:(float)arg1 blurQuality:(id)arg2 blurHardEdges:(int)arg3 ;

-(float)blurRadius;
-(id)blurQuality;
-(float)saturationDeltaFactor;
-(int)style;
-(int)maskMode;
-(CAFilter*)gaussianBlurFilter;
-(CAFilter*)colorSaturateFilter;
-(CAFilter*)tintFilter;
@end

@interface SBFStaticWallpaperView : UIView
- (instancetype)initWithFrame:(CGRect)frame wallpaperImage:(UIImage *)wallpaperImage;
- (UIImageView *)contentView;
- (void)setVariant:(NSUInteger)variant;
- (void)setZoomFactor:(float)zoomFactor;
@end

@interface _SBFakeBlurView : UIView
+ (UIImage *)_imageForStyle:(int *)style withSource:(SBFStaticWallpaperView *)source;
- (void)updateImageWithSource:(id)source;
- (void)reconfigureWithSource:(id)source;
@end

@interface SBUIController : NSObject
+ (instancetype)sharedInstance;

- (void)setLockscreenArtworkImage:(UIImage *)artworkImage;
- (void)updateLockscreenArtwork;
- (void)blurryArtworkPreferencesChanged;
-(BOOL)_activateAppSwitcherFromSide:(int)arg1 ;
-(void)activateApplicationAnimatedFromIcon:(id)arg1 fromLocation:(int)arg2 ;
-(void)activateApplicationAnimated:(id)arg1 ;

@end

@interface SBApplication: NSObject

-(id)bundleIdentifier;
-(id)displayIdentifier;
- (id)displayName;
@end


@interface SBApplicationController: NSObject
+ (instancetype)sharedInstance;

-(id)applicationWithDisplayIdentifier:(id)arg1 ;
@end

@interface _NowPlayingArtView : UIView
@end

@interface SBLockScreenScrollView : UIScrollView
@end

@interface SBLockScreenView : UIView
-(UIView*) mediaControlsView;
-(_UIBackdropView*) wallpaperBlurView;
@end

// @protocol MPUSystemMediaControlsDelegate;
@class MPUNowPlayingController, MPAudioDeviceController, _MPUSystemMediaControlsView, UIImageView, NSDictionary, UIPopoverController, RUTrackActionsModalItem, NSString, NSTimer, UIView;

@interface MPUSystemMediaControlsViewController : UIViewController{

    // MPUNowPlayingController* _nowPlayingController;
    // MPAudioDeviceController* _audioDeviceController;
    // BOOL _wantsToLaunchNowPlayingApp;
    // unsigned _runningLongPressCommand;
    // _MPUSystemMediaControlsView* _mediaControlsView;
    // UIImageView* _artworkImageView;
    // NSDictionary* _nowPlayingInfoForPresentedTrackActions;
    // UIPopoverController* _trackActionsPopoverController;
    // RUTrackActionsModalItem* _trackActionsModalItem;
    // NSString* _audioCategoryForDisabledHUD;
    // NSTimer* _scrubberCommitTimer;
    // double _scrubbedTimeDestination;
    // double _lastDurationFromUpdate;
    // BOOL _persistentUpdatesEnabled;
    // int _style;
    // <MPUSystemMediaControlsDelegate>* _delegate;

}

// @property (nonatomic,readonly) int style;                                                     //@synthesize style=_style - In the implementation block
// @property (assign,nonatomic,__weak) <MPUSystemMediaControlsDelegate> * delegate;              //@synthesize delegate=_delegate - In the implementation block
// @property (nonatomic,readonly) UIView * artworkView; 
// @property (assign,nonatomic) BOOL persistentUpdatesEnabled;                                   //@synthesize persistentUpdatesEnabled=_persistentUpdatesEnabled - In the implementation block
-(void)remoteViewControllerDidFinish;
-(void)audioDeviceControllerAudioRoutesChanged:(id)arg1 ;
-(void)dealloc;
-(void)setDelegate:(id)arg1 ;
-(id)delegate;
-(int)style;
-(id)initWithStyle:(int)arg1 ;
-(void)viewWillAppear:(BOOL)arg1 ;
-(id)initWithNibName:(id)arg1 bundle:(id)arg2 ;
-(void)loadView;
-(void)viewWillDisappear:(BOOL)arg1 ;
-(void)popoverControllerDidDismissPopover:(id)arg1 ;
-(void)modalItem:(id)arg1 didDismissWithButtonIndex:(int)arg2 ;
-(void)transportControlsView:(id)arg1 tapOnControlType:(int)arg2 ;
-(void)transportControlsView:(id)arg1 longPressBeginOnControlType:(int)arg2 ;
-(void)transportControlsView:(id)arg1 longPressEndOnControlType:(int)arg2 ;
-(void)transportControlsView:(id)arg1 tapOnAccessoryButtonType:(int)arg2 ;
-(void)progressViewDidBeginScrubbing:(id)arg1 ;
-(void)progressViewDidEndScrubbing:(id)arg1 ;
-(void)nowPlayingController:(id)arg1 nowPlayingInfoDidChange:(id)arg2 ;
-(void)nowPlayingController:(id)arg1 playbackStateDidChange:(BOOL)arg2 ;
-(void)nowPlayingController:(id)arg1 nowPlayingApplicationDidChange:(id)arg2 ;
-(void)nowPlayingController:(id)arg1 elapsedTimeDidChange:(double)arg2 ;
-(void)_stopScrubberCommitTimer;
-(void)_cancelRunningLongPressCommand;
-(void)_launchCurrentNowPlayingApp;
-(void)_infoButtonTapped:(id)arg1 ;
-(void)_likeBanButtonTapped:(id)arg1 ;
-(void)_beginScrubberCommitTimer;
-(void)_commitCurrentScrubberValue;
-(void)mediaControlsTitlesViewWasTapped:(id)arg1 ;
-(id)artworkView;
-(void)setPersistentUpdatesEnabled:(BOOL)arg1 ;
-(BOOL)persistentUpdatesEnabled;
-(void)trackActioningObject:(id)arg1 didSelectAction:(int)arg2 atIndex:(int)arg3 ;
-(_MPUSystemMediaControlsView*)mediaControlsView;
-(UIView*)volumeView;
@end

@class MPUTransportControlsView, MPUChronologicalProgressView, MPUMediaControlsVolumeView;

@interface _MPUSystemMediaControlsView : UIView {

    // int _style;
    // MPUTransportControlsView* _transportControlsView;
    // MPUChronologicalProgressView* _timeInformationView;
    // MPUMediaControlsTitlesView* _trackInformationView;
    // MPUMediaControlsVolumeView* _volumeView;

}

// @property (nonatomic,readonly) int style;                                                     //@synthesize style=_style - In the implementation block
// @property (nonatomic,retain) MPUTransportControlsView * transportControlsView;                //@synthesize transportControlsView=_transportControlsView - In the implementation block
// @property (nonatomic,retain) MPUChronologicalProgressView * timeInformationView;              //@synthesize timeInformationView=_timeInformationView - In the implementation block
// @property (nonatomic,retain) MPUMediaControlsTitlesView * trackInformationView;               //@synthesize trackInformationView=_trackInformationView - In the implementation block
// @property (nonatomic,retain) MPUMediaControlsVolumeView * volumeView;                         //@synthesize volumeView=_volumeView - In the implementation block
-(UIView*)volumeView;
-(id)initWithFrame:(CGRect)arg1 ;
-(void)layoutSubviews;
-(int)style;
-(id)initWithStyle:(int)arg1 ;
-(UIView*)transportControlsView;
-(UIView*)timeInformationView;
-(UIView*)trackInformationView;
-(void)updatePlaybackState:(BOOL)arg1 ;
-(void)_layoutSubviewsControlCenteriPad;
-(void)setTransportControlsView:(id)arg1 ;
-(void)setTimeInformationView:(id)arg1 ;
-(void)setTrackInformationView:(id)arg1 ;
-(void)setVolumeView:(id)arg1 ;
@end

@interface MPUNowPlayingTitlesView : UIView {

}
-(BOOL)isExplicit;
-(id)initWithFrame:(CGRect)arg1 ;
-(void)layoutSubviews;
-(CGSize)sizeThatFits:(CGSize)arg1 ;
-(int)style;
-(id)titleTextAttributes;
-(void)setTitleTextAttributes:(id)arg1 ;
-(id)_titleLabel;
-(id)initWithStyle:(int)arg1 ;
-(void)setMarqueeEnabled:(BOOL)arg1 ;
-(void)setTitleText:(id)arg1 ;
-(BOOL)isMarqueeEnabled;
-(id)detailTextAttributes;
-(float)textMargin;
-(id)explicitImage;
-(void)setExplicitImage:(id)arg1 ;
-(void)setTextMargin:(float)arg1 ;
-(void)setArtistText:(id)arg1 ;
-(float)titleBaselineOffsetFromBottom;
-(void)setMarqueeEnabled:(BOOL)arg1 allowCurrentMarqueeToFinish:(BOOL)arg2 ;
-(void)setExplicit:(BOOL)arg1 ;
-(void)setAlbumText:(id)arg1 ;
-(void)setDetailTextAttributes:(id)arg1 ;
-(void)resetMarqueePositions;
-(id)artistText;
-(id)albumText;
-(id)stationNameText;
-(id)_detailLabel;
-(id)titleText;
@end

@interface SBFWallpaperView: UIView
@end


@interface SBControlCenterViewController : UIViewController

- (id)containerView;
@end

@interface SBControlCenterController : UIViewController

+ (id)sharedInstanceIfExists;
+ (id)sharedInstance;
- (SBControlCenterViewController*)viewController;
-(void)dismissAnimated:(BOOL)arg1 ;
@end

@interface SBMediaController : NSObject

+ (id)sharedInstance;
- (void)decreaseVolume;
- (void)increaseVolume;
- (BOOL)muted;
- (void)setVolume:(float)arg1;
- (float)volume;
- (BOOL)setPlaybackSpeed:(int)arg1;
- (BOOL)toggleShuffle;
- (BOOL)toggleRepeat;
- (BOOL)skipFifteenSeconds:(int)arg1;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)endSeek:(int)arg1;
- (BOOL)beginSeek:(int)arg1;
- (BOOL)changeTrack:(int)arg1;
- (id)nowPlayingApplication;
- (BOOL)trackIsBeingPlayedByMusicApp;
- (double)trackElapsedTime;
- (id)artwork;
- (double)trackDuration;
- (int)shuffleMode;
- (int)repeatMode;
- (id)nowPlayingAlbum;
- (id)nowPlayingTitle;
- (id)nowPlayingArtist;
- (unsigned long long)trackUniqueIdentifier;
- (BOOL)isTVOut;
- (BOOL)isMovie;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (BOOL)isLastTrack;
- (BOOL)isFirstTrack;
- (BOOL)hasTrack;
- (void)setNowPlayingInfo:(id)arg1;
- (id)_nowPlayingInfo;

@end

@interface SBControlCenterContentContainerView: UIView
@end

