#import "SNWhitelistViewController.h"
#import "SNNumberViewController.h"
#import "SNContentViewController.h"
/*
#import "SNSystemMessageHistoryViewController.h"
#import "SNSystemCallHistoryViewController.h"
*/
#import "SNMainViewController.h"
#import <objc/runtime.h>
#import <notify.h>
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

static int amount;

@implementation SNWhitelistViewController

@synthesize chosenName;
@synthesize chosenKeyword;

- (void)dealloc
{
	[keywordArray release];
	keywordArray = nil;

	[typeArray release];
	typeArray = nil;

	[nameArray release];
	nameArray = nil;

	[chosenName release];
	chosenName = nil;

	[chosenKeyword release];
	chosenKeyword = nil;

	[super dealloc];
}

- (void)loadDatabaseSegment
{
	sqlite3 *database;
	sqlite3_stmt *statement;
	int openResult = sqlite3_open([DATABASE UTF8String], &database);
	if (openResult == SQLITE_OK)
	{
		NSString *sql = [NSString stringWithFormat:@"select keyword, type, name from whitelist limit %lu, 50", (unsigned long)[keywordArray count]];
		int prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
		if (prepareResult == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				char *keyword = (char *)sqlite3_column_text(statement, 0);
				[keywordArray addObject:keyword ? [NSString stringWithUTF8String:keyword] : @""];

				char *type = (char *)sqlite3_column_text(statement, 1);
				[typeArray addObject:type ? [NSString stringWithUTF8String:type] : @""];

				char *name = (char *)sqlite3_column_text(statement, 2);
				[nameArray addObject:name ? [NSString stringWithUTF8String:name] : @""];
			}
			sqlite3_finalize(statement);
		}
		else NSLog(@"SMSNinja: Failed to prepare %@, error %d", sql, prepareResult);

		sql = @"select count(*) from whitelist";
		prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
		if (prepareResult == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				char *count = (char *)sqlite3_column_text(statement, 0);
				amount = atoi(count);
			}
			sqlite3_finalize(statement);
		}
		else NSLog(@"SMSNinja: Failed to prepare %@, error %d", sql, prepareResult);

		sqlite3_close(database);
	}
	else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (SNWhitelistViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain]))
	{
		self.navigationItem.rightBarButtonItem = self.editButtonItem;

		keywordArray = [[NSMutableArray alloc] initWithCapacity:600];
		typeArray = [[NSMutableArray alloc] initWithCapacity:600];
		nameArray = [[NSMutableArray alloc] initWithCapacity:600];
		chosenName = [[NSString alloc] initWithFormat:@""];
		chosenKeyword = [[NSString alloc] initWithFormat:@""];

		[self loadDatabaseSegment];
	}
	return self;
}

- (void)segmentAction:(UISegmentedControl *)sender
{
	if (sender.selectedSegmentIndex == 1)
	{
		SNBlacklistViewController *blacklistViewController = [[SNBlacklistViewController alloc] init];
		UINavigationController *navigationController = self.navigationController;
		[navigationController popViewControllerAnimated:NO];
		[navigationController pushViewController:blacklistViewController animated:NO];
		[blacklistViewController release];
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"White", @"White"), NSLocalizedString(@"Black", @"Black"), nil]];
	segmentedControl.selectedSegmentIndex = 0;
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.frame = CGRectMake(0.0f, 0.0f, 100.0f, 30.0f);
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = segmentedControl;
	[segmentedControl release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"0"]) // NumberViewController
	{
		SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
		numberViewController.flag = @"white";
		numberViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		numberViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
		numberViewController.originalKeyword = numberViewController.keywordString;
		numberViewController.phoneAction = @"1";
		numberViewController.messageAction = @"1";
		numberViewController.replyString = @"0";
		numberViewController.messageString = @"";
		numberViewController.forwardString = @"0";
		numberViewController.numberString = @"";
		numberViewController.soundString = @"0";
		[self.navigationController pushViewController:numberViewController animated:YES];
		[numberViewController release];
	}
	else if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"1"]) // ContentViewController
	{
		SNContentViewController *contentViewController = [[SNContentViewController alloc] init];
		contentViewController.flag = @"white";
		contentViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		contentViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
		contentViewController.originalKeyword = contentViewController.keywordString;
		contentViewController.replyString = @"0";
		contentViewController.messageString = @"";
		contentViewController.forwardString = @"0";
		contentViewController.numberString = @"";
		contentViewController.soundString = @"0";
		[self.navigationController pushViewController:contentViewController animated:YES];
		[contentViewController release];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [keywordArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
	for (UIView *subview in [cell.contentView subviews])
		[subview removeFromSuperview];
	cell.textLabel.text = nil;
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, cell.contentView.bounds.size.width - 50.0f, (cell.contentView.bounds.size.height - 4.0f) / 2.0f)];
	nameLabel.text = [nameArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:nameLabel];
	[nameLabel release];

	UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.frame.size.height, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
	contentLabel.text = [keywordArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:contentLabel];
	[contentLabel release];

	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"Whitelist", @"Whitelist");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSSet *deleteSet = [NSSet setWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];

	sqlite3 *database;
	int openResult = sqlite3_open([DATABASE UTF8String], &database);
	if (openResult == SQLITE_OK)
	{
		for (NSIndexPath *chosenRowIndexPath in deleteSet)
		{
			NSString *sql = [NSString stringWithFormat:@"delete from whitelist where keyword = '%@' and type = '%@' and name = '%@'", [keywordArray objectAtIndex:chosenRowIndexPath.row], [typeArray objectAtIndex:chosenRowIndexPath.row], [[nameArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
			int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
			if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
		}
		sqlite3_close(database);

		notify_post("com.naken.smsninja.whitelistchanged");
	}
	else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);

	NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
	for (NSIndexPath *chosenRowIndexPath in deleteSet) [discardedItems addIndex:chosenRowIndexPath.row];

	[keywordArray removeObjectsAtIndexes:discardedItems];
	[typeArray removeObjectsAtIndexes:discardedItems];
	[nameArray removeObjectsAtIndexes:discardedItems];

	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths:[deleteSet allObjects] withRowAnimation:UITableViewRowAnimationFade];
	[tableView endUpdates];
}

- (void)gotoNumberView
{
	SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
	numberViewController.flag = @"white";
	numberViewController.nameString = @"";
	numberViewController.keywordString = @"";
	numberViewController.originalKeyword = numberViewController.keywordString;
	numberViewController.phoneAction = @"1";
	numberViewController.messageAction = @"1";
	numberViewController.replyString = @"0";
	numberViewController.messageString = @"";
	numberViewController.forwardString = @"0";
	numberViewController.numberString = @"";
	numberViewController.soundString = @"0";
	[self.navigationController pushViewController:numberViewController animated:YES];
	[numberViewController release];
}

- (void)gotoContentView
{
	SNContentViewController *contentViewController = [[SNContentViewController alloc] init];
	contentViewController.flag = @"white";
	contentViewController.nameString = @"";
	contentViewController.keywordString = @"";
	contentViewController.originalKeyword = contentViewController.keywordString;
	contentViewController.replyString = @"0";
	contentViewController.messageString = @"";
	contentViewController.forwardString = @"0";
	contentViewController.numberString = @"";
	contentViewController.soundString = @"0";
	[self.navigationController pushViewController:contentViewController animated:YES];
	[contentViewController release];
}

- (void)gotoSystemCallHistoryView
{
	CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
	[messagingCenter sendMessageName:@"LaunchMobilePhone" userInfo:nil];
	/*
	   SNSystemCallHistoryViewController *systemCallHistoryViewController = [[SNSystemCallHistoryViewController alloc] init];
	   systemCallHistoryViewController.flag = @"white";
	   [self.navigationController pushViewController:systemCallHistoryViewController animated:YES];
	   [systemCallHistoryViewController release];
	 */
}

- (void)gotoSystemMessageHistoryView
{
	CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
	[messagingCenter sendMessageName:@"LaunchMobileSMS" userInfo:nil];
	/*
	   SNSystemMessageHistoryViewController *systemMessageHistoryViewController = [[SNSystemMessageHistoryViewController alloc] init];
	   systemMessageHistoryViewController.flag = @"white";
	   [self.navigationController pushViewController:systemMessageHistoryViewController animated:YES];
	   [systemMessageHistoryViewController release];
	 */
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 0:
			[self gotoNumberView];
			break;
		case 1:
			[self gotoContentView];
			break;
		case 2:
			[self gotoAddressbook];
			break;
		case 3:
			[self gotoSystemCallHistoryView];
			break;
		case 4:
			[self gotoSystemMessageHistoryView];
			break;
	}
}

- (void)addRecord
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Enter numbers", @"Enter numbers"), NSLocalizedString(@"Enter keywords", @"Enter keywords"), NSLocalizedString(@"From addressbook", @"From addressbook"), NSLocalizedString(@"From call history", @"From call history"), NSLocalizedString(@"From message history", @"From message history"), nil];
	[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[actionSheet release];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if (editing) [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"Add") style:UIBarButtonItemStyleBordered target:self action:@selector(addRecord)] autorelease] animated:YES];
	else [self.navigationItem setLeftBarButtonItem:nil animated:animated];
	[super setEditing:editing animated:animated];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	CFIndex emailCounts = 0, phoneCounts = 0;
	ABPropertyID property = kABPersonEmailProperty;
	ABMultiValueRef emails = ABRecordCopyValue(person, property);
	if (emails)
	{
		emailCounts = ABMultiValueGetCount(emails);
		CFRelease(emails);
	}

	property = kABPersonPhoneProperty;
	ABMultiValueRef phones = ABRecordCopyValue(person, property);
	if (phones)
	{
		phoneCounts = ABMultiValueGetCount(phones);
		CFRelease(phones);
	}

	if (emailCounts + phoneCounts == 1)
	{
		if (emailCounts == 1) property = kABPersonEmailProperty;
		else property = kABPersonPhoneProperty;
	}
	else return YES;

	CFMutableStringRef firstName = (CFMutableStringRef)ABRecordCopyValue(person, kABPersonFirstNameProperty);
	CFMutableStringRef lastName =  (CFMutableStringRef)ABRecordCopyValue(person, kABPersonLastNameProperty);
	self.chosenName = nil;
	self.chosenName = [[firstName ? (NSString *)firstName : @"" stringByAppendingString:@" "] stringByAppendingString:lastName ? (NSString *)lastName : @""];
	if (firstName) CFRelease(firstName);
	if (lastName) CFRelease(lastName);

	ABMultiValueRef values = ABRecordCopyValue(person, property);
	if (!values) return NO;
	CFArrayRef valueArray = ABMultiValueCopyArrayOfAllValues(values);
	if (!valueArray)
	{
		CFRelease(values);
		return NO;
	}
	CFStringRef value = (CFStringRef)CFArrayGetValueAtIndex(valueArray, 0);
	if (!value)
	{
		CFRelease(values);
		CFRelease(valueArray);
		return NO;
	}

	NSString *tempString = (NSString *)value;
	tempString = [tempString stringByReplacingOccurrencesOfString:@" " withString:@""];
	tempString = [tempString stringByReplacingOccurrencesOfString:@"-" withString:@""];
	tempString = [tempString stringByReplacingOccurrencesOfString:@"(" withString:@""];
	tempString = [tempString stringByReplacingOccurrencesOfString:@")" withString:@""];

	self.chosenKeyword = nil;
	self.chosenKeyword = tempString;

	CFRelease(values);
	CFRelease(valueArray);

	__block SNWhitelistViewController *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		sqlite3 *database;
		int openResult = sqlite3_open([DATABASE UTF8String], &database);
		if (openResult == SQLITE_OK)
		{
			NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '1', '1', '0', '', '0', '', '0')", weakSelf.chosenKeyword, [weakSelf.chosenName stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
			int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
			if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
			sqlite3_close(database);

			notify_post("com.naken.smsninja.whitelistchanged");
		}
		else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
	});

	[keywordArray addObject:self.chosenKeyword];
	[typeArray addObject:@"0"];
	[nameArray addObject:self.chosenName];

	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([keywordArray count] - 1) inSection:0]] withRowAnimation:YES];
	[self.tableView endUpdates];

	[self dismissModalViewControllerAnimated:YES];

	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	if (property == kABPersonEmailProperty || property == kABPersonPhoneProperty)
	{
		CFMutableStringRef firstName = (CFMutableStringRef)ABRecordCopyValue(person, kABPersonFirstNameProperty);
		CFMutableStringRef lastName =  (CFMutableStringRef)ABRecordCopyValue(person, kABPersonLastNameProperty);
		self.chosenName = nil;
		self.chosenName = [[firstName ? (NSString *)firstName : @"" stringByAppendingString:@" "] stringByAppendingString:lastName ? (NSString *)lastName : @""];
		if (firstName) CFRelease(firstName);
		if (lastName) CFRelease(lastName);

		ABMultiValueRef keywords = ABRecordCopyValue(person, property);
		if (!keywords) return NO;
		CFStringRef keyword = (CFStringRef)ABMultiValueCopyValueAtIndex(keywords, ABMultiValueGetIndexForIdentifier(keywords, identifier));
		if (!keyword)
		{
			CFRelease(keywords);
			return NO;
		}

		NSString *tempString = (NSString *)keyword;
		tempString = [tempString stringByReplacingOccurrencesOfString:@" " withString:@""];
		tempString = [tempString stringByReplacingOccurrencesOfString:@"-" withString:@""];
		tempString = [tempString stringByReplacingOccurrencesOfString:@"(" withString:@""];
		tempString = [tempString stringByReplacingOccurrencesOfString:@")" withString:@""];

		self.chosenKeyword = nil;
		self.chosenKeyword = tempString;

		CFRelease(keyword);
		CFRelease(keywords);

		__block SNWhitelistViewController *weakSelf = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			sqlite3 *database;
			int openResult = sqlite3_open([DATABASE UTF8String], &database);
			if (openResult == SQLITE_OK)
			{
				NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '1', '1', '0', '', '0', '', '0')", weakSelf.chosenKeyword, [weakSelf.chosenName stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
				int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
				if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
				sqlite3_close(database);

            			notify_post("com.naken.smsninja.whitelistchanged");
			}
			else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
		});

		[keywordArray addObject:self.chosenKeyword];
		[typeArray addObject:@"0"];
		[nameArray addObject:self.chosenName];

		[self.tableView beginUpdates];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([keywordArray count] - 1) inSection:0]] withRowAnimation:YES];
		[self.tableView endUpdates];

		[self dismissModalViewControllerAnimated:YES];
	}
	return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)gotoAddressbook
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (amount != [keywordArray count] && scrollView.contentOffset.y + 1000.0f > scrollView.contentSize.height - scrollView.frame.size.height && scrollView.contentOffset.y != -64.0f && scrollView.contentOffset.y != 0.0f)
	{
		[self.tableView beginUpdates];
		int count = [keywordArray count];
		[self loadDatabaseSegment];
		NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:50];
		for (int i = count; i < [keywordArray count]; i++)
		{
			NSIndexPath *newPath =  [NSIndexPath indexPathForRow:i inSection:0];
			[insertIndexPaths insertObject:newPath atIndex:(i - count)];
		}
		[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
	}
}
@end
