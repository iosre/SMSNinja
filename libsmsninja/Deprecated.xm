#import <AddressBook/AddressBook.h>
#include <dlfcn.h>

%hook SpringBoard
%new
- (NSDictionary *)snCallHistory // integrate with stock MobilePhone
{
	static CFArrayRef (*_CTCallCopyAllCalls)(void);
	static CFStringRef (*CTCallCopyAddress)(CFAllocatorRef, CTCallRef);
	static BOOL (*CTCallGetStartTime)(CTCallRef, double *);
	static BOOL (*CTCallIsOutgoing)(CTCallRef);
	static CFStringRef (*CTCallCopyCountryCode)(CFAllocatorRef, CTCallRef);
	static CFStringRef (*UICountryCodeForInternationalCode)(CFStringRef);

	static ABRecordRef (*ABAddressBookFindPersonMatchingEmailAddress)(ABAddressBookRef addressbook, CFStringRef email, int *unknown);
	static ABRecordRef (*ABAddressBookFindPersonMatchingPhoneNumber)(ABAddressBookRef addressbook, CFStringRef number, int *unknown, int zero);
	static ABRecordRef (*ABAddressBookFindPersonMatchingPhoneNumberWithCountry)(ABAddressBookRef addressbook, CFStringRef address, CFStringRef isoCountryCode, int *unknown, int zero);

	void *libHandle1 = dlopen("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_LAZY);
	_CTCallCopyAllCalls = (CFArrayRef (*)(void))dlsym(libHandle1, "_CTCallCopyAllCalls");
	CTCallCopyAddress = (CFStringRef (*)(CFAllocatorRef, CTCallRef))dlsym(libHandle1, "CTCallCopyAddress");
	CTCallGetStartTime = (BOOL (*)(CTCallRef, double *))dlsym(libHandle1, "CTCallGetStartTime");
	CTCallIsOutgoing = (BOOL (*)(CTCallRef))dlsym(libHandle1, "CTCallIsOutgoing");
	CTCallCopyCountryCode = (CFStringRef (*)(CFAllocatorRef, CTCallRef))dlsym(libHandle1, "CTCallCopyCountryCode");

	void *libHandle2 = dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_LAZY);
	UICountryCodeForInternationalCode = (CFStringRef (*)(CFStringRef))dlsym(libHandle2, "UICountryCodeForInternationalCode");

	void *libHandle3 = dlopen("/System/Library/Frameworks/AddressBook.framework/AddressBook", RTLD_LAZY);
	ABAddressBookFindPersonMatchingEmailAddress = (ABRecordRef (*)(ABAddressBookRef, CFStringRef, int *))dlsym(libHandle3, "ABAddressBookFindPersonMatchingEmailAddress");
	ABAddressBookFindPersonMatchingPhoneNumber = (ABRecordRef (*)(ABAddressBookRef, CFStringRef, int *, int))dlsym(libHandle3, "ABAddressBookFindPersonMatchingPhoneNumber");
	ABAddressBookFindPersonMatchingPhoneNumberWithCountry = (ABRecordRef (*)(ABAddressBookRef, CFStringRef, CFStringRef, int *, int))dlsym(libHandle3, "ABAddressBookFindPersonMatchingPhoneNumberWithCountry");

	NSMutableArray *nameArray = [NSMutableArray arrayWithCapacity:200];
	NSMutableArray *timeArray = [NSMutableArray arrayWithCapacity:200];
	NSMutableArray *numberArray = [NSMutableArray arrayWithCapacity:200];
	NSMutableArray *typeArray = [NSMutableArray arrayWithCapacity:200];
	CFArrayRef calls = _CTCallCopyAllCalls();
	for (CFIndex i = 0; i < CFArrayGetCount(calls); i++)
	{
		CTCallRef call = CFArrayGetValueAtIndex(calls, i);

		NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, call);
		[numberArray addObject:[address length] != 0 ? address : @""];

		ABAddressBookRef addressbook = ABAddressBookCreate();
		ABRecordRef record = nil;
		int unknown = INT_MAX;
		if ([address rangeOfString:@"@"].location == NSNotFound)
		{
			CFStringRef countryCode = CTCallCopyCountryCode(kCFAllocatorDefault, call);
			if (countryCode)
			{
				CFStringRef internationalCode = UICountryCodeForInternationalCode(countryCode);
				record = ABAddressBookFindPersonMatchingPhoneNumberWithCountry(addressbook, (CFStringRef)address, internationalCode, &unknown, 0);
				CFRelease(countryCode);
			}
			else record = ABAddressBookFindPersonMatchingPhoneNumber(addressbook, (CFStringRef)address, &unknown, 0);
		}
		else record = ABAddressBookFindPersonMatchingEmailAddress(addressbook, (CFStringRef)address, &unknown);
		if (record)
		{
			CFStringRef firstName = (CFStringRef)ABRecordCopyValue(record, kABPersonFirstNameProperty);
			CFStringRef lastName = (CFStringRef)ABRecordCopyValue(record, kABPersonLastNameProperty);
			[nameArray addObject:[[firstName ? (NSString *)firstName : @"" stringByAppendingString:@" "] stringByAppendingString:lastName ? (NSString *)lastName : @""]];
			if (firstName) CFRelease(firstName);
			if (lastName) CFRelease(lastName);
		}
		else
		{
			NSString *name = NSLocalizedStringFromTableInBundle(@"Stranger", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil);
			[nameArray addObject:name];
		}
		[address release];
		CFRelease(addressbook);

		BOOL isOutgoing = CTCallIsOutgoing(call);
		[typeArray addObject:NSLocalizedStringFromTableInBundle(isOutgoing ? @"outgoing" : @"incoming", @"Localizable", [NSBundle bundleWithPath:@"/Applications/SMSNinja.app"], nil)];

		double *startTime = (double *)malloc(sizeof(double));
		bzero(startTime, sizeof(double));
		CTCallGetStartTime(call, startTime);

		NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:*startTime];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
		[formatter setTimeZone:[NSTimeZone localTimeZone]];
		NSString *dateString = [formatter stringFromDate:date];
		[formatter release];
		[timeArray addObject:dateString];

		free(startTime);
	}
	CFRelease(calls);

	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:nameArray, @"nameArray", timeArray, @"timeArray", numberArray, @"numberArray", typeArray, @"typeArray", nil];

	dlclose(libHandle1);
	dlclose(libHandle2);
	dlclose(libHandle3);
}

%new
- (NSDictionary *)snMessageHistory // integrate with stock MobileSMS
{
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		for (id service in [%c(CKService) availableServices])
		{
			NSArray *messages = [service conversationSummaries:[NSMutableArray array] groupIDs:[NSMutableArray array] groupedRecipients:[NSMutableArray array]];
			// TODO: analyze messages
		}
	}
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		IMChatRegistry *registry = [IMChatRegistry sharedInstance];
		NSArray *chats = [registry allExistingChats];
		for (IMChat *chat in chats)
		{
			CKConversation *conversation = [[%c(CKConversationList) sharedConversationList] _beginTrackingConversationWithChat:chat];
			while ([conversation moreMessagesToLoad])
				[conversation loadMoreMessages];
			NSArray *messages = [conversation messages];
			for (CKIMMessage *message in messages)
			{
				IMMessage *imMessage = [message IMMessage];
				NSDate *date = [imMessage time];
				NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
				[formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
				NSString *dateString = [formatter stringFromDate:date];
				[formatter release];
				NSLog(@"ZYLDebug: date = %@, participants = %@, address = %@, text = %@", dateString, [[conversation chat] participants], [[imMessage subject] ID], [[imMessage text] string]);
			}
		}
	}
}
%end

%hook ICFCallServer
// - (void)_requestCallGrantForIdentifier:(id)arg1 forService:(id)arg2 waitForResponse:(BOOL)arg3 completionBlock:(void (^)(void))arg4
- (void)shouldAllowIncomingCallForNumber:(id)arg1 forService:(id)arg2 response:(void (^)(void))arg3
{
	// This is how iOS 7 blocks a call, but we can't get unknownXPCObject here plus call history is not added this way, so we handle it in SMSNinja's manner :)
	void (^customBlock)(void) = ^(void)
	{
		xpc_object_t xpcDictionary = xpc_dictionary_create_reply(unknownXPCObject);
		IMInsertBoolsToXPCDictionary(xpcDictionary, "response", NO, NULL);
		IMInsertBoolsToXPCDictionary(xpcDictionary, "isBlocked", YES, NULL);
		void *arg1 = (void *)((char *)xpcDictionary);
		void *arg2 = (void *)((char *)xpcDictionary + 1);
		xpc_connection_send_message(arg1, arg2);
		xpc_release(xpcDictionary);
	};

	%orig(arg1, arg2, customBlock);
}
%end

%hook PARecentsManager
- (void)callHistoryRecordAddedNotification:(CTCallRef)notification // delete call history on iOS 6
{
	%orig;

	NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, notification);
	NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	[address release];
#ifdef DEBUG
	NSLog(@"SMSNinja: callHistoryRecordAddedNotification:: address = %@", tempAddress);
#endif
	if ([[settings objectForKey:@"appIsOn"] boolValue])
	{
		BOOL shouldClearSpam = NO;
		int index = NSNotFound;
		if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
		{
			if ([[privatePhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES;
		}
		else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
		{
			if ([[blackPhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		}
		else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
		{
			if ([[blackPhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		}
		else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		if (shouldClearSpam) CTCallDeleteFromCallHistory(notification);
	}
}
%end

%hook PHRecentsManager
- (void)callHistoryRecordAddedNotification:(CTCallRef)notification // delete call history on iOS 7
{
	%orig;

	NSString *address = (NSString *)CTCallCopyAddress(kCFAllocatorDefault, notification);
	NSString *tempAddress = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	[address release];
#ifdef DEBUG
	NSLog(@"SMSNinja: callHistoryRecordAddedNotification:: address = %@", tempAddress);
#endif
	if ([[settings objectForKey:@"appIsOn"] boolValue])
	{
		BOOL shouldClearSpam = NO;
		int index = NSNotFound;
		if ((index = [tempAddress indexInPrivateListWithType:0]) != NSNotFound)
		{
			if ([[privatePhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES;
		}
		else if ((index = [tempAddress indexInBlackListWithType:0]) != NSNotFound)
		{
			if ([[blackPhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		}
		else if ((index = [CurrentTime() indexInBlackListWithType:2]) != NSNotFound)
		{
			if ([[blackPhoneArray objectAtIndex:index] intValue] != 0) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		}
		else if ((index = [tempAddress indexInWhiteListWithType:0]) == NSNotFound && ([[settings objectForKey:@"whitelistCallsOnlyWithBeep"] boolValue] || [[settings objectForKey:@"whitelistCallsOnlyWithoutBeep"] boolValue])) shouldClearSpam = YES & [[settings objectForKey:@"shouldClearSpam"] boolValue];
		if (shouldClearSpam) CTCallDeleteFromCallHistory(notification);
	}
}
%end

%group SNIncomingSMSHook_7

%hook SMSServiceSession
- (void)_processReceivedMessage:(CTMessage *)message // incoming SMS
{
	id sender = message.sender;
	NSString *address = @"";
	if ([sender respondsToSelector:@selector(digits)]) address = [sender digits];
	else if ([sender respondsToSelector:@selector(address)]) address = [sender address];
	address = [address length] == 0 ? @"" : [address normalizedPhoneNumber];
	NSArray *addressArray = [NSArray arrayWithObject:address];

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
	NSLog(@"SMSNinja: _processReceivedMessage:: address = %@, text = %@, with %lu attachments", address, text, (unsigned long)[pictureArray count]);
#endif
	if (ActionOfTextFunctionWithInfo(addressArray, text, pictureArray, NO) == 0) %orig;
}
%end

%end // end of SNIncomingSMSHook_7
