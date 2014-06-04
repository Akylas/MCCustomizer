ARCHS = arm64 armv7s armv7
TARGET = iphone:clang:latest:7.0

include theos/makefiles/common.mk

BUNDLE_NAME = MCCustomizer
MCCustomizer_FILES = MCCustomizer.mm
MCCustomizer_INSTALL_PATH = /Library/PreferenceBundles
MCCustomizer_FRAMEWORKS = UIKit CoreGraphics
MCCustomizer_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MCCustomizer.plist$(ECHO_END)
