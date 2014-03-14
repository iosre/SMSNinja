#import "SNSystemMessageHistoryViewController.h"
#import "SNNumberViewController.h"
#import "SNWhitelistViewController.h"
#import "SNBlacklistViewController.h"
#import "SNPrivatelistViewController.h"
#import <objc/runtime.h>
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

@implementation SNSystemMessageHistoryViewController

@synthesize flag;

- (void)dealloc
{
    [numberArray release];
    numberArray = nil;
    
    [nameArray release];
    nameArray = nil;
    
    [timeArray release];
    timeArray = nil;
    
    [contentArray release];
    contentArray = nil;
    
    [keywordSet release];
    keywordSet = nil;
    
    [flag release];
    flag = nil;
    
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self setEditing:NO animated:NO];
    
    id viewController = self.navigationController.topViewController;
    if ([viewController isKindOfClass:[SNNumberViewController class]]) return;
    [((UITableViewController *)viewController).tableView reloadData];
}

- (void)initializeAllArrays
{
    CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
    NSDictionary *reply = [messagingCenter sendMessageAndReceiveReplyName:@"GetSystemMessageHistory" userInfo:nil];
    numberArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"numberArray"]];
    nameArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"nameArray"]];
    timeArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"timeArray"]];
    contentArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"contentArray"]];
    keywordSet = [[NSMutableSet alloc] initWithCapacity:600];
    
    sqlite3 *database;
    sqlite3_stmt *statement;
    int openResult = sqlite3_open([DATABASE UTF8String], &database);
    if (openResult == SQLITE_OK)
    {
        NSString *sql = [NSString stringWithFormat:@"select keyword from %@list", self.flag];
        int prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (prepareResult == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                char *keyword = (char *)sqlite3_column_text(statement, 0);
                [keywordSet addObject:keyword ? [NSString stringWithUTF8String:keyword] : @""];
            }
            sqlite3_finalize(statement);
        }
        else NSLog(@"SMSNinja: Failed to prepare %@, error %d", sql, prepareResult);
        sqlite3_close(database);
    }
    else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (SNSystemMessageHistoryViewController *)init
{
    if ((self = [super initWithStyle:UITableViewStylePlain]))
    {
        self.title = NSLocalizedString(@"Message History", @"Message History");
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.tableView.allowsSelectionDuringEditing = YES;
        
        [self initializeAllArrays];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [numberArray count];
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
    
    UITableViewCell *defaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default-cell"];
    int defaultCellHeight = defaultCell.bounds.size.height;
    int defaultCellWidth = defaultCell.bounds.size.width;
    [defaultCell release];
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, (defaultCellWidth - 50.0f) / 2.0f, (defaultCellHeight - 4.0f) / 2.0f)];
    nameLabel.tag = 1;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    nameLabel.text = [[nameArray objectAtIndex:indexPath.row] length] != 0 ? [nameArray objectAtIndex:indexPath.row] : [numberArray objectAtIndex:indexPath.row];
    [cell.contentView addSubview:nameLabel];
    [nameLabel release];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + nameLabel.bounds.size.width, nameLabel.frame.origin.y, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
    timeLabel.tag = 2;
    timeLabel.font = nameLabel.font;
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) timeLabel.textAlignment = UITextAlignmentRight;
    else timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth;
    timeLabel.text = [timeArray objectAtIndex:indexPath.row];
    timeLabel.textColor = nameLabel.textColor;
    [cell.contentView addSubview:timeLabel];
    [timeLabel release];
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.bounds.size.height, nameLabel.bounds.size.width + timeLabel.bounds.size.width, nameLabel.bounds.size.height)];
    contentLabel.tag = 3;
    contentLabel.numberOfLines = 0;
    contentLabel.font = nameLabel.font;
    contentLabel.text = [contentArray objectAtIndex:indexPath.row];
    CGSize expectedLabelSize = [contentLabel.text sizeWithFont:contentLabel.font constrainedToSize:CGSizeMake(contentLabel.bounds.size.width, contentLabel.bounds.size.height * 60.0f) lineBreakMode:contentLabel.lineBreakMode];
    CGRect newFrame = contentLabel.frame;
    newFrame.size.height = expectedLabelSize.height;
    contentLabel.frame = newFrame;
    contentLabel.textColor = nameLabel.textColor;
    [cell.contentView addSubview:contentLabel];
    [contentLabel release];
    
    if ([keywordSet containsObject:[numberArray objectAtIndex:indexPath.row]]) [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    else [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default-cell"] autorelease];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    UIFont *font = label.font;
    [label release];
    return (cell.contentView.bounds.size.height - 4.0f) / 2.0f + [[contentArray objectAtIndex:indexPath.row] sizeWithFont:font constrainedToSize:CGSizeMake((cell.contentView.bounds.size.width - 50.0f), (cell.contentView.bounds.size.height - 4.0f) / 2.0f * 60.0f) lineBreakMode:NSLineBreakByWordWrapping].height + 4.0f;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1) // single
    {
        if (buttonIndex == 2) [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:buttonIndex inSection:0] animated:NO];
        
        __block NSInteger index = buttonIndex;
        __block SNSystemMessageHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sqlite3 *database;
            int openResult = sqlite3_open([DATABASE UTF8String], &database);
            if (openResult == SQLITE_OK)
            {
                NSString *sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '%d')", weakSelf.flag, [weakSelf->numberArray objectAtIndex:weakSelf->chosenRow], index];
                int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                sqlite3_close(database);
                
                id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                {
                    [((SNBlacklistViewController *)viewController)->keywordArray addObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow]];
                    [((SNBlacklistViewController *)viewController)->typeArray addObject:@"0"];
                    [((SNBlacklistViewController *)viewController)->nameArray addObject:@""];
                    [((SNBlacklistViewController *)viewController)->messageArray addObject:@"1"];
                    [((SNBlacklistViewController *)viewController)->numberArray addObject:@"1"];
                    [((SNBlacklistViewController *)viewController)->smsArray addObject:@"0"];
                    [((SNBlacklistViewController *)viewController)->phoneArray addObject:@""];
                    [((SNBlacklistViewController *)viewController)->forwardArray addObject:@"0"];
                    [((SNBlacklistViewController *)viewController)->replyArray addObject:@""];
                    [((SNBlacklistViewController *)viewController)->soundArray addObject:[NSString stringWithFormat:@"%d", index]];
                }
                else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                {
                    [((SNPrivatelistViewController *)viewController)->keywordArray addObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow]];
                    [((SNPrivatelistViewController *)viewController)->typeArray addObject:@"0"];
                    [((SNPrivatelistViewController *)viewController)->nameArray addObject:@""];
                    [((SNPrivatelistViewController *)viewController)->messageArray addObject:@"1"];
                    [((SNPrivatelistViewController *)viewController)->numberArray addObject:@"1"];
                    [((SNPrivatelistViewController *)viewController)->smsArray addObject:@"0"];
                    [((SNPrivatelistViewController *)viewController)->phoneArray addObject:@""];
                    [((SNPrivatelistViewController *)viewController)->forwardArray addObject:@"0"];
                    [((SNPrivatelistViewController *)viewController)->replyArray addObject:@""];
                    [((SNPrivatelistViewController *)viewController)->soundArray addObject:[NSString stringWithFormat:@"%d", index]];
                }
            }
            else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
        });
    }
    else if (actionSheet.tag == 2) // all
    {
        if (buttonIndex == 2)
            for (int i = 0; i < [numberArray count]; i++)
                [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
        
        __block NSInteger index = buttonIndex;
        __block SNSystemMessageHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sqlite3 *database;
            int openResult = sqlite3_open([DATABASE UTF8String], &database);
            if (openResult == SQLITE_OK)
            {
                for (NSString *number in weakSelf->numberArray)
                {
                    NSString *sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '%d')", weakSelf.flag, number, index];
                    int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                    if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                    
                    id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                    if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                    {
                        [((SNBlacklistViewController *)viewController)->keywordArray addObject:number];
                        [((SNBlacklistViewController *)viewController)->typeArray addObject:@"0"];
                        [((SNBlacklistViewController *)viewController)->nameArray addObject:@""];
                        [((SNBlacklistViewController *)viewController)->messageArray addObject:@"1"];
                        [((SNBlacklistViewController *)viewController)->numberArray addObject:@"1"];
                        [((SNBlacklistViewController *)viewController)->smsArray addObject:@"0"];
                        [((SNBlacklistViewController *)viewController)->phoneArray addObject:@""];
                        [((SNBlacklistViewController *)viewController)->forwardArray addObject:@"0"];
                        [((SNBlacklistViewController *)viewController)->replyArray addObject:@""];
                        [((SNBlacklistViewController *)viewController)->soundArray addObject:[NSString stringWithFormat:@"%d", index]];
                    }
                    else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                    {
                        [((SNPrivatelistViewController *)viewController)->keywordArray addObject:number];
                        [((SNPrivatelistViewController *)viewController)->typeArray addObject:@"0"];
                        [((SNPrivatelistViewController *)viewController)->nameArray addObject:@""];
                        [((SNPrivatelistViewController *)viewController)->messageArray addObject:@"1"];
                        [((SNPrivatelistViewController *)viewController)->numberArray addObject:@"1"];
                        [((SNPrivatelistViewController *)viewController)->smsArray addObject:@"0"];
                        [((SNPrivatelistViewController *)viewController)->phoneArray addObject:@""];
                        [((SNPrivatelistViewController *)viewController)->forwardArray addObject:@"0"];
                        [((SNPrivatelistViewController *)viewController)->replyArray addObject:@""];
                        [((SNPrivatelistViewController *)viewController)->soundArray addObject:[NSString stringWithFormat:@"%d", index]];
                    }
                }
                sqlite3_close(database);
            }
            else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
        });
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.editing)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
        numberViewController.flag = self.flag;
        numberViewController.nameString = [nameArray objectAtIndex:indexPath.row];
        numberViewController.keywordString = [numberArray objectAtIndex:indexPath.row];
        numberViewController.originalKeyword = numberViewController.keywordString;
        numberViewController.phoneAction = @"1";
        numberViewController.messageAction = @"1";
        numberViewController.replyString = @"0";
        numberViewController.messageString = @"";
        numberViewController.forwardString = @"0";
        numberViewController.numberString = @"";
        numberViewController.soundString = @"1";
        UINavigationController *navigationController = self.navigationController;
        [navigationController popViewControllerAnimated:NO];
        [navigationController pushViewController:numberViewController animated:YES];
        [numberViewController release];
    }
    else
    {
        chosenRow = indexPath.row;
        if (![self.flag isEqualToString:@"white"])
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Turn off the beep", @"Turn off the beep"), NSLocalizedString(@"Turn on the beep", @"Turn on the beep"), nil];
            actionSheet.tag = 1;
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            [actionSheet release];
        }
        else
        {
            __block SNSystemMessageHistoryViewController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sqlite3 *database;
                int openResult = sqlite3_open([DATABASE UTF8String], &database);
                if (openResult == SQLITE_OK)
                {
                    NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '0')", [weakSelf->numberArray objectAtIndex:weakSelf->chosenRow]];
                    int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                    if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                    sqlite3_close(database);
                    
                    SNWhitelistViewController *viewController = (SNWhitelistViewController *)[weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                    [viewController->nameArray addObject:@""];
                    [viewController->keywordArray addObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow]];
                    [viewController->typeArray addObject:@"0"];
                }
                else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
            });
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block int index = indexPath.row;
    __block SNSystemMessageHistoryViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sqlite3 *database;
        int openResult = sqlite3_open([DATABASE UTF8String], &database);
        if (openResult == SQLITE_OK)
        {
            NSString *sql = [NSString stringWithFormat:@"delete from %@list where keyword = '%@'", weakSelf.flag, [weakSelf->numberArray objectAtIndex:index]];
            int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
            if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
            sqlite3_close(database);
            
            id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
            if ([viewController isKindOfClass:[SNBlacklistViewController class]])
            {
                [((SNBlacklistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->nameArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->messageArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->numberArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->smsArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->phoneArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->forwardArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->replyArray removeObjectAtIndex:index];
                [((SNBlacklistViewController *)viewController)->soundArray removeObjectAtIndex:index];
            }
            else if ([viewController isKindOfClass:[SNWhitelistViewController class]])
            {
                [((SNWhitelistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                [((SNWhitelistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                [((SNWhitelistViewController *)viewController)->nameArray removeObjectAtIndex:index];
            }
            else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
            {
                [((SNPrivatelistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->nameArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->messageArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->numberArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->smsArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->phoneArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->forwardArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->replyArray removeObjectAtIndex:index];
                [((SNPrivatelistViewController *)viewController)->soundArray removeObjectAtIndex:index];
            }
        }
        else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
    });
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete;
}

- (void)selectAll:(UIBarButtonItem *)buttonItem
{
    if ([buttonItem.title isEqualToString:NSLocalizedString(@"All", @"All")])
    {
        buttonItem.title = NSLocalizedString(@"None", @"None");
        for (int i = 0; i < [numberArray count]; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        
        if (![self.flag isEqualToString:@"white"])
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Turn off the beep", @"Turn off the beep"), NSLocalizedString(@"Turn on the beep", @"Turn on the beep"), nil];
            actionSheet.tag = 2;
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            [actionSheet release];
        }
        else
        {
            __block SNSystemMessageHistoryViewController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sqlite3 *database;
                int openResult = sqlite3_open([DATABASE UTF8String], &database);
                if (openResult == SQLITE_OK)
                {
                    for (NSString *number in weakSelf->numberArray)
                    {
                        NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '0')", number];
                        int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                        if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                        
                        SNWhitelistViewController *viewController = (SNWhitelistViewController *)[weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                        [viewController->nameArray addObject:@""];
                        [viewController->keywordArray addObject:number];
                        [viewController->typeArray addObject:@"0"];
                    }
                    sqlite3_close(database);
                }
                else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
            });
        }
    }
    else if ([buttonItem.title isEqualToString:NSLocalizedString(@"None", @"None")])
    {
        buttonItem.title = NSLocalizedString(@"All", @"All");
        for (int i = 0; i < [numberArray count]; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
        __block SNSystemMessageHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sqlite3 *database;
            int openResult = sqlite3_open([DATABASE UTF8String], &database);
            if (openResult == SQLITE_OK)
            {
                for (NSString *number in weakSelf->numberArray)
                {
                    NSString *sql = [NSString stringWithFormat:@"delete from %@list where keyword = '%@'", weakSelf.flag, number];
                    int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                    if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                    
                    id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                    if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                    {
                        [((SNBlacklistViewController *)viewController)->keywordArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->typeArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->nameArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->messageArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->numberArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->smsArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->phoneArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->forwardArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->replyArray removeObject:number];
                        [((SNBlacklistViewController *)viewController)->soundArray removeObject:number];
                    }
                    else if ([viewController isKindOfClass:[SNWhitelistViewController class]])
                    {
                        [((SNWhitelistViewController *)viewController)->keywordArray removeObject:number];
                        [((SNWhitelistViewController *)viewController)->typeArray removeObject:number];
                        [((SNWhitelistViewController *)viewController)->nameArray removeObject:number];
                    }
                    else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                    {
                        [((SNPrivatelistViewController *)viewController)->keywordArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->typeArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->nameArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->messageArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->numberArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->smsArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->phoneArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->forwardArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->replyArray removeObject:number];
                        [((SNPrivatelistViewController *)viewController)->soundArray removeObject:number];
                    }
                }
                sqlite3_close(database);
            }
            else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
        });
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    [self.navigationController setToolbarHidden:!editing animated:animate];
    if (editing)
    {
        for (UITableViewCell *cell in [self.tableView visibleCells])
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"All", @"All") style:UIBarButtonItemStylePlain target:self action:@selector(selectAll:)] autorelease] animated:animate];
    }
    else
    {
        for (UITableViewCell *cell in [self.tableView visibleCells])
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [self.navigationItem setLeftBarButtonItem:nil animated:animate];
    }
    [super setEditing:editing animated:animate];
}
@end
