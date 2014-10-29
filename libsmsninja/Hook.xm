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

static void (*oldCallBack)(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

static void newCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	oldCallBack(center, observer, name, object, userInfo);
	CTCallRef call = (CTCallRef)[(NSDictionary *)userInfo objectForKey:@"kCTCall"];
	NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
	NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	[address release];
#ifdef DEBUG
	NSLog(@"SMSNinja: newCallBack(kCTCallHistoryRecordAddNotification): address = %@", tempAddress);
#endif
	if ([[settings objectForKey:@"appIsOn"] boolValue] && call)
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
			if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue] & !isOutgoing;
		}
		else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
		{
			if ([blackPhoneArray[index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue] & !isOutgoing;
		}
		else if ([tempAddress isInAddressBook] && [[settings objectForKey:@"shouldIncludeContactsInWhitelist"] boolValue])
		{
		}
		else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue] & !isOutgoing;

		if (shouldClearSpam)
		{
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) CTCallDeleteFromCallHistory(call);
			else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) // this is dirty :(
			{
				NSArray *callArray = (NSArray *)_CTCallCopyAllCalls();
				if ([callArray count] != 0)
				{
					CTCallRef historyCall = (CTCallRef)callArray[0];
					NSLog(@"SMSNinjaDebug0: historyCall = %@, call = %@", historyCall, call);
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
	// TODO: iOS 8没这个通知了？
	if ([(NSString *)name isEqualToString:@"kCTCallHistoryRecordAddNotification"])
	{
		oldCallBack = callBack;
		old_CTTelephonyCenterAddObserver(center, observer, newCallBack, name, object, suspensionBehavior);
	}
	else old_CTTelephonyCenterAddObserver(center, observer, callBack, name, object, suspensionBehavior);
}

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
					if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
				}
				sqlite3_close(database);
				notify_post([[NSString stringWithFormat:@"com.naken.smsninja.%@listchanged", flag] UTF8String]);
			}
			else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
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
		IMChat *chat = [[%c(IMChatRegistry) sharedInstance] existingChatWithChatIdentifier:(NSString *)[userInfo objectForKey:@"chatID"]];
		[chat leave];
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
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) [messagingCenter registerForMessageName:@"RefreshConversation" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) [messagingCenter registerForMessageName:@"ClearDeletedChat" target:self selector:@selector(snHandleMessageNamed:withUserInfo:)];
	return result;
}
%end

%hook CKConversationListController
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [[settings objectForKey:@"appIsOn"] boolValue])
	{
		CKConversationListCell *cell = (CKConversationListCell *)gesture.view;
		NSUInteger chosenRow = [(UITableView *)MSHookIvar<UITableView *>(self, "_table") indexPathForCell:((UITableViewCell *)cell)].row;
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
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
#ifdef DEBUG
		NSLog(@"SMSNinja: snLongPress:: chosenName = %@, chosenKeyword = %@", chosenName, chosenKeyword);
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
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [[settings objectForKey:@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
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
		NSString *address = [userInfo objectForKey:@"address"];
		NSNumber *result = [NSNumber numberWithBool:[address isInAddressBook]];
		return @{@"result" : result};
	}
	else if ([name isEqualToString:@"GetAddressBookName"])
	{
		NSString *address = [userInfo objectForKey:@"address"];
		NSString *result = [address nameInAddressBook];
		return @{@"result" : result};
	}
	else if ([name isEqualToString:@"SendMessage"])
	{
		NSString *text = [userInfo objectForKey:@"text"];
		NSString *address = [userInfo objectForKey:@"address"];
		[[SNTelephonyManager sharedManager] sendMessageWithText:text address:address];
	}
	else if ([name isEqualToString:@"LaunchMobilePhone"])
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
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
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
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
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
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
		IMChat *chat = [[%c(IMChatRegistry) sharedInstance] existingChatWithChatIdentifier:(NSString *)[userInfo objectForKey:@"chatID"]];
		[chat leave];
	}
	else if ([name isEqualToString:@"RemoveIconFromSwitcher"])
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) [[%c(SBAppSwitcherController) sharedInstance] _removeApplicationFromRecents:[[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:@"com.naken.smsninja"]];
		else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) [[%c(SBAppSwitcherModel) sharedInstance] remove:@"com.naken.smsninja"];
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
	if ([fileManager fileExistsAtPath:@"/var/mobile/Library/SMSNinja/UnreadPrivateInfo"] && [[settings objectForKey:@"appIsOn"] boolValue] && [[settings objectForKey:@"shouldShowPurpleSquare"] boolValue]) ShowPurpleSquare();
}
%end

%hook CTCallCenter
- (void)handleNotificationFromConnection:(void *)arg1 ofType:(id)arg2 withInfo:(NSDictionary *)arg3 // outgoing call
{
	// TODO: iOS 8的进程变成了SpringBoard
	%orig;
	if ([(NSNumber *)[arg3 objectForKey:@"kCTCallStatus"] intValue] == 3 && ((kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1 && [[[NSProcessInfo processInfo] processName] isEqualToString:@"MobilePhone"]) || (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1 && [[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])))
	{
		NSLog(@"SMSNinjaDebug2.5: userInfo = %@, %@, %@", arg3, [arg3 objectForKey:@"kCTCallStatus"], [[NSProcessInfo processInfo] processName]);
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1 && [[arg3 description] rangeOfString:@"status = 196608"].location != NSNotFound) return; // this is dirty on iOS 7 :(

		CTCallRef call = (CTCallRef)[arg3 objectForKey:@"kCTCall"];
		NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
		NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		NSArray *addressArray = @[tempAddress];	
		[address release];
#ifdef DEBUG
		NSLog(@"SMSNinja: handleNotificationFromConnection:ofType:withInfo:: addressArray = %@", addressArray);
#endif
		switch (ActionOfAudioFunctionWithInfo(addressArray, YES))
		{
			default:
				// take a rest!
				break;
		}
	}
}
%end

%hook IMAVTelephonyManager
- (void)_chatStateChanged:(NSConcreteNotification *)arg1 // outgoing FaceTime
{
	// TODO: 进出都可以在这里处理？
	%orig;
	IMAVChat *avChat = nil; // 5_6_7
	IMAVChatProxy *avChatProxy = nil; // 8
	if ( (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1 && [avChat state] == 3) || (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && [avChat state] == 2) ) // 5: 3 for outgoing/waiting, 6 for ended, 2 for incoming/invited; 6_7_8: 2 for outgoing/waiting, 5 for ended, 1 for incoming/invited
	{
		NSMutableArray *otherParticipants = [NSMutableArray arrayWithCapacity:6];
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
		{
			avChat = [arg1 object];
			[otherParticipants addObjectsFromArray:[avChat participants]];
			[otherParticipants removeObject:[avChat localParticipant]];
			for (IMAVChatParticipant *participant in otherParticipants)
			{
				IMHandle *handle = [participant imHandle];
				NSString *address = [handle normalizedID];
				address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
				[addressArray addObject:address];
			}
		}
		else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1)
		{
			avChatProxy = [arg1 object];
			for (IMAVChatParticipantProxy *participantProxy in [avChatProxy remoteParticipants])
			{
				avChat = [participantProxy avChat];
				[otherParticipants addObjectsFromArray:[avChat participants]];
				[otherParticipants removeObject:[avChat localParticipant]];
				for (IMAVChatParticipant *participant in otherParticipants)
				{
					IMHandle *handle = [participant imHandle];
					NSString *address = [handle normalizedID];
					address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
					[addressArray addObject:address];
				}
			}
		}
#ifdef DEBUG
		NSLog(@"SMSNinja: _chatStateChanged:: addressArray = %@", addressArray);
#endif
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
	// TODO: Not called in SpringBoard in iOS 8
	%orig;
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) message = (FZMessage *)message;
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1) message = (IMMessageItem *)message;
	
	if (![message isFinished]) return;
	NSArray *transferGUIDArray = [message fileTransferGUIDs];
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [transferGUIDArray count] == 0) // handles text only messages
	{
		IMChat *chat = [self existingChatWithChatIdentifier:chatID];
		NSArray *handleArray = chat.participants;
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];	
		for (IMHandle *handle in handleArray)
		{
			NSString *address = handle.displayID;
			NSLog(@"SMSNinjaDebug2: address = %@", address);
			address = [address stringByReplacingOccurrencesOfString:@"\u202a" withString:@""];
			address = [address stringByReplacingOccurrencesOfString:@"\u202c" withString:@""];
			address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[addressArray addObject:address];
		}

		NSString *text = [[message body] string];
		text = [text length] == 0 ? @" " : text;

		NSMutableArray *pictureArray = [NSMutableArray array];
#ifdef DEBUG
		NSLog(@"SMSNinja: account:chat:style:chatProperties:messageSent:: addressArray = %@, text = %@, with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);
#endif
		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			BOOL success = NO;
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromFZMessage:message sender:(NSString *)[message sender] subject:[message subject]];
				IMChatItem *chatItem = [chat chatItemForMessage:imMessage];
				success = [chat deleteChatItem:chatItem];
			}
			else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromIMMessageItem:message sender:(NSString *)[message sender] subject:[message subject]];
				NSArray *chatItems = [chat chatItemsForMessages:@[imMessage]];
				[chat deleteChatItems:chatItems];
			}

			if (![chat lastMessage] || !success)
			{
				[chat leave];
				CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.mobilesms"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : chatID}];
			}
		}
	}
	else if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"MobileSMS"] && [transferGUIDArray count] > 0) // handles messages with attachments
	{
		IMChat *chat = [self existingChatWithChatIdentifier:chatID];
		NSArray *handleArray = chat.participants;
		NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:6];	
		for (IMHandle *handle in handleArray)
		{
			NSString *address = handle.displayID;
			address = [address stringByReplacingOccurrencesOfString:@"\u202a" withString:@""];
			address = [address stringByReplacingOccurrencesOfString:@"\u202c" withString:@""];
			address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[addressArray addObject:address];
		}

		NSString *text = [[message body] string];
		text = [text length] == 0 ? @" " : text;

		NSMutableArray *pictureArray = [NSMutableArray array];
		for (NSString *transferGUID in [message fileTransferGUIDs])
		{
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[[%c(IMFileTransferCenter) sharedInstance] transferForGUID:transferGUID] localPath]];
			[pictureArray addObject:image];
			[image release];
		}
#ifdef DEBUG
		NSLog(@"SMSNinja: account:chat:style:chatProperties:messageSent:: bundle = %@, addressArray = %@, text = %@, with %lu attachments", [[NSBundle mainBundle] bundleIdentifier], addressArray, text, (unsigned long)[pictureArray count]);
#endif
		if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, YES) == 1)
		{
			BOOL success = NO;
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromFZMessage:message sender:(NSString *)[message sender] subject:[message subject]];
				IMChatItem *chatItem = [chat chatItemForMessage:imMessage];
				success = [chat deleteChatItem:chatItem];
			}
			else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1)
			{
				IMMessage *imMessage = [%c(IMMessage) messageFromIMMessageItem:message sender:(NSString *)[message sender] subject:[message subject]];
				NSArray *chatItems = [chat chatItemsForMessages:@[imMessage]];
				[chat deleteChatItems:chatItems];
			}

			if (![chat lastMessage] || !success)
			{
				[chat leave];
				CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.mobilesms"];
				[messagingCenter sendMessageName:@"ClearDeletedChat" userInfo:@{@"chatID" : chatID}];
			}
		}
	}
}
%end

%group SNIncomingCallHook_5_6_7

%hook MPConferenceManager // 5_6_7
- (void)_handleInvitation:(NSConcreteNotification *)invitation // incoming FaceTime
{
	// TODO: 用IMAVController替换？
	NSString *address = nil;
	NSMutableArray *addressArray = [NSMutableArray arrayWithCapacity:1];
	NSString *conferenceID = nil;
	NSURL *inviter = nil; // 5
	IMHandle *handle = nil; // 6_7
	IMAVChatProxy *chatProxy = nil; // 7
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		inviter = [[invitation userInfo] objectForKey:@"kCNFConferenceControllerInviterKey"];
		conferenceID = [[invitation userInfo] objectForKey:@"kCNFConferenceControllerConferenceIDKey"];	
		address = [inviter absoluteString];
		if ([address hasPrefix:@"facetime://"])
			address = [[address substringFromIndex:11] normalizedPhoneNumber];
		[addressArray addObject:address];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		handle = [[invitation userInfo] objectForKey:@"kCNFConferenceControllerHandleKey"];
		conferenceID = [[invitation userInfo] objectForKey:@"kCNFConferenceControllerConferenceIDKey"];
		address = [handle normalizedID];
		address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[addressArray addObject:address];
	}
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
	{
		chatProxy = [invitation object];
		handle = [chatProxy otherIMHandle];
		NSString *address = [handle normalizedID];
		address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[addressArray addObject:address];
	}
#ifdef DEBUG
	NSLog(@"SMSNinja: _handleInvitation:: address = %@", address);
#endif
	switch (ActionOfAudioFunctionWithInfo(addressArray, NO))
	{
		case 0:
			%orig;
			break;
		case 1:
			if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) [[self conferenceController] rejectFaceTimeInvitationFrom:inviter conferenceID:conferenceID];
			else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) [[self conferenceController] declineFaceTimeInvitationForConferenceID:conferenceID fromHandle:handle];			
			else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) [chatProxy declineInvitation];
			break;
		case 2:
			break;
		case 3:
			%orig;
			break;
	}
}
%end

%end // end of SNIncomingCallHook_5_6_7

%group SNIncomingCallHook_5_6_7_8

%hook MPTelephonyManager
- (void)displayAlertForCall:(id)arg1 // incoming call
{
	CTCallRef call = nil;
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) call = (CTCallRef)arg1;
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1) call = [(TUTelephonyCall *)arg1 call];
	NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
	NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	NSArray *addressArray = @[tempAddress];	
	[address release];
#ifdef DEBUG
	NSLog(@"SMSNinja: displayAlertForCall:: address = %@", tempAddress);
#endif
	switch (ActionOfAudioFunctionWithInfo(addressArray, NO))
	{
		case 0:
			%orig;
			break;
		case 1:
			%orig(nil);
			CTCallDisconnect(call);
			break;
		case 2:
			%orig(nil);
			break;
		case 3:
			%orig;
			break;
	}
}
%end

%end // end of SNIncomingCallHook_5_6_7_8

%hook SBPluginManager
- (Class)loadPluginBundle:(NSBundle *)bundle
{
	Class result = %orig;
	NSString *bundleIdentifier = [bundle bundleIdentifier];
	if ([bundleIdentifier isEqualToString:@"com.apple.mobilephone.incomingcall"])
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) %init(SNIncomingCallHook_5_6_7);
		%init(SNIncomingCallHook_5_6_7_8);
	}
	return result;
}
%end

%group SNIncomingMessageHook_5_6_7_8

%hook IMDServiceSession
- (void)didReceiveMessage:(id)message forChat:(NSString *)arg2 style:(unsigned char)arg3 // incoming iMessage_5/message_6_7_8
{	
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) message = (FZMessage *)message;
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_1) message = (IMMessageItem *)message;

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
		NSMutableArray *pictureArray = [NSMutableArray arrayWithCapacity:[transferGUIDArray count]];
		for (NSString *transferGUID in transferGUIDArray)
		{
			UIImage *image = [[UIImage alloc] initWithContentsOfFile:[[center transferForGUID:transferGUID] localPath]];
			[pictureArray addObject:image];
			[image release];
		}
#ifdef DEBUG
		NSLog(@"SMSNinja: didReceiveMessage:forChat:style:: address = %@, text = %@, with %lu attachments", sender, text, (unsigned long)[pictureArray count]);
#endif
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
				if ([store respondsToSelector:@selector(deleteChatWithGUID:)])
				{
					if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
					{
						static NSThread *(*IMDPersistenceDatabaseThread)(void);	
						void *libHandle = dlopen("/System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence", RTLD_LAZY);
						IMDPersistenceDatabaseThread = (NSThread *(*)(void))dlsym(libHandle, "IMDPersistenceDatabaseThread");
						[store performSelector:@selector(deleteChatWithGUID:) onThread:IMDPersistenceDatabaseThread() withObject:[chat guid] waitUntilDone:YES];
						dlclose(libHandle);
					}
					else [store deleteChatWithGUID:[chat guid]];
				}
				else if ([store respondsToSelector:@selector(deleteChat:)])
				{
					if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
					{
						static NSThread *(*IMDPersistenceDatabaseThread)(void);	
						void *libHandle = dlopen("/System/Library/PrivateFrameworks/IMDPersistence.framework/IMDPersistence", RTLD_LAZY);
						IMDPersistenceDatabaseThread = (NSThread *(*)(void))dlsym(libHandle, "IMDPersistenceDatabaseThread");
						[store performSelector:@selector(deleteChat:) onThread:IMDPersistenceDatabaseThread() withObject:chat waitUntilDone:YES];
						dlclose(libHandle);
					}
					else [store deleteChat:chat];
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
		CTCallRef call = (CTCallRef)[info objectForKey:@"kCTCall"];
		if (!CTCallIsOutgoing(call))
		{
			NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
			NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[address release];
#ifdef DEBUG
			NSLog(@"SMSNinja: _handleRecentCallNotification:userInfo: address = %@", tempAddress);
#endif
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
			else if ([tempAddress isInAddressBook] && [[settings objectForKey:@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
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
		CTCallRef call = (CTCallRef)[info objectForKey:@"kCTCall"];
		if (!CTCallIsOutgoing(call))
		{
			NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
			NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
			[address release];
#ifdef DEBUG
			NSLog(@"SMSNinja: _handleRecentCallNotification:userInfo: address = %@", tempAddress);
#endif
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
			else if ([tempAddress isInAddressBook] && [[settings objectForKey:@"shouldIncludeContactsInWhitelist"] boolValue])
			{
			}
			else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
		}
	}
	%orig;
}
%end

%end // end of SNBulletinHook_7

%group SNBulletinHook_8

%hook MPBBDataProvider
- (void)_handleCallHistoryDatabaseChangedNotification:(id)arg1
{
	CHManager *recentsManager = MSHookIvar<CHManager *>(self, "_recentsManager");
	CHRecentCall *recentCall = recentsManager.recentCalls[0];
	if (!recentCall.read)
	{
		NSString *address = recentCall.callerId;
		NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
		[address release];
#ifdef DEBUG
		NSLog(@"SMSNinja: _handleCallHistoryDatabaseChangedNotification: address = %@", tempAddress);
#endif
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
		else if ([tempAddress isInAddressBook] && [[settings objectForKey:@"shouldIncludeContactsInWhitelist"] boolValue])
		{
		}
		else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) return;
		%orig;
	}
	else %orig;
}
%end

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
#ifdef DEBUG
	NSLog(@"SMSNinja: _ingestIncomingCTMessage:: address = %@, text = %@, with %lu attachments", address, text, (unsigned long)[pictureArray count]);
#endif
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
#ifdef DEBUG
		NSLog(@"SMSNinja: _sentMessage:: addressArray = %@, text = %@, with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);
#endif
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
#ifdef DEBUG
		NSLog(@"SMSNinja: _sentMessage:: addressArray = %@, text = %@, with %lu attachments", addressArray, text, (unsigned long)[pictureArray count]);
#endif
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
	if (gesture.state == UIGestureRecognizerStateBegan && [[settings objectForKey:@"appIsOn"] boolValue])
	{
		NSUInteger chosenRow = [[self table] indexPathForCell:((UITableViewCell *)gesture.view)].row;
		id call = nil;
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) call = [self calls][chosenRow];
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
		NSLog(@"SMSNinja: snLongPress:: chosenName = %@, chosenKeyword = %@", chosenName, chosenKeyword);
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
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [[settings objectForKey:@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
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

%hook PhoneApplication
- (BOOL)dialPhoneNumber:(NSString *)arg1 dialAssist:(BOOL)arg2
{
	NSString *number = [arg1 normalizedPhoneNumber];
#ifdef DEBUG
	NSLog(@"SMSNinja: dialPhoneNumber:dialAssist:: number = %@", number);
#endif
	if ( ([[settings objectForKey:@"appIsOn"] boolValue] && [number isEqualToString:[settings objectForKey:@"launchCode"]]) || ([[settings objectForKey:@"shouldHideIcon"] boolValue] && [[settings objectForKey:@"launchCode"] length] == 0 && [number isEqualToString:@"666666"]) )
	{
		PhoneTabBarController *tabBarController = [self currentViewController];
		DialerController *dialerController = tabBarController.keypadViewController;
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
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
		else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1)
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

%end // end of SNGeneralHook_5_6_7

%group SNGeneralHook_7_8

%hook PHRecentsViewController
%new
- (void)snLongPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan && [[settings objectForKey:@"appIsOn"] boolValue])
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
#ifdef DEBUG
		NSLog(@"SMSNinja: snLongPress:: chosenName = %@, chosenKeyword = %@", chosenName, chosenKeyword);
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
		if ([chosenKeyword indexInPrivateListWithType:0] == NSNotFound && [[settings objectForKey:@"shouldRevealPrivatelistOutsideSMSNinja"] boolValue]) [snActionSheet addButtonWithTitle:NSLocalizedStringFromTableInBundle(@"Add to Privatelist", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];
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

%hook IMDaemonController // grant SpringBoard permission to send messages :P
- (BOOL)addListenerID:(id)arg1 capabilities:(unsigned)arg2
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"] && [arg1 isEqualToString:@"com.apple.MobileSMS"])
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) return %orig(arg1, 16647);
		else return %orig(arg1, 393216);
	}
	return %orig;
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

%end // end of SNGeneralHook_7

%group SNGeneralHook_8

%hook PhoneApplication
- (BOOL)openURL:(NSURL *)arg1 // should be something like tel://10010?suppressAssist=1&originatingUI=dialer
{
	NSString *number = [arg1 absoluteString];
	if (![number hasPrefix:@"tel://"]) return %orig;

	NSUInteger location = [number rangeOfString:@"?"].location;
	number = [number substringWithRange:NSMakeRange(6, location - 6)];
	number = [number normalizedPhoneNumber];
#ifdef DEBUG
	NSLog(@"SMSNinja: openURL:: number = %@", number);
#endif
	if ( ([[settings objectForKey:@"appIsOn"] boolValue] && [number isEqualToString:[settings objectForKey:@"launchCode"]]) || ([[settings objectForKey:@"shouldHideIcon"] boolValue] && [[settings objectForKey:@"launchCode"] length] == 0 && [number isEqualToString:@"666666"]) )
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

%end // end of SNGeneralHook_8

%ctor
{
	@autoreleasepool
	{
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0)
		{
			MSHookFunction(&CTTelephonyCenterAddObserver, &new_CTTelephonyCenterAddObserver, &old_CTTelephonyCenterAddObserver);
			%init;
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) %init(SNGeneralHook_5);
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1) %init(SNGeneralHook_5_6);
			if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) %init(SNGeneralHook_5_6_7);
			if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_6_1)
			{
				MSHookFunction(&CMFBlockListIsItemBlocked, &new_CMFBlockListIsItemBlocked, &old_CMFBlockListIsItemBlocked);
				%init(SNGeneralHook_7_8);
				if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) %init(SNGeneralHook_7);
				else %init(SNGeneralHook_8);
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
