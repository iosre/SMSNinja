#import "SNCallActionViewController.h"
#import "SNTimeViewController.h"
#import <objc/runtime.h>

@implementation SNCallActionViewController

@synthesize phoneAction;
@synthesize flag;

- (void)dealloc
{
	[phoneAction release];
	phoneAction = nil;

	[flag release];
	flag = nil;

	[super dealloc];
}

- (SNCallActionViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title= NSLocalizedString(@"Call", @"Call");
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if ([self.flag isEqualToString:@"private"])
		return 3;
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
	for (UIView *subview in [cell.contentView subviews])
		[subview removeFromSuperview];
	cell.textLabel.text = nil;
	cell.accessoryView = nil;
	cell.accessoryType = UITableViewCellAccessoryNone;

	switch (indexPath.row)
	{
		case 0:
			cell.textLabel.text = NSLocalizedString(@"Disconnect", @"Disconnect");
			if ([self.phoneAction isEqualToString:@"1"]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else cell.accessoryType = UITableViewCellAccessoryNone;
			break;
		case 1:
			cell.textLabel.text = NSLocalizedString(@"Ignore", @"Ignore");
			if ([self.phoneAction isEqualToString:@"2"]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else cell.accessoryType = UITableViewCellAccessoryNone;
			break;
		case 2:
			cell.textLabel.text = NSLocalizedString(@"Let go", @"Let go");
			if ([self.phoneAction isEqualToString:@"3"]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else cell.accessoryType = UITableViewCellAccessoryNone;
			break;
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
	{
		[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;

		self.phoneAction = nil;
		self.phoneAction = @"0";
	}
	else if ([self.flag isEqualToString:@"black"] && [tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryNone)
	{
		[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
		[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:(1 - indexPath.row) inSection:0]].accessoryType = UITableViewCellAccessoryNone;

		self.phoneAction = nil;
		self.phoneAction = [NSString stringWithFormat:@"%ld", (long)(indexPath.row + 1)];
	}
	else if ([self.flag isEqualToString:@"private"] && [tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryNone)
	{
		[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
		for (int i = 0; i < 3; i++)
		{
			if (i != indexPath.row)
				[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].accessoryType = UITableViewCellAccessoryNone;
		}

		self.phoneAction = nil;
		self.phoneAction = [NSString stringWithFormat:@"%ld", (long)(indexPath.row + 1)];
	}

	id viewController = [self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] - 2)];
	[viewController setPhoneAction:self.phoneAction];
	if ([viewController isKindOfClass:[SNTimeViewController class]]) [((SNTimeViewController *)viewController)->settingsTableView reloadData];
	else [((UITableViewController *)viewController).tableView reloadData];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return NSLocalizedString(@"Uncheck to disable", @"Uncheck to disable");
}
@end
