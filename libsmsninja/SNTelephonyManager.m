#import <objc/runtime.h>
#import "SNTelephonyManager.h"

static SNTelephonyManager *sharedManager;

@implementation SNTelephonyManager
+ (void)initialize
{
	if (self == [SNTelephonyManager class]) sharedManager = [[self alloc] init];
}

+ (instancetype)sharedManager
{
	return sharedManager;
}

- (int)iMessageAvailabilityOfAddress:(NSString *)address
{
	NSString *lowercaseAddress = [address lowercaseString];
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) return [[objc_getClass("CKMadridService") sharedMadridService] availabilityForAddress:lowercaseAddress checkWithServer:YES];
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) return [[objc_getClass("CKPreferredServiceManager") sharedPreferredServiceManager] availabilityForAddress:lowercaseAddress onService:[objc_getClass("IMService") iMessageService] checkWithServer:YES];
	else
	{
		NSString *formattedAddress = @"";
		if ([lowercaseAddress rangeOfString:@"@"].location == NSNotFound) formattedAddress = [@"tel:" stringByAppendingString:lowercaseAddress];
		else formattedAddress = [@"mailto:" stringByAppendingString:lowercaseAddress];
		return [[objc_getClass("IDSIDQueryController") sharedInstance] _refreshIDStatusForDestination:formattedAddress service:@"com.apple.madrid" listenerID:@"__kIMChatServiceForSendingIDSQueryControllerListenerID"];
	}
	return 0;
}

- (void)sendIMessageWithText:(NSString *)text address:(NSString *)address
{
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		CKMadridService *madridService = [objc_getClass("CKMadridService") sharedMadridService];
		if ([objc_getClass("CKMadridService") isConnectedToDaemon] && [objc_getClass("CKMadridService") isMadridEnabled] && [objc_getClass("CKMadridService") isMadridSupported] && [madridService isAvailable] && [madridService ensureMadridConnection] && [madridService canSendToRecipients:@[[madridService copyEntityForAddressString:address]] withAttachments:nil alertIfUnable:NO] && [madridService isValidAddress:address])
		{
			CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
			CKSubConversation *conversation = [conversationList existingConversationForAddresses:@[address]];
			if (!conversation)
			{
				CKMadridEntity *madridEntity = (CKMadridEntity *)[madridService copyEntityForAddressString:address];
				conversation = [conversationList conversationForRecipients:@[madridEntity] create:YES service:madridService];
				[madridEntity release];
			}
			CKMessageStandaloneComposition *composition = [objc_getClass("CKMessageStandaloneComposition") newCompositionForText:text];	
			CKMadridMessage *madridMessage = [madridService newMessageWithComposition:composition forConversation:conversation];
			[madridService sendMessage:madridMessage];
			[composition release];
			[madridMessage release];
		}
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		IMDaemonController *controller = [objc_getClass("IMDaemonController") sharedController];
		CKIMEntity *imEntity = (CKIMEntity *)[objc_getClass("CKIMEntity") copyEntityForAddressString:address];
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		CKConversation *conversation = [conversationList conversationForExistingChatWithAddresses:@[address]];
		if (!conversation) conversation = [conversationList conversationForRecipients:@[imEntity] create:YES];
		if ([conversation _iMessage_canSendToRecipients:@[imEntity] withAttachments:nil alertIfUnable:NO] && controller.isConnected)
		{
			CKMessageComposition *composition = [objc_getClass("CKMessageComposition") newCompositionForText:text];	
			CKIMMessage *imMessage = [conversation newMessageWithComposition:composition];
			[conversation sendMessage:imMessage onService:[objc_getClass("IMService") iMessageService] newComposition:NO];
			[composition release];
			[imMessage release];
		}
		[imEntity release];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
	{
		IMDaemonController *controller = [objc_getClass("IMDaemonController") sharedController];
		CKEntity *entity = (CKEntity *)[objc_getClass("CKEntity") copyEntityForAddressString:address];			
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		CKConversation *conversation = [conversationList conversationForExistingChatWithAddresses:@[address]];
		if (!conversation) conversation = [conversationList conversationForRecipients:@[entity] create:YES];
		if ([conversation _iMessage_canSendToRecipients:@[entity] withAttachments:nil alertIfUnable:NO] && controller.isConnected)
		{
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
			CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
			CKIMMessage *imMessage = [conversation newMessageWithComposition:composition];
			[conversation sendMessage:imMessage onService:[objc_getClass("IMService") iMessageService] newComposition:NO];
			[attributedString release];
			[composition release];
			[imMessage release];
		}
		[entity release];
	}
	else
	{
		IMAccountController *accountController = [objc_getClass("IMAccountController") sharedInstance];
		IMAccount *account = [accountController bestAccountForService:[objc_getClass("IMServiceImpl") iMessageService]];
		if (!account) NSLog(@"SMSNinja: Failed to send iMessage because we can't find a valid iMessage account.");
		else
		{
			if (![account isActive] || ![account isConnected] || ![account isOperational]) [accountController activateAccount:account];
			if ([account isActive] && [account isConnected] && [account isOperational])
			{
				CKEntity *entity = [objc_getClass("CKEntity") _copyEntityForAddressString:address onAccount:account];
				IMHandle *handle = [entity handle];
				IMChat *chat = [[objc_getClass("IMChatRegistry") sharedInstance] chatForIMHandle:handle];
				CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
				CKConversation *conversation = [conversationList conversationForExistingChat:chat];
				if (!conversation) conversation = [conversationList conversationForHandles:@[handle] create:YES];
				if ([conversation _iMessage_canSendToRecipients:@[entity] alertIfUnable:NO] && ((IMDaemonController *)[objc_getClass("IMDaemonController") sharedController]).isConnected)
				{
					NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
					CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
					IMMessage *imMessage = [conversation messageWithComposition:composition];
					[conversation sendMessage:imMessage newComposition:NO];
					[attributedString release];
					[composition release];
					[entity release];
				}
				else NSLog(@"SMSNinja: Failed to send iMessage because iMessage is broken.");
			}
			else NSLog(@"SMSNinja: Failed to send iMessage because we can't find a valid iMessage account.");
		}
	}
}

- (void)sendSMSWithText:(NSString *)text address:(NSString *)address
{
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
	{
		CKSMSService *smsService = [objc_getClass("CKSMSService") sharedSMSService];
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		CKSubConversation *conversation = [conversationList existingConversationForAddresses:@[address]];
		if (!conversation)
		{
			CKSMSEntity *smsEntity = (CKSMSEntity *)[smsService copyEntityForAddressString:address];
			conversation = [conversationList conversationForRecipients:@[smsEntity] create:YES service:smsService];
			[smsEntity release];
		}
		CKSMSMessage *smsMessage = [smsService _newSMSMessageWithText:text forConversation:conversation];
		[smsService sendMessage:smsMessage];
		[smsMessage release];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_6_1)
	{
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		CKConversation *conversation = [conversationList conversationForExistingChatWithAddresses:@[address]];
		if (!conversation)
		{
			CKIMEntity *imEntity = (CKIMEntity *)[objc_getClass("CKIMEntity") copyEntityForAddressString:address];			
			conversation = [conversationList conversationForRecipients:@[imEntity] create:YES];
			[imEntity release];
		}
		CKMessageComposition *composition = [objc_getClass("CKMessageComposition") newCompositionForText:text];	
		CKIMMessage *imMessage = [conversation newMessageWithComposition:composition];
		[conversation sendMessage:imMessage onService:[objc_getClass("IMService") smsService] newComposition:NO];
		[composition release];
		[imMessage release];
	}
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1)
	{
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		CKConversation *conversation = [conversationList conversationForExistingChatWithAddresses:@[address]];
		if (!conversation)
		{
			CKEntity *entity = (CKEntity *)[objc_getClass("CKEntity") copyEntityForAddressString:address];			
			conversation = [conversationList conversationForRecipients:@[entity] create:YES];
			[entity release];
		}
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
		CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
		CKIMMessage *imMessage = [conversation newMessageWithComposition:composition];
		[conversation sendMessage:imMessage onService:[objc_getClass("IMService") smsService] newComposition:NO];
		[attributedString release];
		[composition release];
		[imMessage release];
	}
	else
	{
		IMAccountController *accountController = [objc_getClass("IMAccountController") sharedInstance];
		IMAccount *account = [accountController bestAccountForService:[objc_getClass("IMServiceImpl") smsService]];
		if (!account) NSLog(@"SMSNinja: Failed to send SMS because we can't find a valid SMS account.");
		else
		{
			if (![account isActive] || ![account isConnected] || ![account isOperational]) [accountController activateAccount:account];
			if ([account isActive] && [account isConnected] && [account isOperational])
			{
				CKEntity *entity = [objc_getClass("CKEntity") _copyEntityForAddressString:address onAccount:account];
				IMHandle *handle = [entity handle];
				IMChat *chat = [[objc_getClass("IMChatRegistry") sharedInstance] chatForIMHandle:handle];
				CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
				CKConversation *conversation = [conversationList conversationForExistingChat:chat];
				if (!conversation) conversation = [conversationList conversationForHandles:@[handle] create:YES];
				NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
				CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
				IMMessage *imMessage = [conversation messageWithComposition:composition];
				[conversation sendMessage:imMessage newComposition:NO];
				[attributedString release];
				[composition release];
				[entity release];
			}
			else NSLog(@"SMSNinja: Failed to send SMS because we can't find a valid SMS account.");
		}
	}
}

- (void)sendMessageWithText:(NSString *)text address:(NSString *)address
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])
	{
		if ([self iMessageAvailabilityOfAddress:address] == 1)
		{
			[self sendIMessageWithText:text address:address];
			NSLog(@"SMSNinja: Send %@ to %@ as iMessage.", text, address);
		}
		else
		{
			[self sendSMSWithText:text address:address];
			NSLog(@"SMSNinja: Send %@ to %@ as SMS.", text, address);
		}
	}
	else
	{
		CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
		[messagingCenter sendMessageName:@"SendMessage" userInfo:@{@"address" : address, @"text" : text}];
	}
}

- (void)reply:(NSString *)address with:(NSString *)text
{
	[self sendMessageWithText:text address:address];
}

- (void)forward:(NSString *)text to:(NSString *)address
{
	[self sendMessageWithText:text address:address];
}
@end
