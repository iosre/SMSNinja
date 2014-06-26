#import "SMSNinja-private.h"

@interface SNPrivateViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
	UITextField *fakePasswordField;
	UISwitch *purpleSwitch;
	UISwitch *semicolonSwitch;
	UISwitch *revealSwitch;
	UITapGestureRecognizer *tapRecognizer;
}
- (void)saveSettingsFromSource:(UIControl *)control;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
@end
