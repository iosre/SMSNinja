#import "libsmsninja-private.h"

@interface SNTelephonyManager : NSObject
+ (id)sharedManager;
- (int)iMessageAvailabilityOfAddress:(NSString *)address;
- (void)sendIMessageWithText:(NSString *)text address:(NSString *)address;
- (void)sendSMSWithText:(NSString *)text address:(NSString *)address;
- (void)sendMessageWithText:(NSString *)text address:(NSString *)address;
- (void)reply:(NSString *)address with:(NSString *)text;
- (void)forward:(NSString *)text to:(NSString *)address;
@end
