#import "SMSNinja-private.h"

@interface SNMessageActionViewController : UITableViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>
{
	UISwitch *forwardSwitch;
	UITextField *numberField;
	UITapGestureRecognizer *tapRecognizer;
}
@property (nonatomic, retain) NSString *messageAction;
@property (nonatomic, retain) NSString *forwardString;
@property (nonatomic, retain) NSString *numberString;
- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap;
@end
