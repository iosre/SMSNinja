#import "libsmsninja.h"

NSDictionary *settings;
NSMutableArray *blackKeywordArray;
NSMutableArray *blackTypeArray;
NSMutableArray *blackNameArray;
NSMutableArray *blackPhoneArray;
NSMutableArray *blackSmsArray;
NSMutableArray *blackReplyArray;
NSMutableArray *blackMessageArray;
NSMutableArray *blackForwardArray;
NSMutableArray *blackNumberArray;
NSMutableArray *blackSoundArray;

NSMutableArray *whiteKeywordArray;
NSMutableArray *whiteTypeArray;
NSMutableArray *whiteNameArray;
NSMutableArray *whitePhoneArray;
NSMutableArray *whiteSmsArray;
NSMutableArray *whiteReplyArray;
NSMutableArray *whiteMessageArray;
NSMutableArray *whiteForwardArray;
NSMutableArray *whiteNumberArray;
NSMutableArray *whiteSoundArray;

NSMutableArray *privateKeywordArray;
NSMutableArray *privateTypeArray;
NSMutableArray *privateNameArray;
NSMutableArray *privatePhoneArray;
NSMutableArray *privateSmsArray;
NSMutableArray *privateReplyArray;
NSMutableArray *privateMessageArray;
NSMutableArray *privateForwardArray;
NSMutableArray *privateNumberArray;
NSMutableArray *privateSoundArray;

@interface SNActionSheetDelegate : NSObject <UIActionSheetDelegate>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

static UIActionSheet *snActionSheet;
static SNActionSheetDelegate *snActionSheetDelegate;

static NSString *chosenName;
static NSString *chosenKeyword;

@implementation SNActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != snActionSheet.cancelButtonIndex)
	{
		__block NSString *flag = nil;
		if ([[snActionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedStringFromTableInBundle(@"Add to Blacklist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)]) flag = @"black";
		else if ([[snActionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedStringFromTableInBundle(@"Add to Whitelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)]) flag = @"white";
		else if ([[snActionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)]) flag = @"private";

		dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			sqlite3 *database;
			int openResult = sqlite3_open([DATABASE UTF8String], &database);
			if (openResult == SQLITE_OK)
			{
				for (NSString *keyword in [chosenKeyword componentsSeparatedByString:@"  "])
				{
					chosenName = [chosenName stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
					NSString *sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '1', '1', '0', '', '0', '', '1')", flag, keyword, chosenName];
					int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
					if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec \"%@\", error %d", sql, execResult);
				}
				sqlite3_close(database);
				notify_post([[NSString stringWithFormat:@"com.naken.smsninja.%@listchanged", flag] UTF8String]);
			}
			else NSLog(@"SMSNinja: Failed to open \"%@\", error %d", DATABASE, openResult);
		});
	}
	snActionSheet.delegate = nil;
	[snActionSheetDelegate release];
	snActionSheetDelegate = nil;
	[snActionSheet release];
	snActionSheet = nil;

	[chosenName release];
	chosenName = nil;

	[chosenKeyword release];
	chosenKeyword = nil;
}
@end

%hook SMSApplication
%new
- (NSDictionary *)snHandleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo
{
	if ([name isEqualToString:@"RefreshConversation"]) [[%c(CKConversationList) sharedConversationList] reloadConversations];
	else if ([name isEqualToString:@"ClearDeletedChat"])
	{
		IMChat *chat = [[%c(IMChatRegistry) sharedInstance] existingChatWithChatIdentifier:(NSString *)userInfo[@"chatID"]];
		if (chat)
		{
			[chat leave];
			CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
			CKConversation *conversation = [conversationList conversationForExistingChat:chat];
			if (conversation) [conversationList deleteConversation:conversation];
		}
	}
	return nil;
}

- (void)dealloc
{
	CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.naken.smsninja.mobilesms"];
	[messagingCenter stopServer];
	%orig;
}

- (BOOL)application:(id)application didFinishLaunchingWithOptions:(id)options
{
	BOOL result = %orig;
	CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.naken.smsninja.mobilesms"];
	[messagingCenter runServerOnCurrentThread];
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) [messagingCenter registerForMessageName:@"RefreshConversation" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) [messagingCenter registerForMessageName:@"ClearDeletedChat" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	return result;
}
%end

%hook CKConversationListController
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [settings[@"appIsOn"] boolValue])
	{
		CKConversationListCell *cell = (CKConversationListCell *)gesture.view;
		NSUInteger chosenRow = [(UITableView *)MSHookIvar<UITableView *>(self, "_table") indexPathForCell:((UITableViewCell *)cell)].row;
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
		{
			CKConversationList *list = self.conversationList;
			CKAggregateConversation *conversation = [list activeConversations][chosenRow];
			NSArray *recipients = [conversation recipients];
			NSString *tempString = @"";
			for (CKEntity *recipient in recipients) tempString = [[tempString stringByAppendingString:[[recipient rawAddress] normalizedPhoneNumber]] stringByAppendingString:@"  "];

			[chosenName release];
			chosenName = nil;
			chosenName = [[NSString alloc] initWithString:[conversation name]];

			[chosenKeyword release];
			chosenKeyword = nil;
			chosenKeyword = [tempString length] != 0 ? [[NSString alloc] initWithString:[tempString substringToIndex:([tempString length] - 2)]] : [[NSString alloc] initWithString:@""];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
		{
			CKConversationList *list = self.conversationList;
			CKConversation *conversation = [list activeConversations][chosenRow];
			NSArray *recipients = [conversation recipientStrings];
			NSString *tempString = @"";			
			for (NSString *recipient in recipients) tempString = [[tempString stringByAppendingString:[recipient normalizedPhoneNumber]] stringByAppendingString:@"  "];

			[chosenName release];
			chosenName = nil;
			chosenName = [[NSString alloc] initWithString:[conversation name]];

			[chosenKeyword release];
			chosenKeyword = nil;
			chosenKeyword = [tempString length] != 0 ? [[NSString alloc] initWithString:[tempString substringToIndex:([tempString length] - 2)]] : [[NSString alloc] initWithString:@""];
		}

		NSLog(@"SMSNinja: CKConversationListController | snLongPress: | chosenName = \"%@\", chosenKeyword = \"%@\"", chosenName, chosenKeyword);

		[snActionSheetDelegate release];
		snActionSheetDelegate = nil;
		snActionSheetDelegate = [[SNActionSheetDelegate alloc] init];
		snActionSheet.delegate = nil;
		[snActionSheet release];
		snActionSheet = nil;
		snActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:snActionSheetDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		if ([chosenKeyword indexInBlackListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Blacklist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInWhiteListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Whitelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [settings[@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		[snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		snActionSheet.cancelButtonIndex = snActionSheet.numberOfButtons - 1;
		if (snActionSheet.numberOfButtons > 1) [snActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		else
		{
			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
				duration:0.6f
				options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
				animations:^{
					[((UITableViewCell *)gesture.view).contentView.layer performSelector:@selector(removeAllAnimations) withObject:nil afterDelay:1.8f];
					((UITableViewCell *)gesture.view).contentView.layer.opacity = 0.0f;
				}
				completion:^(BOOL finished){
		   			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
			   		duration:0.6f
			 		options:UIViewAnimationOptionTransitionNone
					animations:^{
						((UITableViewCell *)gesture.view).contentView.layer.opacity = 1.0f;
					}
					completion:NULL
					];
				}];
		}
	}
}

- (UITableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2
{
	UITableViewCell *result = %orig;
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(snLongPress:)];
	[result addGestureRecognizer:longPressGesture];
	[longPressGesture release];
	return result;
}
%end

%hook SpringBoard
%new
- (NSDictionary *)snHandleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo
{
	if ([name isEqualToString:@"UpdateBadge"]) UpdateBadge();
	else if ([name isEqualToString:@"ShowPurpleSquare"]) ShowPurpleSquare();
	else if ([name isEqualToString:@"HidePurpleSquare"]) HidePurpleSquare();
	else if ([name isEqualToString:@"ShowIcon"]) ShowIcon();
	else if ([name isEqualToString:@"HideIcon"]) HideIcon();
	else if ([name isEqualToString:@"PlayFilterSound"]) PlayFilterSound();
	else if ([name isEqualToString:@"PlayBlockSound"]) PlayBlockSound();
	else if ([name isEqualToString:@"CheckAddressBook"])
	{
		NSString *address = userInfo[@"address"];
		NSNumber *result = [NSNumber numberWithBool:[address isInAddressBook]];
		return @{@"result" : result};
	}
	else if ([name isEqualToString:@"GetAddressBookName"])
	{
		NSString *address = userInfo[@"address"];
		NSString *result = [address nameInAddressBook];
		return @{@"result" : result};
	}
	else if ([name isEqualToString:@"SendMessage"])
	{
		NSString *text = userInfo[@"text"];
		NSString *address = userInfo[@"address"];
		[[SNTelephonyManager sharedManager] sendMessageWithText:text address:address];
	}
	else if ([name isEqualToString:@"LaunchMobilePhone"])
	{
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
		{
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.apple.mobilephone"];
			[[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
		{
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.mobilephone" suspended:NO];
		}
	}
	else if ([name isEqualToString:@"LaunchMobileSMS"])
	{
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
		{
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.apple.MobileSMS"];
			[[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
		{
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.apple.MobileSMS" suspended:NO];
		}
	}
	else if ([name isEqualToString:@"LaunchSMSNinja"])
	{
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
		{
			SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.naken.smsninja"];
			[[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
		{
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:@"com.naken.smsninja" suspended:NO];
		}
	}
	else if ([name isEqualToString:@"ClearDeletedChat"])
	{
		IMChat *chat = [[%c(IMChatRegistry) sharedInstance] existingChatWithChatIdentifier:(NSString *)userInfo[@"chatID"]];
		if (chat)
		{
			[chat leave];
			CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
			CKConversation *conversation = [conversationList conversationForExistingChat:chat];
			if (conversation) [conversationList deleteConversation:conversation];
		}
	}
	else if ([name isEqualToString:@"RemoveIconFromSwitcher"])
	{
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) [[%c(SBAppSwitcherController) sharedInstance] _removeApplicationFromRecents:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.naken.smsninja"]];
		else if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_0) [[%c(SBAppSwitcherModel) sharedInstance] remove:@"com.naken.smsninja"];
		else [[%c(SBAppSwitcherModel) sharedInstance] removeDisplayItem:[%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:@"com.naken.smsninja"]];
	}
	return nil;

	NSLog(@"SMSNinja: Come to http://bbs.iosre.com for more c00l shit :) ");
}

%new
- (void)snHandleNSNotification:(NSNotification *)notification
{
	notify_post("com.naken.smsninja.willlock");
}

- (void)applicationDidFinishLaunching:(id)application
{
	%orig;

	CPDistributedMessagingCenter *messagingCenter = [%c(CPDistributedMessagingCenter) centerNamed:@"com.naken.smsninja.springboard"];
	[messagingCenter runServerOnCurrentThread];
	[messagingCenter registerForMessageName:@"UpdateBadge" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"ShowPurpleSquare" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"HidePurpleSquare" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"ShowIcon" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"HideIcon" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"PlayFilterSound" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"PlayBlockSound" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"CheckAddressBook" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"GetAddressBookName" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"SendMessage" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"LaunchMobilePhone" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"LaunchMobileSMS" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"LaunchSMSNinja" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"ClearDeletedChat" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	[messagingCenter registerForMessageName:@"RemoveIconFromSwitcher" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];

	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(snHandleNSNotification:) name:@"SBAwayViewDimmedNotification" object:nil];

	NSFileManager *fileManager = [NSFileManager defaultManager];
	UpdateBadge();
	if ([fileManager fileExistsAtPath:@"/var/mobile/Library/SMSNinja/UnreadPrivateInfo"] && [settings[@"appIsOn"] boolValue] && [settings[@"shouldShowPurpleSquare"] boolValue]) ShowPurpleSquare();
}
%end

%hook CTCallCenter
- (void)handleNotificationFromConnection:(void *)arg1 ofType:(id)arg2 withInfo:(NSDictionary *)arg3 // outgoing call, 3 for outgoing, 4 for incoming, 5 for disconnect
{
	%orig;
	if ([(NSNumber *)arg3[@"kCTCallStatus"] intValue] == 3 && ((kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1 && [[[NSProcessInfo processInfo] processName] isEqualToString:@"MobilePhone"]) || (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1 && [[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])))
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1 && [[arg3 description] rangeOfString:@"status = 196608"].location != NSNotFound) return; // this is dirty on iOS 7 :(

		CTCallRef call = (CTCallRef)arg3[@"kCTCall"];
		NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
		NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		NSArray *addressArray = @[tempAddress];	
		[address release];

		NSLog(@"SMSNinja: CTCallCenter | handleNotificationFromConnection:ofType:withInfo: | addressArray = \"%@\"", addressArray);

		switch (ActionOfAudioFunctionWithInfo(addressArray, YES))
		{
			default:
				// take a rest!
				break;
		}
	}
}
%end

%hook IMChatRegistry
- (void)account:(id)account chat:(NSString *)chatID style:(unsigned char)style chatProperties:(id)properties messageSent:(id)message // outgoing iMessage_5/messages_6_7_8, called in SpringBoard & MobileSMS
{
	%orig;
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) message = (FZMessage *)message;
	else message = (IMMessageItem *)message;
	
	if (![message isFinished]) return;
	NSArray *transferGUIDArray = [message fileTransferGUIDs];
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [transferGUIDArray count] == 0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) // handles text only messages on iOS 5 ~ 7
	{
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
		IMChat *chat = [self existingChatWithChatIdentifier:chatID];
		if (chat)
		{
			NSArray *handleArray = chat.participants;
			for (IMHandle *handle in handleArray)
			{
				NSString *address = handle.displayID;
				address = [address stringByReplacingOccurrencesOfString:@"\u202a" withString:@""];
				address = [address stringByReplacingOccurrencesOfString:@"\u202c" withString:@""];
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}
		}
		else [addressArray addObject:[message sender]];

		NSString *text = [[message body] string];
		text = [text length] == 0 ? @" " : text;

		NSMutableArray *pictureArray = [NSMutableArray array];

		NSLog(@"SMSNinja: IMChatRegistry | account:chat:style:chatProperties:messageSent: | addressArray = \"%@\", text = \"%@\", with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);

		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			BOOL success = NO;
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromFZMessage:message sender:(NSString *)[message sender] subject:[message subject]];
				IMChatItem *chatItem = [chat chatItemForMessage:imMessage];
				success = [chat deleteChatItem:chatItem];
			}
			else
			{
				NSArray *chatItems = [chat chatItemsForItems:@[message]];
				[chat deleteChatItems:chatItems];
			}

			if (![chat lastMessage] || (!success && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1))
			{
				[chat leave];
				CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.mobilesms"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : chatID}];
			}
		}
	}
	else if (([[[NSProcessInfo processInfo] processName] isEqualToString:@"MobileSMS"] && [transferGUIDArray count] > 0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) || ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1)) // handles messages with attachments in iOS 5 ~ 7 and all messages in iOS 8
	{
		IMChat *chat = [self existingChatWithChatIdentifier:chatID];
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
		if (chat)
		{
			NSArray *handleArray = chat.participants;
			for (IMHandle *handle in handleArray)
			{
				NSString *address = handle.displayID;
				address = [address stringByReplacingOccurrencesOfString:@"\u202a" withString:@""];
				address = [address stringByReplacingOccurrencesOfString:@"\u202c" withString:@""];
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}
		}
		else [addressArray addObject:[message sender]];

		NSString *text = [[message body] string];
		text = [text length] == 0 ? @" " : text;

		NSMutableArray *pictureArray = [NSMutableArray array];
		for (NSString *transferGUID in [message fileTransferGUIDs])
		{
			IMFileTransfer *transfer = [[%c(IMFileTransferCenter) sharedInstance] transferForGUID:transferGUID];
			if ([[transfer mimeType] hasPrefix:@"image/"])
			{
				UIImage *image = [[UIImage alloc] initWithContentsOfFile:[transfer localPath]];
				[pictureArray addObject:image];
				[image release];
			}
			else if ([[transfer mimeType] hasPrefix:@"audio/"])
			{
				// TODO: save audio attachments
			}
			else if ([[transfer mimeType] hasPrefix:@"video/"])
			{
				// TODO: save video attachments
			}
		}

		NSLog(@"SMSNinja: IMChatRegistry | account:chat:style:chatProperties:messageSent: | bundle = \"%@\", addressArray = \"%@\", text = \"%@\", with %lu attachments", [[NSBundle mainBundle] bundleIdentifier], addressArray, text, (unsigned long)[pictureArray count]);

		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			BOOL success = NO;
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromFZMessage:message sender:(NSString *)[message sender] subject:[message subject]];
				IMChatItem *chatItem = [chat chatItemForMessage:imMessage];
				success = [chat deleteChatItem:chatItem];
			}
			else
			{
				NSArray *chatItems = [chat chatItemsForItems:@[message]];
				[chat deleteChatItems:chatItems];
			}

			if (![chat lastMessage] || (!success && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1))
			{
				[chat leave];
				CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.mobilesms"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : chatID}];
			}
		}
	}
}
%end

%hook IMAVTelephonyManager
- (void)_chatStateChanged:(NSConcreteNotification *)arg1 // outgoing FaceTime, state 5: 3 for outgoing/waiting, 6 for ended, 2 for incoming/invited; 6_7_8: 2 for outgoing/waiting, 5 for ended, 1 for incoming/invited
{
	%orig;

	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
	{
		IMAVChat *avChat = [arg1 object];
		if ((kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1 && [avChat state] == 3) || (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && [avChat state] == 2))
		{		
			NSMutableArray *otherParticipants = [NSMutableArray arrayWithCapacity:6];
			[otherParticipants addObjectsFromArray:[avChat participants]];
			[otherParticipants removeObject:[avChat localParticipant]];
			NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
			for (IMAVChatParticipant *participant in otherParticipants)
			{
				IMHandle *handle = [participant imHandle];
				NSString *address = [handle normalizedID];
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}

			NSLog(@"SMSNinja: IMAVTelephonyManager | _chatStateChanged: | addressArray = \"%@\"", addressArray);

			switch (ActionOfAudioFunctionWithInfo(addressArray, YES))
			{
				default:
					// take a rest!
					break;
			}
		}
	}
	else
	{
		IMAVChatProxy *avChatProxy = [arg1 object];
		if ([avChatProxy state] == 2)
		{
			NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
			for (IMAVChatParticipantProxy *participantProxy in [avChatProxy remoteParticipants])
			{
				IMHandle *handle = [participantProxy.avChat otherIMHandle];
				NSString *address = [handle normalizedID];
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}

			NSLog(@"SMSNinja: IMAVTelephonyManager | _chatStateChanged: | addressArray = \"%@\"", addressArray);

			switch (ActionOfAudioFunctionWithInfo(addressArray, YES))
			{
				default:
					// take a rest!
					break;
			}
		}
	}
}
%end

%group SNIncomingFaceTimeHook_5_6_7

%hook MPConferenceManager
- (void)_handleInvitation:(NSConcreteNotification *)invitation // incoming FaceTime
{
	NSString *address = nil;
	NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:1];
	NSString *conferenceID = nil;
	NSURL *inviter = nil; // 5
	IMHandle *handle = nil; // 6_7
	IMAVChatProxy *chatProxy = nil; // 7
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		inviter = [invitation userInfo][@"kCNFConferenceControllerInviterKey"];
		conferenceID = [invitation userInfo][@"kCNFConferenceControllerConferenceIDKey"];	
		address = [inviter absoluteString];
		if ([address hasPrefix:@"facetime://"]) address = [[address substringFromIndex:11] normalizedPhoneNumber];
		[addressArray addObject:address];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		handle = [invitation userInfo][@"kCNFConferenceControllerHandleKey"];
		conferenceID = [invitation userInfo][@"kCNFConferenceControllerConferenceIDKey"];
		address = [handle normalizedID];
		address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[addressArray addObject:address];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
	{
		chatProxy = [invitation object];
		handle = [chatProxy otherIMHandle];
		NSString *address = [handle normalizedID];
		address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[addressArray addObject:address];
	}

	NSLog(@"SMSNinja: MPConferenceManager | _handleInvitation: | addressArray = \"%@\"", addressArray);

	switch (ActionOfAudioFunctionWithInfo(addressArray, NO))
	{
		case 0:
			{
				%orig;
				break;
			}
		case 1:
			{
				if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) [[self conferenceController] rejectFaceTimeInvitationFrom:inviter conferenceID:conferenceID];
				else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) [[self conferenceController] declineFaceTimeInvitationForConferenceID:conferenceID fromHandle:handle];
				else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) [chatProxy declineInvitation];
				break;
			}
		case 2:
			{
				[self stopAudioPlayer];
				break;
			}
		case 3:
			{
				%orig;
				break;
			}
	}
}
%end

%end // end of SNIncomingFaceTimeHook_5_6_7

%group SNIncomingCallHook_5_6_7

%hook MPTelephonyManager
- (void)displayAlertForCall:(id)arg1 // incoming call
{
	CTCallRef call = nil;
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) call = (CTCallRef)arg1;
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) call = [(TUTelephonyCall *)arg1 call];
	if (CTCallGetStatus(call) == 4)
	{
		NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
		NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		NSArray *addressArray = @[tempAddress];	
		[address release];

		NSLog(@"SMSNinja: MPTelephonyManager | displayAlertForCall: | address = \"%@\"", tempAddress);

		switch (ActionOfAudioFunctionWithInfo(addressArray, NO))
		{
			case 0:
				{
					%orig;
					break;
				}
			case 1:
				{
					%orig(nil);
					CTCallDisconnect(call);
					break;
				}
			case 2:
				{
					%orig(nil);
					break;
				}
			case 3:
				{
					%orig;
					break;
				}
		}
	}
	else %orig;
}
%end

%end // end of SNIncomingCallHook_5_6_7

%group SNIncomingMessageHook_5_6_7_8

%hook IMDServiceSession
- (void)didReceiveMessage:(id)message forChat:(NSString *)arg2 style:(unsigned char)arg3 // incoming iMessage_5/message_6_7_8
{	
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) message = (FZMessage *)message;
	else message = (IMMessageItem *)message;

	if (![message isFinished]) %orig;
	else
	{
		NSArray *transferGUIDArray = [message fileTransferGUIDs];
		NSString *sender = [(NSString *)[message sender] normalizedPhoneNumber];
		NSArray *addressArray = @[sender];

		NSAttributedString *body = [message body];
		NSString *text = [[message body] string];
		NSMutableArray *substringArray = [NSMutableArray arrayWithCapacity:10];

		void (^customBlock)(id value, NSRange range, BOOL *stop) = ^(id value, NSRange range, BOOL *stop)
		{
			if (value) [substringArray addObject:[text substringWithRange:range]];
		};

		[body enumerateAttribute:@"__kIMFileTransferGUIDAttributeName" inRange:NSMakeRange(0, [text length]) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:customBlock];

		for (NSString *substring in substringArray)
			text = [text stringByReplacingOccurrencesOfString:substring withString:@" "];
		text = [text length] != 0 ? text : @" ";

		IMDFileTransferCenter *center = [%c(IMDFileTransferCenter) sharedInstance];
		NSMutableArray *pictureArray = [NSMutableArray array];
		for (NSString *transferGUID in transferGUIDArray)
		{
			IMFileTransfer *transfer = [center transferForGUID:transferGUID];
			if ([[transfer mimeType] hasPrefix:@"image/"])
			{
				UIImage *image = [[UIImage alloc] initWithContentsOfFile:[transfer localPath]];
				[pictureArray addObject:image];
				[image release];
			}
			else if ([[transfer mimeType] hasPrefix:@"audio/"])
			{
				// TODO: save audio attachments
			}
			else if ([[transfer mimeType] hasPrefix:@"video/"])
			{
				// TODO: save video attachments
			}
		}

		NSLog(@"SMSNinja: IMDServiceSession | didReceiveMessage:forChat:style: | address = \"%@\", text = \"%@\", with %lu attachments", sender, text, (unsigned long)[pictureArray count]);

		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, NO) == 0) %orig;
		else
		{
			IMDChatRegistry *chatRegistry = [%c(IMDChatRegistry) sharedInstance];
			IMDChat *chat = [chatRegistry existingChatForID:arg2 account:[self account]];
			BOOL deleteChat = NO;
			if ([chatRegistry respondsToSelector:@selector(removeMessage:fromChat:)]) [chatRegistry removeMessage:message fromChat:chat];
			else deleteChat = YES;
			if (![chat lastMessage] || deleteChat)
			{
				IMDChatStore *store = [%c(IMDChatStore) sharedInstance];
				if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
				{
					static NSThread *(*IMDPersistenceDatabaseThread)(void);	
					void *libHandle = dlopen("/System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence", RTLD_LAZY);
					IMDPersistenceDatabaseThread = (NSThread *(*)(void))dlsym(libHandle, "IMDPersistenceDatabaseThread");
					if ([store respondsToSelector:@selector(deleteChat:)]) [store performSelector:@selector(deleteChat:) onThread:IMDPersistenceDatabaseThread() withObject:chat waitUntilDone:YES];
					else if ([store respondsToSelector:@selector(deleteChatWithGUID:)]) [store performSelector:@selector(deleteChatWithGUID:) onThread:IMDPersistenceDatabaseThread() withObject:[chat guid] waitUntilDone:YES];
					dlclose(libHandle);
				}
				else
				{
					if ([store respondsToSelector:@selector(deleteChat:)]) [store deleteChat:chat];
					else if ([store respondsToSelector:@selector(deleteChatWithGUID:)]) [store deleteChatWithGUID:[chat guid]];
				}
				CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.mobilesms"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : arg2}];
				messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : arg2}];					
			}
		}
	}
}
%end

%end // end of SNIncomingMessageHook_5_6_7_8

%hook IMDaemon
- (void)_loadServices
{
	%orig;
	%init(SNIncomingMessageHook_5_6_7_8);
}
%end

%group SNBulletinHook_5_6

%hook MPBBDataProvider
- (void)_handleRecentCallNotification:(NSString *)notification userInfo:(NSDictionary *)info
{
	if ([notification isEqualToString:@"kCTCallHistoryRecordAddNotification"])
	{
		CTCallRef call = (CTCallRef)info[@"kCTCall"];
		if (!CTCallIsOutgoing(call))
		{
			NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
			NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[address release];

			NSLog(@"SMSNinja: MPBBDataProvider | _handleRecentCallNotification:userInfo: | address = \"%@\"", tempAddress);

			NSUInteger index = NSNotFound;
			if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
			{
				if ([privatePhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
		}
	}
	%orig;
}
%end

%end // end of SNBulletinHook_5_6

%group SNBulletinHook_7

%hook MPBBDataProvider
- (void)_handleRecentCallNotification:(NSString *)notification userInfo:(NSDictionary *)info
{
	if ([notification isEqualToString:@"kCTCallHistoryRecordAddNotification"])
	{
		CTCallRef call = (CTCallRef)info[@"kCTCall"];
		if (!CTCallIsOutgoing(call))
		{
			NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
			NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[address release];

			NSLog(@"SMSNinja: MPBBDataProvider | _handleRecentCallNotification:userInfo: | address = \"%@\"", tempAddress);

			NSUInteger index = NSNotFound;
			if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
			{
				if ([privatePhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
		}
	}
	%orig;
}
%end

%end // end of SNBulletinHook_7

%group SNBulletinHook_8
/*
%hook MPBBDataProvider
- (void)_handleCallHistoryDatabaseChangedNotification:(id)arg1
{
	// TODO: 有时会崩溃！
	CHManager *recentsManager = MSHookIvar<CHManager *>(self, "_recentsManager");
	NSArray *recentCalls = recentsManager.recentCalls;
	if ([recentCalls count] > 0)
	{
		CHRecentCall *recentCall = recentCalls[0];
		if (![recentCall.originated boolValue])
		{
			NSString *address = recentCall.callerId;
			NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[address release];

			NSLog(@"SMSNinja: MPBBDataProvider | _handleCallHistoryDatabaseChangedNotification: | arg1 = \"%@\", call = \"%@\", address = \"%@\"", arg1, recentCall, tempAddress);

			NSUInteger index = NSNotFound;
			if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
			{
				if ([privatePhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) return;
			}
			else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
			%orig;
		}
		else %orig;
	}
	else %orig;
}
%end
*/
%end // end of SNBulletinHook_8

%group SNGeneralHook_5

%hook SMSCTServer
- (void)_ingestIncomingCTMessage:(CTMessage *)message // incoming SMS
{
	id sender = message.sender;
	NSString *address = @"";
	if ([sender respondsToSelector:@selector(digits)]) address = [sender digits];
	else if ([sender respondsToSelector:@selector(address)]) address = [sender address];
	address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	NSArray *addressArray = @[address];

	NSArray *items = message.items;
	NSString *text = @"";
	NSMutableArray *pictureArray = [NSMutableArray arrayWithCapacity:6];
	for (CTMessagePart *part in items)
	{
		if ([part.contentType isEqualToString:@"text/plain"])
		{
			NSString *string = [[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding];
			text = [[text stringByAppendingString:string] stringByAppendingString:@" "];
			[string release];
		}
		else if ([part.contentType hasPrefix:@"image/"])
		{
			UIImage *image = [[UIImage alloc] initWithData:part.data];
			[pictureArray addObject:image];
			[image release];
		}
	}
	text = [text length] != 0 ? [text substringToIndex:([text length] - 1)] : @" ";

	NSLog(@"SMSNinja: SMSCTServer | _ingestIncomingCTMessage: | address = \"%@\", text = \"%@\", with %lu attachments", address, text, (unsigned long)[pictureArray count]);

	if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, NO) == 0) %orig;
	else %orig(nil);
}
%end

%hook CKSMSService
- (void)_sentMessage:(id)arg1 replace:(BOOL)arg2 postInternalNotification:(BOOL)arg3 // outgoing SMS
{
	%orig;

	void *libHandle = dlopen("/System/Library/PrivateFrameworks/IMCore.framework/Frameworks/IMDPersistence.framework/IMDPersistence", RTLD_LAZY);
	int (*IMDSMSRecordGetRecordIdentifier)(id arg1) = (int (*)(id))dlsym(libHandle, "IMDSMSRecordGetRecordIdentifier");
	int messageRowID = IMDSMSRecordGetRecordIdentifier(arg1);
	CKSMSMessage *message = [[%c(CKSMSMessage) alloc] initWithRowID:messageRowID];
	dlclose(libHandle);

	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [message messagePartCount] == 0) // handles text only messages
	{
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
		NSString *address = [[message address] normalizedPhoneNumber];
		[addressArray addObject:address];
		NSString *text = [message text];

		NSMutableArray *pictureArray = [NSMutableArray arrayWithCapacity:6];

		NSLog(@"SMSNinja: CKSMSService | _sentMessage: | addressArray = \"%@\", text = \"%@\", with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);

		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			[self beginBulkDeleteMode];
			CKSubConversation *conversation = [[%c(CKConversationList) sharedConversationList] conversationForMessage:message create:NO service:self];
			if (!conversation) conversation = [[%c(CKConversationList) sharedConversationList] conversationForMessage:message create:YES service:self];
			[self deleteMessage:message fromConversation:conversation];
			if ([conversation isEmpty]) [conversation deleteAllMessagesAndRemoveGroup];
			[self endBulkDeleteMode];
			ReloadConversation();
		}
	}
	else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"MobileSMS"] && [message messagePartCount] > 0) // handles messages with attachments
	{
		CKSubConversation *conversation = [[%c(CKConversationList) sharedConversationList] conversationForMessage:message create:NO service:self];
		NSArray *entities = conversation.recipients;
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
		if ([entities count] == 0) // single recipient, but Apple, why 0 instead of 1?
		{
			NSString *address = [[message address] normalizedPhoneNumber];
			[addressArray addObject:address];
		}
		else // multiple recipients
		{
			for (CKSMSEntity *entity in entities)
			{
				NSString *address = entity.rawAddress;
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}
		}
		NSString *text = @"";
		NSMutableArray *pictureArray = [NSMutableArray arrayWithCapacity:6];
		for (CKMessagePart *part in [message parts]) // save text
		{
			if ([part type] == 0) // text
			{
				text = [[text stringByAppendingString:[part text]] stringByAppendingString:@" "];
			}
			else if ([part type] == 1) // image
			{
				CKCompressibleImageMediaObject *mediaObject = [part mediaObject];
				CKImageData *imageData = [mediaObject imageData];
				UIImage *image = [[UIImage alloc] initWithData:imageData.data];
				[pictureArray addObject:image];
				[image release];
			}
		}
		text = [text length] != 0 ? [text substringToIndex:([text length] - 1)] : @" ";

		NSLog(@"SMSNinja: CKSMSService | _sentMessage: | addressArray = \"%@\", text = \"%@\", with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);

		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			[self beginBulkDeleteMode];
			[self deleteMessage:message fromConversation:conversation];
			if ([conversation isEmpty]) [conversation deleteAllMessagesAndRemoveGroup];
			[self endBulkDeleteMode];
			ReloadConversation();
		}
	}
	[message release];	
}
%end

%end // end of SNGeneralHook_5

%group SNGeneralHook_5_6

%hook RecentsViewController
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [settings[@"appIsOn"] boolValue])
	{
		NSUInteger chosenRow = [[self table] indexPathForCell:((UITableViewCell *)gesture.view)].row;
		id call = nil;
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) call = [self calls][chosenRow];
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) call = [self callAtTableViewIndex:chosenRow];
		if ([call isKindOfClass:[%c(RecentCall) class]]) // including RecentMultiCall
		{
			RecentsTableViewCell *cell = (RecentsTableViewCell *)gesture.view;
			for (UIView *subview in cell.subviews)
				if ([subview isKindOfClass:[%c(UITableViewCellContentView) class]])
					for (UIView *subsubview in subview.subviews)
						if ([subsubview isKindOfClass:[%c(RecentsTableViewCellContentView) class]])
						{
							[chosenName release];
							chosenName = nil;
							chosenName = [[NSString alloc] initWithString:((RecentsTableViewCellContentView *)subsubview).callerName];
							break;
						}

			NSString *tempString = @"";
			NSArray *ctCalls = [call underlyingCTCalls];
			for (NSUInteger i = 0; i < [ctCalls count]; i++)
			{
				CTCallRef ctCall = (CTCallRef)ctCalls[i];
				NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, ctCall);
				if (![[tempString componentsSeparatedByString:@"  "] containsObject:[address normalizedPhoneNumber]]) tempString = [[tempString stringByAppendingString:[address normalizedPhoneNumber]] stringByAppendingString:@"  "];
				[address release];
			}
			[chosenKeyword release];
			chosenKeyword = nil;
			chosenKeyword = [tempString length] != 0 ? [[NSString alloc] initWithString:[tempString substringToIndex:([tempString length] - 2)]] : @"";
		}
#ifdef DEBUG
		NSLog(@"SMSNinja: RecentsViewController | snLongPress: | chosenName = \"%@\", chosenKeyword = \"%@\"", chosenName, chosenKeyword);
#endif
		[snActionSheetDelegate release];
		snActionSheetDelegate = nil;
		snActionSheetDelegate = [[SNActionSheetDelegate alloc] init];
		snActionSheet.delegate = nil;
		[snActionSheet release];
		snActionSheet = nil;
		snActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:snActionSheetDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		if ([chosenKeyword indexInBlackListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Blacklist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInWhiteListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Whitelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [settings[@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		[snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		snActionSheet.cancelButtonIndex = snActionSheet.numberOfButtons - 1;
		if (snActionSheet.numberOfButtons > 1) [snActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		else
		{
			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
				duration:0.6f
				options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
				animations:^{
					[((UITableViewCell *)gesture.view).contentView.layer performSelector:@selector(removeAllAnimations) withObject:nil afterDelay:1.8f];
					((UITableViewCell *)gesture.view).contentView.layer.opacity = 0.0f;
				}
				completion:^(BOOL finished){
		   			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
			 		duration:0.6f
					options:UIViewAnimationOptionTransitionNone
					animations:^{
						((UITableViewCell *)gesture.view).contentView.layer.opacity = 1.0f;
					}
					completion:NULL
		   			];
				}];
		}
	}
}

- (UITableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2
{
	UITableViewCell *result = %orig;
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(snLongPress:)];
	[result addGestureRecognizer:longPressGesture];
	[longPressGesture release];
	return result;
}
%end

%hook BBServer
- (void)_loadDataProviderPluginBundle:(NSBundle *)bundle
{
	%orig;
	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone.bbplugin"]) %init(SNBulletinHook_5_6);
}
%end

%end // end of SNGeneralHook_5_6

%group SNGeneralHook_5_6_7

static void (*oldCallBack)(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static void newCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	oldCallBack(center, observer, name, object, userInfo);
	CTCallRef call = (CTCallRef)((NSDictionary *)userInfo)[@"kCTCall"];
	NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
	NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	[address release];

	NSLog(@"SMSNinja: CoreTelephony | newCallBack(kCTCallHistoryRecordAddNotification) | address = \"%@\"", tempAddress);

	if ([settings[@"appIsOn"] boolValue] && call)
	{
		BOOL isOutgoing = CTCallIsOutgoing(call);
		BOOL shouldClearSpam = NO;
		NSUInteger index = NSNotFound;
		if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
		{
			if ([privatePhoneArray[index] intValue] != 0) shouldClearSpam = YES;
		}
		else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
		{
			if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
		}
		else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
		{
			if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
		}
		else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
		{
		}
		else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;

		if (shouldClearSpam)
		{
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) CTCallDeleteFromCallHistory(call);
			else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) // this is dirty on iOS 7 :(
			{
				NSArray *callArray = (NSArray *)_CTCallCopyAllCalls();
				if ([callArray count] != 0)
				{
					CTCallRef historyCall = (CTCallRef)callArray[0];
					NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
					NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
					NSString *historyAddress = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, historyCall);
					NSString *historyTempAddress = [historyAddress length] == 0 ? @"" : [historyAddress normalizedPhoneNumber];

					BOOL historyIsOutgoing = CTCallIsOutgoing(historyCall);

					double *startTime = (double *)malloc(sizeof(double));
					bzero(startTime, sizeof(double));
					CTCallGetStartTime(call, startTime);
					double *historyStartTime = (double *)malloc(sizeof(double));
					bzero(historyStartTime, sizeof(double));
					CTCallGetStartTime(historyCall, historyStartTime);

					if ([tempAddress isEqualToString:historyTempAddress] && isOutgoing == historyIsOutgoing && *startTime == *historyStartTime) CTCallDeleteFromCallHistory(historyCall);

					[address release];
					[historyAddress release];

					free(startTime);
					free(historyStartTime);					
				}
				[callArray release];
			}
		}
	}
}

extern "C" void CTTelephonyCenterAddObserver(CFNotificationCenterRef center, const void *observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior);

void (*old_CTTelephonyCenterAddObserver)(CFNotificationCenterRef center, const void *observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior);

void new_CTTelephonyCenterAddObserver(CFNotificationCenterRef center, const void *observer, CFNotificationCallback callBack, CFStringRef name, const void *object, CFNotificationSuspensionBehavior suspensionBehavior)  // delete call history
{
	if ([(NSString *)name isEqualToString:@"kCTCallHistoryRecordAddNotification"])
	{
		oldCallBack = callBack;
		old_CTTelephonyCenterAddObserver(center, observer, newCallBack, name, object, suspensionBehavior);
	}
	else old_CTTelephonyCenterAddObserver(center, observer, callBack, name, object, suspensionBehavior);
}

%hook PhoneApplication
- (BOOL)dialPhoneNumber:(NSString *)arg1 dialAssist:(BOOL)arg2
{
	NSString *number = [arg1 normalizedPhoneNumber];

	NSLog(@"SMSNinja: PhoneApplication | dialPhoneNumber:dialAssist: | number = \"%@\"", number);

	if ( ([settings[@"appIsOn"] boolValue] && [number isEqualToString:settings[@"launchCode"]]) || ([settings[@"shouldHideIcon"] boolValue] && [settings[@"launchCode"] length] == 0 && [number isEqualToString:@"666666"]) )
	{
		PhoneTabBarController *tabBarController = [self currentViewController];
		DialerController *dialerController = tabBarController.keypadViewController;
		if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
		{
			DialerView *dialerView = MSHookIvar<DialerView *>(dialerController, "_dialerView");
			DialerLCDField *lcd = [dialerView lcd];
			[lcd setText:@"" needsFormat:NO];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
		{
			DialerView *dialerView = MSHookIvar<DialerView *>(dialerController, "_dialerView");
			DialerLCDView *lcdView = [dialerView lcdView];
			UILabel* numberLabel = [lcdView numberLabel];
			[numberLabel setText:@""];
		}
		else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
		{
			PHHandsetDialerView *dialerView = MSHookIvar<PHHandsetDialerView *>(dialerController, "_dialerView");
			PHHandsetDialerLCDView *lcdView = [dialerView lcdView];
			UILabel* numberLabel = [lcdView numberLabel];
			[numberLabel setText:@""];
		}

		CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
		[messagingCenter sendMessageName:@"LaunchSMSNinja" userInfo:nil];
		return NO;
	}
	return %orig;
}
%end

%hook SBPluginManager
- (Class)loadPluginBundle:(NSBundle *)bundle
{
	Class result = %orig;
	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone.incomingcall"])
	{
		%init(SNIncomingFaceTimeHook_5_6_7);
		%init(SNIncomingCallHook_5_6_7);
	}
	return result;
}
%end

%end // end of SNGeneralHook_5_6_7

%group SNGeneralHook_7_8

%hook PHRecentsViewController // MobilePhone & FaceTime on 7, MobilePhone only on 8
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [settings[@"appIsOn"] boolValue])
	{
		NSUInteger chosenRow = [[self table] indexPathForCell:((UITableViewCell *)gesture.view)].row;
		id call = [self callAtTableViewIndex:chosenRow];
		if ([call isKindOfClass:[%c(PHRecentCall) class]]) // including RecentMultiCall
		{
			[chosenName release];
			chosenName = nil;
			chosenName = [[NSString alloc] initWithString:[(PHRecentCall *)call callerDisplayName]];

			NSString *tempString = @"";
			NSArray *ctCalls = [call underlyingCTCalls];
			for (NSUInteger i = 0; i < [ctCalls count]; i++)
			{
				CTCallRef ctCall = (CTCallRef)ctCalls[i];
				NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, ctCall);
				if (![[tempString componentsSeparatedByString:@"  "] containsObject:[address normalizedPhoneNumber]]) tempString = [[tempString stringByAppendingString:[address normalizedPhoneNumber]] stringByAppendingString:@"  "];
				[address release];
			}
			[chosenKeyword release];
			chosenKeyword = nil;
			chosenKeyword = [tempString length] != 0 ? [[NSString alloc] initWithString:[tempString substringToIndex:([tempString length] - 2)]] : @"";
		}
		else if ([call isKindOfClass:[%c(CHRecentCall) class]])
		{
			[chosenName release];
			chosenName = nil;
			chosenName = [[NSString alloc] initWithString:[(CHRecentCall *)call callerNameForDisplay]];

			[chosenKeyword release];
			chosenKeyword = nil;
			chosenKeyword = [[NSString alloc] initWithString:[[(CHRecentCall *)call callerId] normalizedPhoneNumber]];
		}

		NSLog(@"SMSNinja: PHRecentsViewController | snLongPress: | chosenName = \"%@\", chosenKeyword = \"%@\"", chosenName, chosenKeyword);

		[snActionSheetDelegate release];
		snActionSheetDelegate = nil;
		snActionSheetDelegate = [[SNActionSheetDelegate alloc] init];
		snActionSheet.delegate = nil;
		[snActionSheet release];
		snActionSheet = nil;
		snActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:snActionSheetDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		if ([chosenKeyword indexInBlackListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Blacklist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInWhiteListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Whitelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [settings[@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		[snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		snActionSheet.cancelButtonIndex = snActionSheet.numberOfButtons - 1;
		if (snActionSheet.numberOfButtons > 1) [snActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		else
		{
			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
				duration:0.6f
				options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
				animations:^{
					[((UITableViewCell *)gesture.view).contentView.layer performSelector:@selector(removeAllAnimations) withObject:nil afterDelay:1.8f];
					((UITableViewCell *)gesture.view).contentView.layer.opacity = 0.0f;
				}
				completion:^(BOOL finished){
		   			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
			   		duration:0.6f
			   		options:UIViewAnimationOptionTransitionNone
			   		animations:^{
				   		((UITableViewCell *)gesture.view).contentView.layer.opacity = 1.0f;
			   		}
					completion:NULL
		   			];
	   			}];
		}
	}
}

- (UITableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2
{
	UITableViewCell *result = %orig;
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(snLongPress:)];
	[result addGestureRecognizer:longPressGesture];
	[longPressGesture release];
	return result;
}
%end

%hook TUPrivacyManager // take over stock blocklist, only allows removal
- (void)setBlockIncomingCommunication:(BOOL)arg1 forPhoneNumber:(TUPhoneNumber *)arg2 // arg1: YES for add, NO for remove
{
	if (!arg1) %orig;
}

- (void)setBlockIncomingCommunication:(BOOL)arg1 forEmailAddress:(TUPhoneNumber *)arg2
{
	if (!arg1) %orig;
}
%end

extern "C" BOOL CMFBlockListIsItemBlocked(CommunicationFilterItem *);

BOOL (*old_CMFBlockListIsItemBlocked)(CommunicationFilterItem *);

BOOL new_CMFBlockListIsItemBlocked(CommunicationFilterItem *item)  // disable stock blocklist check
{
	return NO;
}

%end // end of SNGeneralHook_7_8

%group SNGeneralHook_7

%hook BBDataProviderManager
- (void)_loadDataProviderPluginBundle:(NSBundle *)bundle
{
	%orig;
	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone.bbplugin"]) %init(SNBulletinHook_7);
}
%end

%hook IMDaemonController // grant SpringBoard permission to send messages :P
- (BOOL)addListenerID:(NSString *)arg1 capabilities:(unsigned)arg2
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [arg1 isEqualToString:@"com.apple.MobileSMS"]) return %orig(arg1, 16647);
	return %orig;
}
%end

%end // end of SNGeneralHook_7

%group SNGeneralHook_8

%hook PHFrecentViewController // FaceTime on 8
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [settings[@"appIsOn"] boolValue])
	{
		NSUInteger chosenRow = [[self table] indexPathForCell:((UITableViewCell *)gesture.view)].row;
		CHRecentCall *call = [self callAtTableViewIndex:chosenRow];
		[chosenName release];
		chosenName = nil;
		chosenName = [[NSString alloc] initWithString:[(CHRecentCall *)call callerNameForDisplay]];

		[chosenKeyword release];
		chosenKeyword = nil;
		chosenKeyword = [[NSString alloc] initWithString:[[(CHRecentCall *)call callerId] normalizedPhoneNumber]];

		NSLog(@"SMSNinja: PHFrecentViewController | snLongPress: | chosenName = \"%@\", chosenKeyword = \"%@\"", chosenName, chosenKeyword);

		[snActionSheetDelegate release];
		snActionSheetDelegate = nil;
		snActionSheetDelegate = [[SNActionSheetDelegate alloc] init];
		snActionSheet.delegate = nil;
		[snActionSheet release];
		snActionSheet = nil;
		snActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:snActionSheetDelegate cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
		if ([chosenKeyword indexInBlackListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Blacklist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInWhiteListWithType:0] == NSNotFound) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Whitelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [settings[@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		[snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
		snActionSheet.cancelButtonIndex = snActionSheet.numberOfButtons - 1;
		if (snActionSheet.numberOfButtons > 1) [snActionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		else
		{
			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
				duration:0.6f
				options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
				animations:^{
					[((UITableViewCell *)gesture.view).contentView.layer performSelector:@selector(removeAllAnimations) withObject:nil afterDelay:1.8f];
					((UITableViewCell *)gesture.view).contentView.layer.opacity = 0.0f;
				}
				completion:^(BOOL finished){
		   			[UIView transitionWithView:((UITableViewCell *)gesture.view).contentView
					duration:0.6f
					options:UIViewAnimationOptionTransitionNone
					animations:^{
						((UITableViewCell *)gesture.view).contentView.layer.opacity = 1.0f;
					}
					completion:NULL
		   			];
	   			}];
		}
	}
}

- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2
{
	UITableViewCell *result = %orig;
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(snLongPress:)];
	[result addGestureRecognizer:longPressGesture];
	[longPressGesture release];
	return result;
}
%end

%hook PhoneApplication
- (BOOL)openURL:(NSURL *)arg1 // should be something like tel://10010?suppressAssist=1&originatingUI=dialer
{
	NSString *number = [arg1 absoluteString];
	if (![number hasPrefix:@"tel://"]) return %orig;

	NSUInteger location = [number rangeOfString:@"?"].location;
	number = [number substringWithRange:NSMakeRange(6, location - 6)];
	number = [number normalizedPhoneNumber];

	NSLog(@"SMSNinja: PhoneApplication | openURL: | number = \"%@\"", number);

	if ( ([settings[@"appIsOn"] boolValue] && [number isEqualToString:settings[@"launchCode"]]) || ([settings[@"shouldHideIcon"] boolValue] && [settings[@"launchCode"] length] == 0 && [number isEqualToString:@"666666"]) )
	{
		PhoneTabBarController *tabBarController = [self currentViewController];
		DialerController *dialerController = tabBarController.keypadViewController;
		PHHandsetDialerView *dialerView = MSHookIvar<PHHandsetDialerView *>(dialerController, "_dialerView");
		PHHandsetDialerLCDView *lcdView = [dialerView lcdView];
		UILabel* numberLabel = [lcdView numberLabel];
		[numberLabel setText:@""];

		CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
		[messagingCenter sendMessageName:@"LaunchSMSNinja" userInfo:nil];
		return NO;
	}
	return %orig;
}
%end

%hook BBLocalDataProviderStore
- (void)_loadDataProviderPluginBundle:(NSBundle *)bundle
{
	%orig;
	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone.bbplugin"]) %init(SNBulletinHook_8);
}
%end

%hook IMDaemonController // grant SpringBoard permission to send messages :P
- (unsigned int)capabilities
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"]) return 17159 | %orig;
	return %orig;
}
%end

%hook TUCallCenter
- (void)handleCallStatusChanged:(TUCall *)arg1 userInfo:(NSDictionary *)arg2 // incoming call & facetime inside SpringBoard
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])
	{
		NSMutableArray *addressArray = nil;
		if ([arg1 isKindOfClass:NSClassFromString(@"TUFaceTimeCall")]) // facetime audio or video
		{
			IMAVChatProxy *avChatProxy = [(TUFaceTimeVideoCall *)arg1 chat];
			if ([avChatProxy state] == 1)
			{
				addressArray = [NSMutableArray arrayWithCapacity:6];
				for (IMAVChatParticipantProxy *participantProxy in [avChatProxy remoteParticipants])
				{
					IMHandle *handle = [participantProxy.avChat otherIMHandle];
					NSString *address = [handle normalizedID];
					address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
					[addressArray addObject:address];
				}
			}
			else
			{
				%orig;
				return;
			}
		}
		else if ([arg1 isKindOfClass:NSClassFromString(@"TUTelephonyCall")])
		{
			CTCallRef call = [(TUTelephonyCall *)arg1 call];
			if (CTCallGetStatus(call) == 4)
			{
				addressArray = [NSMutableArray arrayWithCapacity:6];
				NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
				NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				addressArray = (NSMutableArray *)@[tempAddress];	
				[address release];
			}
			else
			{
				%orig;
				return;
			}
		}

		NSLog(@"SMSNinja: TUCallCenter | handleCallStatusChanged:userInfo: | addressArray = \"%@\"", addressArray);

		switch (ActionOfAudioFunctionWithInfo(addressArray, NO))
		{
			case 0:
				{
					%orig;
					break;
				}
			case 1:
				{
					[self disconnectCall:arg1];
					break;
				}
			case 2:
				{
					break;
				}
			case 3:
				{
					%orig;
					break;
				}
		}
	}
	else %orig;
}
%end

%end // end of SNGeneralHook_8

%group SNCallServicesdHook

%hook NSManagedObjectContext
- (void)insertObject:(NSManagedObject *)object
{
	if ([object isKindOfClass:NSClassFromString(@"CallRecord")])
	{
		CallRecord *record = (CallRecord *)object;
		NSString *address = record.address;
		NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[address release];

		NSLog(@"SMSNinja: NSManagedObjectContext | insertObject: | address = \"%@\"", tempAddress);

		if ([settings[@"appIsOn"] boolValue]) // when calltype is 1 i.e. telephony, everything is fine; when it's 8 i.e. facetime, callservicesd crashes
		{
			BOOL isOutgoing = [record.originated boolValue];
			BOOL shouldClearSpam = NO;
			NSUInteger index = NSNotFound;
			if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
			{
				if ([privatePhoneArray[index] intValue] != 0) shouldClearSpam = YES;
			}
			else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
			}
			else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
			{
				if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
			}
			else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;

			if (!shouldClearSpam) %orig;
		}
		else %orig;
	}
	else %orig;
}
/*
- (BOOL)save:(NSError **)error
{
	if ([self hasChanges])
	{
		NSSet *allInsertedRecords = self.insertedObjects;
		if ([allInsertedRecords count] != 0)
		{
			// NSMutableArray *deadRecords = [NSMutableArray arrayWithCapacity:6];
			for (CallRecord *record in allInsertedRecords)
			{
				NSString *address = record.address;
				NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[address release];

				NSLog(@"SMSNinja: NSManagedObjectContext | save: | address = \"%@\"", tempAddress);

				if ([settings[@"appIsOn"] boolValue]) // when calltype is 1 i.e. telephony, everything is fine; when it's 8 i.e. facetime, callservicesd crashes
				{
					BOOL isOutgoing = [record.originated boolValue];
					BOOL shouldClearSpam = NO;
					NSUInteger index = NSNotFound;
					if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
					{
						if ([privatePhoneArray[index] intValue] != 0) shouldClearSpam = YES;
					}
					else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
					{
						if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
					}
					else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
					{
						if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
					}
					else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
					{
					}
					else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;

					if (shouldClearSpam) return NO; // [deadRecords addObject:record.unique_id];
				}
			}
			// if ([deadRecords count] != 0) [[[%c(DBHandleManager) instance] dbHandle] deleteObjectsWithUniqueIds:deadRecords];
		}
	}
	return %orig;
}
*/
%end

%hook CallHistoryDBHandle
/*
- (void)updateCallDBProperties
{
	// %orig;
	object_setInstanceVariable(self, "fCallRecordContext", NULL);
	NSLog(@"SMSNinjaDebug: 1");
}
*/
- (void)handleCallRecordContextDidSaveNotification:(NSDictionary *)arg1 // delete call history
{
	// TODO: 感觉还是删除操作不到位造成的，貌似要考虑NSManagedObjectContext的保存问题！
	/*
	   NSArray *allKeys = [arg1 allKeys];
	   if ([allKeys indexOfObject:@"inserted"] != NSNotFound)
	   {
	   NSSet *allInsertedRecords = arg1[@"inserted"];
	   if ([allInsertedRecords count] != 0)
	   {
	   NSMutableArray *deadRecords = [NSMutableArray arrayWithCapacity:6];
	   for (CallRecord *record in allInsertedRecords)
	   {
	   NSString *address = record.address;
	   NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	   [address release];
	   if ([settings[@"appIsOn"] boolValue] && [record.calltype intValue] == 1) // when calltype is 8 i.e. facetime, callservicesd crashes
	   {
	   NSLog(@"SMSNinja: CallHistoryDBHandle | handleCallRecordContextDidSaveNotification: | address = \"%@\"", tempAddress);
	   BOOL isOutgoing = [record.originated boolValue];
	   BOOL shouldClearSpam = NO;
	   NSUInteger index = NSNotFound;
	   if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
	   {
	   if ([privatePhoneArray[index] intValue] != 0) shouldClearSpam = YES;
	   }
	   else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
	   {
	   if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
	   }
	   else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
	   {
	   if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;
	   }
	   else if ([tempAddress isInAddressBook] && [settings[@"shouldIncludeContactsInWhitelist"] boolValue])
	   {
	   }
	   else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([settings[@"whitelistCallsOnlyWithBeep"] boolValue] || [settings[@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [settings[@"shouldClearSpam"] boolValue] & !isOutgoing;

	   if (shouldClearSpam) [deadRecords addObject:record.unique_id];
	   }
	   }
	   if ([deadRecords count] != 0) [[[%c(DBHandleManager) instance] dbHandle] deleteObjectsWithUniqueIds:deadRecords];
	   }
	   }
	 */
	%orig;
}
%end

%end // end of SNCallServicesdHook

%ctor
{
	@autoreleasepool
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0)
		{
			if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"callservicesd"]) %init(SNCallServicesdHook);
			else
			{			
				%init;
				if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) %init(SNGeneralHook_5);
				if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) %init(SNGeneralHook_5_6);
				if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
				{
					MSHookFunction(&CTTelephonyCenterAddObserver, &new_CTTelephonyCenterAddObserver, &old_CTTelephonyCenterAddObserver);
					%init(SNGeneralHook_5_6_7);
				}
				if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
				{
					MSHookFunction(&CMFBlockListIsItemBlocked, &new_CMFBlockListIsItemBlocked, &old_CMFBlockListIsItemBlocked);
					%init(SNGeneralHook_7_8);
					if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) %init(SNGeneralHook_7);
					else %init(SNGeneralHook_8);
				}
			}

			LoadAllLists(nil, nil, nil, nil, nil);
			LoadSettings(nil, nil, nil, nil, nil);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, LoadBlacklist, CFSTR("com.naken.smsninja.blacklistchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, LoadWhitelist, CFSTR("com.naken.smsninja.whitelistchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, LoadPrivatelist, CFSTR("com.naken.smsninja.privatelistchanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, LoadSettings, CFSTR("com.naken.smsninja.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		}
	}
}
