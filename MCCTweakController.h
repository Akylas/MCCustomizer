
#define PREFERENCES_PATH @"/User/Library/Preferences/com.akylas.mccustomizer.plist"
#define PREFERENCES_CHANGED_NOTIFICATION "com.akylas.mccustomizer.preferences-changed"

#define BOOL_INT(value) (value ? 1 : 0)
#define BOOL_TO_STRING(value) ( value ? @"YES" : @"NO" )
#define TAG @"MCCustomizer"
#define Log(x, ...) NSLog(@"[%@] " x, TAG, ##__VA_ARGS__)

#define CLASS_STRING(object) NSStringFromClass([object class])


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

@class SBLockScreenView;
@interface MCCTweakController : NSObject {

}
@property (nonatomic, retain) NSDictionary* settings;

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
+(id)getProp:(NSString*)key;

#define BOOL_PROP(val) [[MCCTweakController getProp:[NSString stringWithUTF8String:#val]] boolValue]
#define STRING_PROP(val) [MCCTweakController getProp:[NSString stringWithUTF8String:#val]]
#define FLOAT_PROP(val) [[MCCTweakController getProp:[NSString stringWithUTF8String:#val]] floatValue]
#define SHOULD_HOOK() BOOL_PROP(TweakEnabled)
@end


