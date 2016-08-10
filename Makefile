ARCHS = arm64 armv7s armv7
# THEOS_PLATFORM_SDK_ROOT = /Volumes/data/dev/old_xcode/Xcode.app/Contents/Developer
TARGET = iphone::9.2:8.0
THEOS_BUILD_DIR = Packages


SHARED_CFLAGS = -Wno-deprecated-declarations

include theos/makefiles/common.mk

TWEAK_NAME = MCCustomizer
MCCustomizer_CFLAGS = -fobjc-arc -Wno-unused-function -Wno-parentheses
MCCustomizer_FILES = Tweak.xm ColorArt/SLColorArt.m ColorArt/UIImage+Scale.m ColorArt/UIImage+ColorArt.m MCCTweakController.xm SBUIController.xm MPUSystemMediaControlsView.xm NowPlayingArtPluginController.xm SBControlCenter.xm SBLockScreen.xm MPUSystemMediaControlsViewController.xm SBWallpaperController.xm UIAlertController+Blocks.m MPUNowPlayingController.xm
MCCustomizer_FRAMEWORKS = Foundation CoreGraphics QuartzCore UIKit MediaPlayer
MCCustomizer_PRIVATE_FRAMEWORKS = SpringBoardUI SpringBoardUIServices MediaPlayerUI MediaRemote
MCCustomizer_LIBRARIES = activator substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
# SUBPROJECTS += ccloader
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
