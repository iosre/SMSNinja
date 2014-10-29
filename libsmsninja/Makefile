ARCHS = armv7 arm64
TARGET = iphone:latest:5.0

include theos/makefiles/common.mk

TWEAK_NAME = libsmsninja
libsmsninja_FILES = libsmsninja.mm SNTelephonyManager.m Hook.xm
libsmsninja_FRAMEWORKS = UIKit AddressBook AudioToolbox CoreTelephony
libsmsninja_PRIVATE_FRAMEWORKS = AppSupport
libsmsninja_LDFLAGS = -lz -lsqlite3.0 -weak_framework CommunicationsFilter -weak_framework IMFoundation -weak_framework CallHistory
libsmsninja_LDFLAGS += -F$(SYSROOT)/System/Library/PrivateFrameworks -L$(SYSROOT)/usr/lib/system

include $(THEOS_MAKE_PATH)/tweak.mk
