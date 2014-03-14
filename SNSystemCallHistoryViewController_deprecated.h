#import "SMSNinja-private.h"

@interface SNSystemCallHistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
{
@public
	NSMutableArray *numberArray;
	NSMutableArray *nameArray;
	NSMutableArray *timeArray;
	NSMutableArray *typeArray;
    NSMutableSet *keywordSet;
	int chosenRow;
}
@property (nonatomic, retain) NSString *flag;
- (void)initializeAllArrays;
- (void)selectAll:(UIBarButtonItem *)buttonItem;
@end