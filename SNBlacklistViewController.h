#import "SMSNinja-private.h"
#import <AddressBookUI/AddressBookUI.h>

@interface SNBlacklistViewController : UITableViewController <UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, ABPeoplePickerNavigationControllerDelegate>
{
	NSMutableArray *keywordArray;
	NSMutableArray *typeArray;
	NSMutableArray *nameArray;
	NSMutableArray *phoneArray;
	NSMutableArray *smsArray;
	NSMutableArray *replyArray;
	NSMutableArray *messageArray;
	NSMutableArray *forwardArray;
	NSMutableArray *numberArray;
	NSMutableArray *soundArray;
}
@property (nonatomic, retain) NSString *chosenName;
@property (nonatomic, retain) NSString *chosenKeyword;
- (void)loadDatabaseSegment;
- (void)addRecord;
- (void)gotoNumberView;
- (void)gotoContentView;
- (void)gotoTimeView;
- (void)gotoAddressbook;
- (void)gotoSystemMessageHistoryView;
- (void)gotoSystemCallHistoryView;
- (void)segmentAction:(UISegmentedControl *)sender;
@end
