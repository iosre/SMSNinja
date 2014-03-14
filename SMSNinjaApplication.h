#import "SMSNinja-private.h"
#import "SNMainViewController.h"

@interface SMSNinjaApplication: UIApplication <UIApplicationDelegate, UIAlertViewDelegate>
{
	UIWindow *_window;
	SNMainViewController *_viewController;
	UINavigationController *navigationController;
}
@property (nonatomic, retain) UIWindow *window;
- (void)showPasswordAlert;
- (void)updateBadgeAndSquareAndIcon;
@end
