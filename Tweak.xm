#import "TweakController.h"
#include <dlfcn.h>

static void reloadSettings() {

    //  Load settings plist
    NSDictionary * settings = [NSDictionary dictionaryWithContentsOfFile:PREFERENCES_PATH];

    if (!settings)
        return;

    [[TweakController sharedInstance] applySettings:settings];
    [[TweakController sharedInstance] settingsDidChange];

}

static void reloadSettingsNotification(CFNotificationCenterRef notificationCenterRef, void * arg1, CFStringRef arg2, const void * arg3, CFDictionaryRef dictionary)
{
    reloadSettings();
}

%ctor {

    @autoreleasepool {

        dlopen("/System/Library/SpringBoardPlugins/NowPlayingArtLockScreen.lockbundle/NowPlayingArtLockScreen", 2);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadSettingsNotification, CFSTR(PREFERENCES_CHANGED_NOTIFICATION), NULL, CFNotificationSuspensionBehaviorCoalesce);

        %init;

    }

}