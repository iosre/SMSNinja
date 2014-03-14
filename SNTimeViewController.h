#import "SMSNinja-private.h"

@interface SNTimeViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>
{
    UITextField *nameField;
    UISwitch *replySwitch;
    UITextField *messageField;
    UISwitch *soundSwitch;
@public
	UITableView *settingsTableView;
@private
    UIPickerView *timePickerView;
    UITapGestureRecognizer *tapRecognizer;
}
@property (nonatomic, retain) NSString *keywordString;
@property (nonatomic, retain) NSString *nameString;
@property (nonatomic, retain) NSString *phoneAction;
@property (nonatomic, retain) NSString *messageAction;
@property (nonatomic, retain) NSString *replyString;
@property (nonatomic, retain) NSString *messageString;
@property (nonatomic, retain) NSString *soundString;
@property (nonatomic, retain) NSString *forwardString; // in another view
@property (nonatomic, retain) NSString *numberString; // in another view
@property (nonatomic, retain) NSString *originalKeyword;
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
- (void)saveTextFieldValues;
- (void)saveSwitchValues;
@end
