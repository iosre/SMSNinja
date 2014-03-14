#import "SMSNinja-private.h"

@interface SNContentViewController : UITableViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>
{
	UITextField *nameField;
	UITextField *keywordField;
	UISwitch *forwardSwitch;
	UITextField *numberField;
	UISwitch *replySwitch;
	UITextField *messageField;
	UISwitch *soundSwitch;

	NSMutableArray *keywordArray;
	UITapGestureRecognizer *tapRecognizer;
}
@property (nonatomic, retain) NSString *nameString;
@property (nonatomic, retain) NSString *keywordString;
@property (nonatomic, retain) NSString *forwardString;
@property (nonatomic, retain) NSString *numberString;
@property (nonatomic, retain) NSString *replyString;
@property (nonatomic, retain) NSString *messageString;
@property (nonatomic, retain) NSString *soundString;
@property (nonatomic, retain) NSString *flag;
@property (nonatomic, retain) NSString *originalKeyword;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
- (void)saveTextFieldValues;
- (void)saveSwitchValues;
@end
