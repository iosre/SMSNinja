#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#include <dispatch/dispatch.h>
#import <AddressBook/AddressBook.h>
#import <sqlite3.h>
#import <notify.h>
#import <dlfcn.h>
#import <objc/runtime.h>
#import "SNTelephonyManager.h"
#import "libsmsninja-private.h"
#import "xpc.h"

#define DEBUG

#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#define PICTURES @"/var/mobile/Library/SMSNinja/Pictures/"
#define PRIVATEPICTURES @"/var/mobile/Library/SMSNinja/PrivatePictures/"

__attribute__((visibility("hidden")))
extern NSDictionary *settings;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackKeywordArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackTypeArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackNameArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackPhoneArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackSmsArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackReplyArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackMessageArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackForwardArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackNumberArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *blackSoundArray;

__attribute__((visibility("hidden")))
extern NSMutableArray *whiteKeywordArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteTypeArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteNameArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whitePhoneArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteSmsArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteReplyArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteMessageArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteForwardArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteNumberArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *whiteSoundArray;

__attribute__((visibility("hidden")))
extern NSMutableArray *privateKeywordArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateTypeArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateNameArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privatePhoneArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateSmsArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateReplyArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateMessageArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateForwardArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateNumberArray;
__attribute__((visibility("hidden")))
extern NSMutableArray *privateSoundArray;

__attribute__((visibility("hidden")))
extern "C" NSString *CurrentTime(void);
__attribute__((visibility("hidden")))
extern "C" void LoadBlacklist(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
__attribute__((visibility("hidden")))
extern "C" void LoadWhitelist(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
__attribute__((visibility("hidden")))
extern "C" void LoadPrivatelist(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
__attribute__((visibility("hidden")))
extern "C" void LoadAllLists(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
__attribute__((visibility("hidden")))
extern "C" void LoadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);
__attribute__((visibility("hidden")))
extern "C" void UpdateBadge(void);
__attribute__((visibility("hidden")))
extern "C" void ShowIcon(void);
__attribute__((visibility("hidden")))
extern "C" void HideIcon(void);
__attribute__((visibility("hidden")))
extern "C" void ShowPurpleSquare(void);
__attribute__((visibility("hidden")))
extern "C" void HidePurpleSquare(void);
__attribute__((visibility("hidden")))
extern "C" void PlayFilterSound(void);
__attribute__((visibility("hidden")))
extern "C" void PlayBlockSound(void);
__attribute__((visibility("hidden")))
extern "C" void ReloadConversation(void); // 5

__attribute__((visibility("hidden")))
extern "C" NSUInteger ActionOfTextFunctionWithInfo(NSArray *addressArray, NSString *text, NSArray *pictureArray, BOOL isFromMe); // 0 for off, 1 for filter, 2 for block
__attribute__((visibility("hidden")))
extern "C" NSUInteger ActionOfAudioFunctionWithInfo(NSArray *addressArray, BOOL isFromMe); // 0 for off, 1 for disconnect, 2 for ignore, 3 for let go

extern "C" CFStringRef UIFormattedPhoneNumberFromStringWithCountry(CFStringRef, CFStringRef);
extern "C" CFStringRef CTSettingCopyMyPhoneNumber(CFAllocatorRef);
extern "C" CFStringRef CPPhoneNumberCopyActiveCountryCode(CFAllocatorRef);
extern "C" ABRecordRef ABAddressBookFindPersonMatchingEmailAddress(ABAddressBookRef, CFStringRef, NSUInteger *);
extern "C" ABRecordRef ABAddressBookFindPersonMatchingPhoneNumber(ABAddressBookRef, CFStringRef, NSUInteger *, int);
extern "C" ABRecordRef ABAddressBookFindPersonMatchingPhoneNumberWithCountry(ABAddressBookRef, CFStringRef, CFStringRef, NSUInteger *, int);
extern "C" CFStringRef CTCallCopyAddress(CFAllocatorRef, CTCallRef);
extern "C" int CTCallGetStatus(CTCallRef);
extern "C" void CTCallDeleteFromCallHistory(CTCallRef);
extern "C" void CTCallDisconnect(CTCallRef);
extern "C" BOOL CTCallIsOutgoing(CTCallRef);
extern "C" BOOL CTCallGetStartTime(CTCallRef, double *);
extern "C" CFArrayRef _CTCallCopyAllCalls(void);
extern "C" BOOL IMInsertBoolsToXPCDictionary(void *, const char *, BOOL, const char *); // 7

@interface NSString (libsmsninja)
- (NSString *)normalizedPhoneNumber;	
- (BOOL)isRegularlyEqualTo:(NSString *)stringInList;
- (NSString *)stringByRemovingCharacters;
- (NSUInteger)indexInPrivateListWithType:(int)type; // number, content
- (NSUInteger)indexInBlackListWithType:(int)type; // number, content, time
- (NSUInteger)indexInWhiteListWithType:(int)type; // number, content
- (BOOL)isInAddressBook; // number
- (NSString *)nameInAddressBook; // number
@end

@interface LSStatusBarItem : NSObject
- (id) initWithIdentifier:(NSString*)identifier alignment:(int)alignment;
@property (nonatomic, assign) NSString* titleString;
@end
