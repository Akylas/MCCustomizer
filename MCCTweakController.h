
#define PREFERENCES_PATH @"/User/Library/Preferences/com.akylas.mccustomizer.plist"
#define PREFERENCES_CHANGED_NOTIFICATION "com.akylas.mccustomizer.preferences-changed"

#define BOOL_INT(value) (value ? 1 : 0)
#define BOOL_TO_STRING(value) ( value ? @"YES" : @"NO" )
#define TAG @"MCCustomizer"
#define Log(x, ...) NSLog(@"[%@] " x, TAG, ##__VA_ARGS__)

#define CLASS_STRING(object) NSStringFromClass([object class])

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define DEFAULT_TINT_COLOR [UIColor whiteColor]

#define kMCCId @"com.akylas.mccustomizer"

#define kMCCActionStartTimer @"com.akylas.mccustomizer.starttimer"
#define kMCCActionTogglePlayPause @"com.akylas.mccustomizer.playpause"
#define kMCCActionPlay @"com.akylas.mccustomizer.play"
#define kMCCActionPause @"com.akylas.mccustomizer.pause"
#define kMCCActionStop @"com.akylas.mccustomizer.stop"
#define kMCCActionNextTrack @"com.akylas.mccustomizer.nexttrack"
#define kMCCActionPreviousTrack @"com.akylas.mccustomizer.previoustrack"
#define kMCCActionToggleRepeat @"com.akylas.mccustomizer.repeat"
#define kMCCActionToggleShuffle @"com.akylas.mccustomizer.shuffle"
#define kMCCActionOpenPlayer @"com.akylas.mccustomizer.openplayer"
#define kMCCEventSleepTimer @"com.akylas.mccustomizer.sleeptimer"

#define kMRMCCColorArtDidChangeNotification @"kMRMCCColorArtDidChangeNotification"
#define kMRMCCSettingsDidChangeNotification @"kMRMCCSettingsDidChangeNotification"


@class SBLockScreenView;
@class MPUNowPlayingController;
@interface MCCTweakController : NSObject<UIPopoverPresentationControllerDelegate> {

}
@property (nonatomic, retain) NSDictionary* settings;

@property(nonatomic,retain) MPUNowPlayingController* npController;
@property(nonatomic,retain) UIImage* nowPlayingImage;
@property(nonatomic,readonly) UIImageView* ccArtworkView;
@property(nonatomic,readonly) UIImageView* lsArtworkView;

+ (instancetype)sharedInstance;
-(void)runAction:(NSString*)action;
-(void)runAction:(NSString*)action withObject:(id)object;
+(void)runAction:(NSString*)action;
+(void)runAction:(NSString*)action withObject:(id)object;

- (void)settingsDidChange;
- (void)applySettings:(NSDictionary *)settings;

- (void)dataProviderDidLoad;
-(void)currentSongChanged;
-(void)playingInfoChanged;
-(void)updateNowPlaying:(NSDictionary*)dict withController:(MPUNowPlayingController*)controller;
+(id)getProp:(NSString*)key;
-(UIColor*) controlCenterControlColorForState:(int) state;

#define BOOL_PROP(val) [[MCCTweakController getProp:[NSString stringWithUTF8String:#val]] boolValue]
#define STRING_PROP(val) [MCCTweakController getProp:[NSString stringWithUTF8String:#val]]
#define FLOAT_PROP(val) [[MCCTweakController getProp:[NSString stringWithUTF8String:#val]] floatValue]
#define SHOULD_HOOK() BOOL_PROP(TweakEnabled)
@end


