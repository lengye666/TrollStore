TARGET := iphone:clang:16.5:14.0
INSTALL_TARGET_PROCESSES = TrollStore
ARCHS = arm64

TARGET_CODESIGN = ../Exploits/fastPathSign/fastPathSign

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = TrollStore

TrollStore_FILES = $(wildcard *.m) $(wildcard ../Shared/*.m)
TrollStore_FRAMEWORKS = UIKit CoreGraphics CoreServices CoreTelephony
TrollStore_PRIVATE_FRAMEWORKS = SpringBoardServices BackBoardServices MobileCoreServices MobileContainerManager
TrollStore_CODESIGN_FLAGS = -Sentitlements.plist
TrollStore_CFLAGS = -fobjc-arc -I../Shared
TrollStore_LDFLAGS = -L/opt/homebrew/lib -framework MobileCoreServices

include $(THEOS_MAKE_PATH)/application.mk
