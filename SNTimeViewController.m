#import "SNTimeViewController.h"
#import "SNCallActionViewController.h"
#import "SNMessageActionViewController.h"
#import "SNTextTableViewCell.h"
#import "SNBlacklistViewController.h"
#import <notify.h>
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

@implementation SNTimeViewController

@synthesize keywordString;
@synthesize nameString;
@synthesize phoneAction;
@synthesize messageAction;
@synthesize replyString;
@synthesize messageString;
@synthesize soundString;
@synthesize forwardString;
@synthesize numberString;
@synthesize originalKeyword;

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[timePickerView release];
	timePickerView = nil;

	[settingsTableView release];
	settingsTableView = nil;

	[nameString release];
	nameString = nil;

	[keywordString release];
	keywordString = nil;

	[phoneAction release];
	phoneAction = nil;

	[messageAction release];
	messageAction = nil;

	[replyString release];
	replyString = nil;

	[messageString release];
	messageString = nil;

	[forwardString release];
	forwardString = nil;

	[soundString release];
	soundString = nil;

	[nameField release];
	nameField = nil;

	[replySwitch release];
	replySwitch = nil;

	[messageField release];
	messageField = nil;

	[soundSwitch release];
	soundSwitch = nil;

	[originalKeyword release];
	originalKeyword = nil;

	[tapRecognizer release];
	tapRecognizer = nil;

	[super dealloc];
}

- (SNTimeViewController *)init
{
	if ((self = [super init]))
	{
		self.title= NSLocalizedString(@"Time", @"Time");

		nameField = [[UITextField alloc] initWithFrame:CGRectZero];
		replySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		messageField = [[UITextField alloc] initWithFrame:CGRectZero];
		soundSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];

		tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardWithTap:)];
		tapRecognizer.delegate = self;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	timePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, self.view.bounds.size.height / 2.0f)];
	timePickerView.delegate = self;
	timePickerView.showsSelectionIndicator = YES;
	timePickerView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:timePickerView];

	NSString *duration = self.keywordString;
	NSString *one = [duration substringToIndex:[duration rangeOfString:@":"].location];
	duration = [duration substringFromIndex:[duration rangeOfString:@":"].location + 1];
	NSString *two = [duration substringToIndex:[duration rangeOfString:@"~"].location];
	duration = [duration substringFromIndex:[duration rangeOfString:@"~"].location + 1];
	NSString *three = [duration substringToIndex:[duration rangeOfString:@":"].location];
	duration = [duration substringFromIndex:[duration rangeOfString:@":"].location + 1];
	NSString *four = duration;

	[timePickerView selectRow:(4800 + [one intValue]) inComponent:0 animated:YES];
	[timePickerView selectRow:(4800 + [two intValue]) inComponent:1 animated:YES];
	[timePickerView selectRow:0 inComponent:2 animated:YES];
	[timePickerView selectRow:(4800 + [three intValue]) inComponent:3 animated:YES];
	[timePickerView selectRow:(4800 + [four intValue]) inComponent:4 animated:YES];

	settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, timePickerView.bounds.size.height, timePickerView.bounds.size.width, self.view.bounds.size.height - timePickerView.bounds.size.height - (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0 ? self.navigationController.navigationBar.frame.size.height : 0.0f)) style:UITableViewStyleGrouped];
	settingsTableView.dataSource = self;
	settingsTableView.delegate = self;
	[self.view addSubview:settingsTableView];

	[settingsTableView addGestureRecognizer:tapRecognizer];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 5;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (component == 2)
		return 1;

	return 10000;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return 50.0f;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (component == 0 || component == 3)
		return [NSString stringWithFormat:(row % 24 < 10 ? @"0%ld" : @"%ld"), (long)(row % 24)];
	else if (component == 1 || component == 4)
		return [NSString stringWithFormat:(row % 60 < 10 ? @"0%ld" : @"%ld"), (long)(row % 60)];
	return @"~";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0 || section == 3)
		return 1;
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SNTextTableViewCell *cell = [settingsTableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[SNTextTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"any-cell"] autorelease];
	for (UIView *subview in [cell.contentView subviews])
		[subview removeFromSuperview];
	cell.textLabel.text = nil;
	cell.detailTextLabel.text = nil;
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;

	switch (indexPath.section)
	{
		case 0:
			cell.textLabel.text = NSLocalizedString(@"Name", @"Name");
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			nameField.delegate = self;
			nameField.placeholder = NSLocalizedString(@"Input here", @"Input here");
			nameField.text = self.nameString;
			nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
			[cell.contentView addSubview:nameField];

			break;
		case 1:
			if (indexPath.row == 0)
			{
				cell.textLabel.text = NSLocalizedString(@"Call", @"Call");
				NSString *detailText = @"";
				if ([self.phoneAction isEqualToString:@"1"]) detailText = NSLocalizedString(@"Disconnect", @"Disconnect");
				else if ([self.phoneAction isEqualToString:@"2"]) detailText = NSLocalizedString(@"Ignore", @"Ignore");
				cell.detailTextLabel.text = detailText;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}
			else if (indexPath.row == 1)
			{
				cell.textLabel.text = NSLocalizedString(@"SMS", @"SMS");
				NSString *detailText = @"";
				if ([self.messageAction isEqualToString:@"1"]) detailText = [detailText stringByAppendingString:NSLocalizedString(@"Block", @"Block")];
				if ([self.forwardString isEqualToString:@"1"]) detailText = [detailText stringByAppendingString:NSLocalizedString(@", Forward", @", Forward")];
				if ([detailText hasPrefix:@", "]) detailText = [detailText substringFromIndex:2];
				cell.detailTextLabel.text = detailText;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			}

			break;
		case 2:
			if (indexPath.row == 0)
			{
				cell.textLabel.text = NSLocalizedString(@"Reply", @"Reply");
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.accessoryView = replySwitch;
				replySwitch.on = [self.replyString isEqualToString:@"0"] ? NO : YES;
				[replySwitch addTarget:self action:@selector(saveSwitchValues) forControlEvents:UIControlEventValueChanged];
			}
			else if (indexPath.row == 1)
			{
				cell.textLabel.text = NSLocalizedString(@"With", @"With");
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				messageField.delegate = self;
				messageField.text = self.messageString;
				messageField.clearButtonMode = UITextFieldViewModeWhileEditing;
				messageField.placeholder = NSLocalizedString(@"Message here", @"Message here");
				[cell.contentView addSubview:messageField];
			}

			break;
		case 3:
			cell.textLabel.text = NSLocalizedString(@"Beep", @"Beep");
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			cell.accessoryView = soundSwitch;
			soundSwitch.on = [self.soundString isEqualToString:@"0"] ? NO : YES;
			[soundSwitch addTarget:self action:@selector(saveSwitchValues) forControlEvents:UIControlEventValueChanged];

			break;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (indexPath.section == 1)
	{
		switch (indexPath.row)
		{
			case 0:
				{
					SNCallActionViewController *callActionViewController = [[SNCallActionViewController alloc] init];
					callActionViewController.phoneAction = self.phoneAction;
					callActionViewController.flag = @"black";
					[self.navigationController pushViewController:callActionViewController animated:YES];
					[callActionViewController release];
					break;
				}
			case 1:
				{
					SNMessageActionViewController *messageActionViewController = [[SNMessageActionViewController alloc] init];
					messageActionViewController.messageAction = self.messageAction;
					messageActionViewController.forwardString = self.forwardString;
					messageActionViewController.numberString = self.numberString;
					[self.navigationController pushViewController:messageActionViewController animated:YES];
					[messageActionViewController release];
					break;
				}
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self saveTextFieldValues];

	NSString *one = [NSString stringWithFormat:([timePickerView selectedRowInComponent:0] % 24 < 10 ? @"0%ld" : @"%ld"), (long)([timePickerView selectedRowInComponent:0] % 24)];
	NSString *two = [NSString stringWithFormat:([timePickerView selectedRowInComponent:1] % 60 < 10 ? @"0%ld" : @"%ld"), (long)([timePickerView selectedRowInComponent:1] % 60)];
	NSString *three = [NSString stringWithFormat:([timePickerView selectedRowInComponent:3] % 24 < 10 ? @"0%ld" : @"%ld"), (long)([timePickerView selectedRowInComponent:3] % 24)];
	NSString *four = [NSString stringWithFormat:([timePickerView selectedRowInComponent:4] % 60 < 10 ? @"0%ld" : @"%ld"), (long)([timePickerView selectedRowInComponent:4] % 60)];
	NSString *keyword = [[[[[[one stringByAppendingString:@":"] stringByAppendingString:two] stringByAppendingString:@"~"] stringByAppendingString:three] stringByAppendingString:@":"] stringByAppendingString:four];

	id viewController = self.navigationController.topViewController;
	if ([viewController isKindOfClass:[SNCallActionViewController class]] || [viewController isKindOfClass:[SNMessageActionViewController class]]) return;

	__block SNTimeViewController *weakSelf = self;
	__block NSUInteger index = [((SNBlacklistViewController *)viewController)->keywordArray indexOfObject:self.originalKeyword];
	dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		sqlite3 *database;
		int openResult = sqlite3_open([DATABASE UTF8String], &database);
		if (openResult == SQLITE_OK)
		{
			NSString *sql = @"";
			if ([keyword isEqualToString:weakSelf.originalKeyword] && index != NSNotFound) sql = [NSString stringWithFormat:@"update blacklist set keyword = '%@', type = '2', name = '%@', phone = '%@', sms = '%@', reply = '%@', message = '%@', forward = '%@', number = '%@', sound = '%@' where keyword = '%@'", keyword, weakSelf.nameString, weakSelf.phoneAction, weakSelf.messageAction, weakSelf.replyString, weakSelf.messageString, weakSelf.forwardString, weakSelf.numberString, weakSelf.soundString, weakSelf.keywordString];
			else sql = [NSString stringWithFormat:@"insert or replace into blacklist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '2', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')", keyword, weakSelf.nameString, weakSelf.phoneAction, weakSelf.messageAction, weakSelf.replyString, weakSelf.messageString, weakSelf.forwardString, weakSelf.numberString, weakSelf.soundString];
			int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
			if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
			sqlite3_close(database);

			notify_post("com.naken.smsninja.blacklistchanged");
		}
		else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
	});

	if ([keyword isEqualToString:self.originalKeyword] && index != NSNotFound)
	{
		[((SNBlacklistViewController *)viewController)->keywordArray replaceObjectAtIndex:index withObject:keyword];
		[((SNBlacklistViewController *)viewController)->nameArray replaceObjectAtIndex:index withObject:self.nameString];
		[((SNBlacklistViewController *)viewController)->replyArray replaceObjectAtIndex:index withObject:self.replyString];
		[((SNBlacklistViewController *)viewController)->messageArray replaceObjectAtIndex:index withObject:self.messageString];
		[((SNBlacklistViewController *)viewController)->forwardArray replaceObjectAtIndex:index withObject:self.forwardString];
		[((SNBlacklistViewController *)viewController)->numberArray replaceObjectAtIndex:index withObject:self.numberString];
		[((SNBlacklistViewController *)viewController)->soundArray replaceObjectAtIndex:index withObject:self.soundString];
		[((SNBlacklistViewController *)viewController)->smsArray replaceObjectAtIndex:index withObject:self.messageAction];
		[((SNBlacklistViewController *)viewController)->phoneArray replaceObjectAtIndex:index withObject:self.phoneAction];
	}
	else
	{
		if (![((SNBlacklistViewController *)viewController)->keywordArray containsObject:keyword])
		{
			[((SNBlacklistViewController *)viewController)->keywordArray addObject:keyword];
			[((SNBlacklistViewController *)viewController)->typeArray addObject:@"2"];
			[((SNBlacklistViewController *)viewController)->nameArray addObject:self.nameString];
			[((SNBlacklistViewController *)viewController)->messageArray addObject:self.messageString];
			[((SNBlacklistViewController *)viewController)->numberArray addObject:self.numberString];
			[((SNBlacklistViewController *)viewController)->smsArray addObject:self.messageAction];
			[((SNBlacklistViewController *)viewController)->phoneArray addObject:self.phoneAction];
			[((SNBlacklistViewController *)viewController)->forwardArray addObject:self.forwardString];
			[((SNBlacklistViewController *)viewController)->replyArray addObject:self.replyString];
			[((SNBlacklistViewController *)viewController)->soundArray addObject:self.soundString];
		}
	}
	[((UITableViewController *)viewController).tableView reloadData];
}

- (void)saveTextFieldValues
{
	if (nameField)
	{
		self.nameString = nil;
		self.nameString = nameField.text ? nameField.text : @"";
	}
	if (messageField)
	{
		self.messageString = nil;
		self.messageString = messageField.text ? messageField.text : @"";
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self saveTextFieldValues];
	[textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	float movementDuration = [(NSNumber *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int movementDistance = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 ? self.navigationController.navigationBar.frame.size.height : 0.0f);

	[UIView beginAnimations:@"animation" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration: movementDuration];
	self.view.center = CGPointMake(self.view.center.x, self.view.center.y - movementDistance);
	[UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	NSDictionary *userInfo = [notification userInfo];
	float movementDuration = [(NSNumber *)[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int movementDistance = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height - (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 ? self.navigationController.navigationBar.frame.size.height : 0.0f);

	[UIView beginAnimations:@"animation" context:nil];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:movementDuration];
	self.view.center = CGPointMake(self.view.center.x, self.view.center.y + movementDistance);
	[UIView commitAnimations];
}

- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap
{
	[nameField resignFirstResponder];
	[messageField resignFirstResponder];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (gestureRecognizer == tapRecognizer && ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:NSClassFromString(@"UITableViewCellContentView")])) return NO;
	return YES;
}

- (void)saveSwitchValues
{
	if (replySwitch)
	{
		self.replyString = nil;
		self.replyString = replySwitch.on ? @"1" : @"0";
	}
	if (soundSwitch)
	{
		self.soundString = nil;
		self.soundString = soundSwitch.on ? @"1" : @"0";
	}
}
@end
