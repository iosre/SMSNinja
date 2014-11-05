#import "SMSNinja-private.h"

@interface SNPrivateMessageHistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
{
	NSMutableArray *idArray;
	NSMutableArray *nameArray;
	NSMutableArray *numberArray;
	NSMutableArray *contentArray;
	NSMutableArray *timeArray;
	NSMutableArray *picturesArray;
	NSMutableSet *bulkSet;
	NSUInteger chosenRow;
}
- (void)loadDatabaseSegment;
- (void)selectAll:(UIBarButtonItem *)buttonItem;
- (void)bulkDelete;
- (void)segmentAction:(id)sender;
@end
