#import "SMSNinja-private.h"

@interface SNSettingsViewController : UITableViewController <UIAlertViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    UISwitch *iconBadgeSwitch;
    UISwitch *statusBarBadgeSwitch;
    UISwitch *hideIconSwitch;
    UISwitch *clearSwitch;
    UISwitch *addressbookSwitch;
    UITextField *passwordField;
    UITextField *launchCodeField;
    
    UITapGestureRecognizer *tapRecognizer;
}
@property (nonatomic, retain) NSNumber *fake;
- (void)resetSettings;
- (void)saveSettings;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
- (void)saveTextFieldValues;
@end
