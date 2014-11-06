#import "SMSNinja-private.h"

@interface SNSystemCallHistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
{
	NSMutableArray *numberArray;
	NSMutableArray *nameArray;
	NSMutableArray *timeArray;
	NSMutableArray *typeArray;
	NSMutableSet *keywordSet;
	NSUInteger chosenRow;
}
@property (nonatomic, retain) NSString *flag;
- (void)initializeAllArrays;
- (void)selectAll:(UIBarButtonItem *)buttonItem;
@end
