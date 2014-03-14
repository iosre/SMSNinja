#import "SMSNinja-private.h"

@interface SNPrivateViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    UITextField *fakePasswordField;
	UISwitch *purpleSwitch;
	UISwitch *semicolonSwitch;
    UISwitch *revealSwitch;
    UITapGestureRecognizer *tapRecognizer;
}
- (void)saveSettings;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
@end
