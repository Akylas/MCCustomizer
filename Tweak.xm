#import <substrate.h>
#import "MCCTweakController.h"
#include <dlfcn.h>

extern "C" UIColor *                 _SBUIControlCenterControlColorForState(int state);

static UIColor * (*original__SBUIControlCenterControlColorForState)(int state);
extern "C" NSInteger                 _SBUIControlCenterControlBlendModeForState(int state);

static void reloadSettings() {

    //  Load settings plist
    NSDictionary * settings = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];
    if (!settings)
        return;
    Log(@"reloadSettings %@", [settings objectForKey:@"TweakEnabled"]);
    [[MCCTweakController sharedInstance] applySettings:settings];
    [[MCCTweakController sharedInstance] settingsDidChange];

}

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    Log(@"reloadSettingsNotification %@", (__bridge NSDictionary*)dictionary);
    reloadSettings();
}

UIColor * PN_SBUIControlCenterControlColorForState(int state) {
    UIColor* color = [[MCCTweakController sharedInstance] controlCenterControlColorForState:state];
    return color ?: original__SBUIControlCenterControlColorForState(state);
}

NSInteger PN_SBUIControlCenterControlBlendModeForState(int state) {
    return kCGBlendModeNormal;
}

%ctor {

    // MSHookFunction((void *)_SBUIControlCenterControlBlendModeForState, (void *)PN_SBUIControlCenterControlBlendModeForState, (void **)NULL);
    // MSHookFunction(_SBUIControlCenterControlColorForState, PN_SBUIControlCenterControlColorForState, &original__SBUIControlCenterControlColorForState);
    @autoreleasepool {
        dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
        dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", 2);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR(PREFERENCES_CHANGED_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);

        %init;

    }

}