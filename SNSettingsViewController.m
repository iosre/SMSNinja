#import "SNSettingsViewController.h"
#import "SNMainViewController.h"
#import "SNTextTableViewCell.h"
#import <notify.h>
#import <objc/runtime.h>

#ifndef SMSNinjaDebug
#define DOCUMENT @"/var/mobile/Library/SMSNinja"
#else
#define DOCUMENT @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja"
#endif

#define SETTINGS [DOCUMENT stringByAppendingString:@"/smsninja.plist"]
#define DATABASE [DOCUMENT stringByAppendingString:@"/smsninja.db"]
#define PICTURES [DOCUMENT stringByAppendingString:@"/Pictures/"]
#define PRIVATEPICTURES [DOCUMENT stringByAppendingString:@"/PrivatePictures/"]

@implementation SNSettingsViewController

@synthesize fake;

- (void)dealloc
{
	[iconBadgeSwitch release];
	iconBadgeSwitch = nil;

	[statusBarBadgeSwitch release];
	statusBarBadgeSwitch = nil;

	[hideIconSwitch release];
	hideIconSwitch = nil;

	[clearSwitch release];
	clearSwitch = nil;

	[addressbookSwitch release];
	addressbookSwitch = nil;

	[passwordField release];
	passwordField = nil;

	[launchCodeField release];
	launchCodeField = nil;

	[tapRecognizer release];
	tapRecognizer = nil;

	[super dealloc];
}

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title = NSLocalizedString(@"Settings", @"Settings");
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", @"Reset") style:UIBarButtonItemStylePlain target:self action:@selector(resetSettings)] autorelease];

		iconBadgeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		statusBarBadgeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		hideIconSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		clearSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		addressbookSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		passwordField = [[UITextField alloc] initWithFrame:CGRectZero];
		launchCodeField = [[UITextField alloc] initWithFrame:CGRectZero];

		tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardWithTap:)];
		tapRecognizer.delegate = self;
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:	return 6;
		case 1:	return 4;
		case 2:	return 1;
		case 3:	return 2;
		default : return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:	return NSLocalizedString(@"General" ,@"General");
		case 1:	return NSLocalizedString(@"Call", @"Call");
		case 2:	return @"";
		case 3:	return NSLocalizedString(@"About", @"About");
		default : return @"";
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SNTextTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[SNTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
	for (UIView *subview in [cell.contentView subviews]) [subview removeFromSuperview];
	cell.textLabel.text = nil;
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
	switch (indexPath.section)
	{
		case 0: // General
			{
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.accessoryView = nil;
				switch (indexPath.row)
				{
					case 0:
					{
						cell.textLabel.text = NSLocalizedString(@"Password", @"Password");
						passwordField.delegate = self;
						passwordField.secureTextEntry = YES;
						passwordField.placeholder = NSLocalizedString(@"Input here", @"Input here");
						passwordField.text = [dictionary objectForKey:@"startPassword"];
						passwordField.clearButtonMode = UITextFieldViewModeWhileEditing;
						if ([cell.contentView.subviews indexOfObject:passwordField] == NSNotFound)  [cell.contentView addSubview:passwordField];
						break;
					}
					case 1:
					{
						cell.textLabel.text = NSLocalizedString(@"Launch Code", @"Launch Code");
						launchCodeField.delegate = self;
						launchCodeField.secureTextEntry = YES;
						launchCodeField.keyboardType = UIKeyboardTypeNumberPad;
						launchCodeField.placeholder = NSLocalizedString(@"Numbers only", @"Numbers only");
						launchCodeField.text = [dictionary objectForKey:@"launchCode"];
						launchCodeField.clearButtonMode = UITextFieldViewModeWhileEditing;
						if ([cell.contentView.subviews indexOfObject:launchCodeField] == NSNotFound) [cell.contentView addSubview:launchCodeField];
						break;
					}
					case 2:
					{
						cell.textLabel.text = NSLocalizedString(@"Hide Icon", @"Hide Icon");
						cell.accessoryView = hideIconSwitch;
						hideIconSwitch.on = [[dictionary objectForKey:@"shouldHideIcon"] boolValue];
						[hideIconSwitch addTarget:self action:@selector(saveSettingsFromSource:) forControlEvents:UIControlEventValueChanged];
						break;
					}
					case 3:
					{
						cell.textLabel.text = NSLocalizedString(@"Icon Badge", @"Icon Badge");
						cell.accessoryView = iconBadgeSwitch;
						iconBadgeSwitch.on = [[dictionary objectForKey:@"shouldShowIconBadge"] boolValue];
						[iconBadgeSwitch addTarget:self action:@selector(saveSettingsFromSource:) forControlEvents:UIControlEventValueChanged];
						break;
					}
					case 4:
					{
						cell.textLabel.text = NSLocalizedString(@"Statusbar Badge", @"Statusbar Badge");
						cell.accessoryView = statusBarBadgeSwitch;
						statusBarBadgeSwitch.on = [[dictionary objectForKey:@"shouldShowStatusBarBadge"] boolValue];
						[statusBarBadgeSwitch addTarget:self action:@selector(saveSettingsFromSource:) forControlEvents:UIControlEventValueChanged];
						break;
					}
					case 5:
					{
						cell.textLabel.text = NSLocalizedString(@"Contacts ⊆ Whitelist", @"Contacts ⊆ Whitelist");
						cell.accessoryView = addressbookSwitch;
						addressbookSwitch.on = [[dictionary objectForKey:@"shouldIncludeContactsInWhitelist"] boolValue];
						[addressbookSwitch addTarget:self action:@selector(saveSettingsFromSource:) forControlEvents:UIControlEventValueChanged];
						break;
					}
				}
				break;
			}
		case 1: // Call
			{
				cell.accessoryView = nil;
				switch (indexPath.row)
				{
					case 0:
						{
							cell.textLabel.text = NSLocalizedString(@"Whitelist calls only w/ beep", @"Whitelist calls only w/ beep");
							cell.accessoryType = [[dictionary objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
							break;
						}
					case 1:
						{
							cell.textLabel.text = NSLocalizedString(@"Whitelist calls only w/o beep", @"Whitelist calls only w/o beep");
							cell.accessoryType = [[dictionary objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
							break;
						}
					case 2:
						{
							cell.textLabel.text = NSLocalizedString(@"Whitelist msgs only w/ beep", @"Whitelist msgs only w/ beep");
							cell.accessoryType = [[dictionary objectForKey:@"whitelistMessagesOnlyWithBeep"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
							break;
						}
					case 3:
						{
							cell.textLabel.text = NSLocalizedString(@"Whitelist msgs only w/o beep", @"Whitelist msgs only w/o beep");
							cell.accessoryType = [[dictionary objectForKey:@"whitelistMessagesOnlyWithoutBeep"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
							break;
						}
				}
				break;
			}
		case 2: // NoBlockedCallLog
			{
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.text = NSLocalizedString(@"Clear blocked calls", @"Clear blocked calls");
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.accessoryView = clearSwitch;
				clearSwitch.on = [[dictionary objectForKey:@"shouldClearSpam"] boolValue];
				[clearSwitch addTarget:self action:@selector(saveSettingsFromSource:) forControlEvents:UIControlEventValueChanged];

				break;
			}
		case 3:
			{
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.accessoryView = nil;
				switch (indexPath.row)
				{
					case 0:
						{
							cell.textLabel.text = NSLocalizedString(@"Questions & Suggestions", @"Questions & Suggestions");
							break;
						}
					case 1:
						{
							cell.textLabel.text = NSLocalizedString(@"Donate via PayPal. Thank you!", @"Donate via PayPal. Thank you!");
							break;
						}
				}
				break;
			}
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (indexPath.section == 1)
	{
		NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];

		if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
		{
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;

			switch (indexPath.row)
			{
				case 0:
					{
						[dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"whitelistCallsOnlyWithBeep"];
						break;
					}
				case 1:
					{
						[dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"whitelistCallsOnlyWithoutBeep"];
						break;
					}
				case 2:
					{
						[dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"whitelistMessagesOnlyWithBeep"];
						break;
					}
				case 3:
					{
						[dictionary setObject:[NSNumber numberWithBool:NO] forKey:@"whitelistMessagesOnlyWithoutBeep"];
						break;
					}
			}
		}
		else if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryNone)
		{
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

			if (indexPath.row == 0 || indexPath.row == 1)
			{
				[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(1 - indexPath.row) inSection:1]].accessoryType = UITableViewCellAccessoryNone;

				[dictionary setObject:[NSNumber numberWithBool:YES] forKey:indexPath.row == 0 ? @"whitelistCallsOnlyWithBeep" : @"whitelistCallsOnlyWithoutBeep"];
				[dictionary setObject:[NSNumber numberWithBool:NO] forKey:indexPath.row == 1 ? @"whitelistCallsOnlyWithBeep" : @"whitelistCallsOnlyWithoutBeep"];
			}
			else if (indexPath.row == 2 || indexPath.row == 3)
			{
				[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(5 - indexPath.row) inSection:1]].accessoryType = UITableViewCellAccessoryNone;

				[dictionary setObject:[NSNumber numberWithBool:YES] forKey:indexPath.row == 2 ? @"whitelistMessagesOnlyWithBeep" : @"whitelistMessagesOnlyWithoutBeep"];
				[dictionary setObject:[NSNumber numberWithBool:NO] forKey:indexPath.row == 3 ? @"whitelistMessagesOnlyWithBeep" : @"whitelistMessagesOnlyWithoutBeep"];
			}
		}

		[dictionary writeToFile:SETTINGS atomically:YES];
		notify_post("com.naken.smsninja.settingschanged");	
	}
	else if (indexPath.section == 3)
	{
		if (indexPath.row == 0)
		{
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notice", @"Notice") message:NSLocalizedString(@"Please please please read the messages at the top of the webpage. If this is a bug/crash/error report, send me an email with syslog attached!", @"Please please please read the messages at the top of the webpage. If this is a bug/crash/error report, send me an email with syslog attached!") delegate:self cancelButtonTitle:NSLocalizedString(@"Never mind", @"Never mind") otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
			alertView.tag = 4;
			[alertView show];
			[alertView release];
		}
		else
		{
			NSString *url = @"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=X5WXJTUHP7JLJ";
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
		}
	}
}

- (void)saveSettingsFromSource:(UIControl *)control
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (control == statusBarBadgeSwitch && (![fileManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib"] || ![fileManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libstatusbar.plist"]))
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notice", @"Notice") message:NSLocalizedString(@"To enable this feature, you need to install libstatusbar, whose potential bugs are not in my charge.", @"To enable this feature, you need to install libstatusbar, whose potential bugs are not in my charge.") delegate:self cancelButtonTitle:NSLocalizedString(@"Never mind", @"Never mind") otherButtonTitles:NSLocalizedString(@"Go to Cydia", @"Go to Cydia") , nil];
		alertView.tag = 2;
		[alertView show];
		[alertView release];
		statusBarBadgeSwitch.on = NO;
	}
	if (control == hideIconSwitch && (![fileManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libhide.dylib"] || ![fileManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libhide.plist"] || ![fileManager fileExistsAtPath:@"/usr/bin/hidelibconvert"] || ![fileManager fileExistsAtPath:@"/usr/lib/hide.dylib"] || ![fileManager fileExistsAtPath:@"/var/mobile/Library/LibHide"]))
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notice", @"Notice") message:NSLocalizedString(@"To enable this feature, you need to install libhide, whose potential bugs are not in my charge.", @"To enable this feature, you need to install libhide, whose potential bugs are not in my charge.") delegate:self cancelButtonTitle:NSLocalizedString(@"Never mind", @"Never mind") otherButtonTitles:NSLocalizedString(@"Go to Cydia", @"Go to Cydia") , nil];
		alertView.tag = 3;
		[alertView show];
		[alertView release];
		hideIconSwitch.on = NO;
	}

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
	[dictionary setObject:[NSNumber numberWithBool:iconBadgeSwitch.on] forKey:@"shouldShowIconBadge"];
	[dictionary setObject:[NSNumber numberWithBool:statusBarBadgeSwitch.on] forKey:@"shouldShowStatusBarBadge"];
	[dictionary setObject:[NSNumber numberWithBool:hideIconSwitch.on] forKey:@"shouldHideIcon"];
	[dictionary setObject:[NSNumber numberWithBool:clearSwitch.on] forKey:@"shouldClearSpam"];
	[dictionary setObject:[NSNumber numberWithBool:addressbookSwitch.on] forKey:@"shouldIncludeContactsInWhitelist"];
	[dictionary writeToFile:SETTINGS atomically:YES];
	notify_post("com.naken.smsninja.settingschanged");	
}

- (void)resetSettings
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notice", @"Notice") message:NSLocalizedString(@"Are you sure to reset SMSNinja?", @"Are you sure to reset SMSNinja?") delegate:self cancelButtonTitle:NSLocalizedString(@"Forget that!", @"Forget that!") otherButtonTitles:NSLocalizedString(@"Go ahead!", @"Go ahead!") , nil];
	alertView.tag = 1;
	[alertView show];
	[alertView release];
}

static void (^CreateDatabase)(void) = ^(void)
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;

	if (!([fileManager fileExistsAtPath:DOCUMENT isDirectory:&isDir] && isDir)) [fileManager createDirectoryAtPath:DOCUMENT withIntermediateDirectories:YES attributes:nil error:nil];

	if (!([fileManager fileExistsAtPath:PICTURES isDirectory:&isDir] && isDir)) [fileManager createDirectoryAtPath:PICTURES withIntermediateDirectories:YES attributes:nil error:nil];

	if (!([fileManager fileExistsAtPath:PRIVATEPICTURES isDirectory:&isDir] && isDir)) [fileManager createDirectoryAtPath:PRIVATEPICTURES withIntermediateDirectories:YES attributes:nil error:nil];

	if (![fileManager fileExistsAtPath:SETTINGS])
#ifndef SMSNinjaDebug
		[fileManager copyItemAtPath:@"/Applications/SMSNinja.app/smsninja.plist" toPath:SETTINGS error:nil];
#else
	[fileManager copyItemAtPath:@"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/SMSNinjaUI.app/smsninja.plist" toPath:SETTINGS error:nil];
#endif
	if (![fileManager fileExistsAtPath:DATABASE])
#ifndef SMSNinjaDebug
		[fileManager copyItemAtPath:@"/Applications/SMSNinja.app/smsninja.db" toPath:DATABASE error:nil];
#else
	[fileManager copyItemAtPath:@"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/SMSNinjaUI.app/smsninja.db" toPath:DATABASE error:nil];
#endif
	NSString *filePath = [DOCUMENT stringByAppendingString:@"/blocked.caf"];
#ifndef SMSNinjaDebug
	if (![fileManager fileExistsAtPath:filePath]) [fileManager copyItemAtPath:@"/System/Library/Audio/UISounds/sms-received5.caf" toPath:filePath error:nil];
#endif
	filePath = [DOCUMENT stringByAppendingString:@"/private.caf"];
#ifndef SMSNinjaDebug
	if (![fileManager fileExistsAtPath:filePath]) [fileManager copyItemAtPath:@"/System/Library/Audio/UISounds/sms-received3.caf" toPath:filePath error:nil];
#endif
};

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		switch ((int)alertView.tag)
		{
			case 1:
				{
					NSFileManager *fileManager = [NSFileManager defaultManager];
					[fileManager removeItemAtPath:DOCUMENT error:nil];
					CreateDatabase();
					[[UIApplication sharedApplication] terminateWithSuccess];
					break;
				}
			case 2:
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/libstatusbar"]];
					break;
				}
			case 3:
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/libhide"]];
					break;
				}
			case 4:
				{
					[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://ying.lu/smsninja-faq/"]];
					break;
				}
		}
	}
}

- (void)saveTextFieldValues
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
	[dictionary setObject:[passwordField.text length] != 0 ? passwordField.text : @"" forKey:[self.fake boolValue] ? @"fakePassword" : @"startPassword"];
	[dictionary setObject:[[[launchCodeField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] length] != 0 ? [[launchCodeField.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""] : @"" forKey:@"launchCode"];
	[dictionary writeToFile:SETTINGS atomically:YES];
	notify_post("com.naken.smsninja.settingschanged");	
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

- (void)viewDidLoad
{
	[super viewDidLoad];
	if ([self.fake boolValue]) self.navigationItem.rightBarButtonItem = nil;
	[self.view addGestureRecognizer:tapRecognizer];
}

- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap
{
	[passwordField resignFirstResponder];
	[launchCodeField resignFirstResponder];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
	if (gestureRecognizer == tapRecognizer && ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:NSClassFromString(@"UITableViewCellContentView")])) return NO;
	return YES;
}
@end
