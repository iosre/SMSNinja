#import "SMSNinja-private.h"

@interface SNMainViewController : UITableViewController <UITableViewDelegate, UIAlertViewDelegate>
{
	UISwitch *appSwitch;
}
@property (nonatomic, retain) NSNumber *fake;
- (void)saveSettings;
- (void)gotoSettingsView;
- (void)gotoReadMeView;
- (void)updateDatabase;
@end
