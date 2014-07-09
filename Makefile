THEOS_DEVICE_IP = 192.168.2.10
#THEOS_DEVICE_PORT = 2222
ARCHS = armv7 armv7s arm64
TARGET = iphone:latest:5.0

include theos/makefiles/common.mk

APPLICATION_NAME = SMSNinja
SMSNinja_FILES = main.m SMSNinjaApplication.m SNBlacklistViewController.m SNBlockedCallHistoryViewController.m SNBlockedMessageHistoryViewController.m SNCallActionViewController.m SNContentViewController.m SNMainViewController.m SNMessageActionViewController.m SNNumberViewController.m SNPictureViewController.m SNPrivateCallHistoryViewController.m SNPrivatelistViewController.m SNPrivateMessageHistoryViewController.m SNPrivateViewController.m SNReadMeViewController.m SNSettingsViewController.m SNTextTableViewCell.m SNTimeViewController.m SNWhitelistViewController.m
SMSNinja_FRAMEWORKS = UIKit Foundation CoreGraphics AddressBookUI AddressBook
SMSNinja_LDFLAGS = -lz -lsqlite3.0

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall -9 SpringBoard"
