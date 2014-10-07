ARCHS = arm64 armv7s armv7
THEOS_PLATFORM_SDK_ROOT = /Volumes/data/dev/old_xcode/Xcode.app/Contents/Developer
TARGET = iphone:clang:latest:7.0
THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = MCCustomizer
MCCustomizer_CFLAGS = -fobjc-arc -Wno-unused-function -Wno-parentheses
MCCustomizer_FILES = Tweak.xm MCCTweakController.xm SBUIController.xm _MPUSystemMediaControlsView.xm NowPlayingArtPluginController.xm SBControlCenter.xm SBLockScreen.xm MPUSystemMediaControlsViewController.xm SBWallpaperController.xm UIAlertView+Blocks.m
MCCustomizer_FRAMEWORKS = Foundation CoreGraphics QuartzCore UIKit MediaPlayer
MCCustomizer_PRIVATE_FRAMEWORKS = SpringBoardUIServices MediaPlayerUI
MCCustomizer_LIBRARIES = activator

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
# SUBPROJECTS += ccloader
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
