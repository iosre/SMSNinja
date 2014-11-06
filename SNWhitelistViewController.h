#import "SNBlacklistViewController.h"
#import "SMSNinja-private.h"
#import <AddressBookUI/AddressBookUI.h>

@interface SNWhitelistViewController : UITableViewController <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, ABPeoplePickerNavigationControllerDelegate>
{
@public
	NSMutableArray *keywordArray;
	NSMutableArray *typeArray;
	NSMutableArray *nameArray;
}
@property (nonatomic, retain) NSString *chosenName;
@property (nonatomic, retain) NSString *chosenKeyword;
- (void)loadDatabaseSegment;
- (void)addRecord;
- (void)gotoNumberView;
- (void)gotoContentView;
- (void)gotoAddressbook;
- (void)gotoSystemMessageHistoryView;
- (void)gotoSystemCallHistoryView;
- (void)segmentAction:(UISegmentedControl *)sender;
@end
