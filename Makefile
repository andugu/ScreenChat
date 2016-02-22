include theos/makefiles/common.mk

LDFLAGS += -F. -framework Cycript -framework JavaScriptCore -framework Security -current_version 1.0 -compatibility_version 1.0 -framework UIKit -framework CFNetwork

ARCHS = armv7 arm64

TWEAK_NAME = ScreenChat
ScreenChat_FILES = Tweak.xm fishhook/fishhook.c
ScreenChat_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk


