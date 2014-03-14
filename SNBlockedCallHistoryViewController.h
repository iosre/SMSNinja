#import "SMSNinja-private.h"

@interface SNBlockedCallHistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
{
	NSMutableArray *idArray;
	NSMutableArray *nameArray;
	NSMutableArray *numberArray;
	NSMutableArray *contentArray;
	NSMutableArray *timeArray;
	NSMutableArray *readArray;
	NSMutableSet *bulkSet;
	int chosenRow;
}
- (void)loadDatabaseSegment;
- (void)selectAll:(UIBarButtonItem *)buttonItem;
- (void)bulkDelete;
- (void)bulkUnread;
- (void)bulkRead;
- (void)segmentAction:(id)sender;
@end
