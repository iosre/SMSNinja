#import "SNMainViewController.h"
#import "SNBlockedMessageHistoryViewController.h"
#import "SNBlacklistViewController.h"
#import "SNSettingsViewController.h"
#import "SNReadMeViewController.h"
#import "SNPrivateViewController.h"
#import <objc/runtime.h>
#import <sqlite3.h>
#import <notify.h>

#ifndef SMSNinjaDebug
#define DOCUMENT @"/var/mobile/Library/SMSNinja"
#else
#define DOCUMENT @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja"
#endif

#define SETTINGS [DOCUMENT stringByAppendingString:@"/smsninja.plist"]
#define DATABASE [DOCUMENT stringByAppendingString:@"/smsninja.db"]
#define PICTURES [DOCUMENT stringByAppendingString:@"/Pictures/"]
#define PRIVATEPICTURES [DOCUMENT stringByAppendingString:@"/PrivatePictures/"]

@implementation SNMainViewController

@synthesize fake;

- (void)dealloc
{
	[fake release];
	fake = nil;

	[appSwitch release];
	appSwitch = nil;

	[super dealloc];
}

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title = NSLocalizedString(@"SMSNinja", @"SMSNinja");
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"Settings") style:UIBarButtonItemStylePlain target:self action:@selector(gotoSettingsView)] autorelease];
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Readme", @"Readme") style:UIBarButtonItemStylePlain target:self action:@selector(gotoReadMeView)] autorelease];

		appSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self updateDatabase];

	CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
	UIView *view = self.tableView;
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.backgroundColor = [UIColor clearColor];
	label.text = NSLocalizedString(@"by snakeninny", @"by snakeninny");
	label.alpha = 0.6f;
	CGSize size = [label.text sizeWithFont:label.font];
	label.frame = CGRectMake((appFrame.size.width - size.width) / 2.0f, view.bounds.size.height - size.height - 12.0f, size.width, size.height);
	[view addSubview:label];
	[label release];
}

static void (^CreateDatabase)(void) = ^(void)
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDir;

	if (!([fileManager fileExistsAtPath:DOCUMENT isDirectory:&isDir] && isDir))
		[fileManager createDirectoryAtPath:DOCUMENT withIntermediateDirectories:YES attributes:nil error:nil];

	if (!([fileManager fileExistsAtPath:PICTURES isDirectory:&isDir] && isDir))
		[fileManager createDirectoryAtPath:PICTURES withIntermediateDirectories:YES attributes:nil error:nil];

	if (!([fileManager fileExistsAtPath:PRIVATEPICTURES isDirectory:&isDir] && isDir))
		[fileManager createDirectoryAtPath:PRIVATEPICTURES withIntermediateDirectories:YES attributes:nil error:nil];

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
	if (![fileManager fileExistsAtPath:filePath])
		[fileManager copyItemAtPath:@"/System/Library/Audio/UISounds/sms-received5.caf" toPath:filePath error:nil];
#endif
	filePath = [DOCUMENT stringByAppendingString:@"/private.caf"];
#ifndef SMSNinjaDebug
	if (![fileManager fileExistsAtPath:filePath])
		[fileManager copyItemAtPath:@"/System/Library/Audio/UISounds/sms-received3.caf" toPath:filePath error:nil];
#endif
};

- (void)updateDatabase
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS] && [[NSDictionary dictionaryWithContentsOfFile:SETTINGS] count] != 16)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Notice", @"Notice") message:NSLocalizedString(@"It seems that you have installed SMSNinja before. To activate version 1.5, SMSNinja have to convert settings files to the latest suitable format. Settings files are stored in \"/var/mobile/Library/SMSNinja\", it's highly recommended that you make a backup of the files first. Are you sure to convert now?", @"It seems that you have installed SMSNinja before. To activate version 1.5, SMSNinja have to convert settings files to the latest suitable format. Settings files are stored in \"/var/mobile/Library/SMSNinja\", it's highly recommended that you make a backup of the files first. Are you sure to convert now?") delegate:self cancelButtonTitle:NSLocalizedString(@"Yes", @"Yes") otherButtonTitles:NSLocalizedString(@"One second!", @"One second!"), nil];
		[alertView show];
		[alertView release];
	}
	else dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), CreateDatabase);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		[fileManager removeItemAtPath:SETTINGS error:nil];
#ifndef SMSNinjaDebug
		[fileManager copyItemAtPath:@"/Applications/SMSNinja.app/smsninja.plist" toPath:SETTINGS error:nil];
#else
		[fileManager copyItemAtPath:@"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/SMSNinjaUI.app/smsninja.plist" toPath:SETTINGS error:nil];
#endif
		[self.tableView reloadData];
	}
}

- (void)gotoSettingsView
{
	SNSettingsViewController *settingsViewControllerClass = [[SNSettingsViewController alloc] init];
	settingsViewControllerClass.fake = self.fake;
	[self.navigationController pushViewController:settingsViewControllerClass animated:YES];
	[settingsViewControllerClass release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ([self.fake boolValue]) return 2;
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1) return 2;
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
	for (UIView *subview in [cell.contentView subviews])
		[subview removeFromSuperview];
	cell.textLabel.text = nil;
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;

	switch (indexPath.section)
	{
		case 0:
			{
				cell.textLabel.text = NSLocalizedString(@"SMSNinja", @"SMSNinja");
				cell.selectionStyle = UITableViewCellSelectionStyleNone;

				cell.accessoryView = appSwitch;
				NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
				appSwitch.on = [dictionary[@"appIsOn"] boolValue];
				[appSwitch addTarget:self action:@selector(saveSettings) forControlEvents:UIControlEventValueChanged];
				break;
			}
		case 1:
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				switch (indexPath.row)
				{
					case 0:
						cell.textLabel.text = NSLocalizedString(@"Blocked Info", @"Blocked Info");
						break;
					case 1:
						cell.textLabel.text = NSLocalizedString(@"Black & Whitelist", @"Black & Whitelist");
						break;
				}
				break;
			}
		case 2:
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.textLabel.text = NSLocalizedString(@"Private Zone", @"Private Zone");
				break;
			}
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
	{
		switch (indexPath.row)
		{
			case 0:
				{
					SNBlockedMessageHistoryViewController *blockedMessageHistoryViewController = [[SNBlockedMessageHistoryViewController alloc] init];
					[self.navigationController pushViewController:blockedMessageHistoryViewController animated:YES];
					[blockedMessageHistoryViewController release];
					break;
				}
			case 1:
				{
					SNBlacklistViewController *blacklistViewController = [[SNBlacklistViewController alloc] init];
					[self.navigationController pushViewController:blacklistViewController animated:YES];
					[blacklistViewController release];
					break;
				}
		}
	}
	else if (indexPath.section == 2)
	{
		SNPrivateViewController *privateViewController = [[SNPrivateViewController alloc] init];
		[self.navigationController pushViewController:privateViewController animated:YES];
		[privateViewController release];
	}
}

- (void)saveSettings
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
	dictionary[@"appIsOn"] = @(appSwitch.on);
	[dictionary writeToFile:SETTINGS atomically:YES];

	notify_post("com.naken.smsninja.settingschanged");	
}

- (void)gotoReadMeView
{
	SNReadMeViewController *readMeViewController = [[SNReadMeViewController alloc] init];
	readMeViewController.fake = self.fake;
	[self.navigationController pushViewController:readMeViewController animated:YES];
	[readMeViewController release];
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
	NSMutableArray *labelArray = [NSMutableArray arrayWithCapacity:5];
	for (UIView *view in alertView.subviews)
		if ([view isKindOfClass:[UILabel class]])
			[labelArray addObject:view];

	for (UILabel *label in labelArray)
		if ([[label text] length] > 20)
			label.textAlignment = NSTextAlignmentLeft;
}
@end
