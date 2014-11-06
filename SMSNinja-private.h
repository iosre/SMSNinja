#import <UIKit/UIKit.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

@interface UISwitch (private_5_6)
- (void)setAlternateColors:(BOOL)colors;
@end

@interface UITextView (private_5_6)
- (void)setContentToHTMLString:(NSString *)htmlstring;
@end

@interface CPDistributedMessagingCenter : NSObject
+ (instancetype)centerNamed:(id)named;
- (id)sendMessageAndReceiveReplyName:(id)name userInfo:(id)info;
- (BOOL)sendMessageName:(id)name userInfo:(id)info;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)messageName target:(id)target selector:(SEL)selector;
@end

@interface UIApplication (private_5_6_7)
- (void)terminateWithSuccess;
@property (NS_NONATOMIC_IOSONLY, getter=isLocked, readonly) BOOL locked;
@end
