#import <objc/runtime.h>
#import "SNTelephonyManager.h"

static SNTelephonyManager *sharedManager;

@implementation SNTelephonyManager
+ (void)initialize
{
	if (self == [SNTelephonyManager class]) sharedManager = [[self alloc] init];
}

+ (id)sharedManager
{
	return sharedManager;
}

- (int)iMessageAvailabilityOfAddress:(NSString *)address
{
	if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) return [[objc_getClass("CKMadridService") sharedMadridService] availabilityForAddress:address checkWithServer:YES];
	else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_7_1) return [[objc_getClass("CKPreferredServiceManager") sharedPreferredServiceManager] availabilityForAddress:address onService:[objc_getClass("IMService") iMessageService] checkWithServer:YES];
	else
	{
		NSString *formattedAddress = @"";
		if ([address rangeOfString:@"@"].location == NSNotFound) formattedAddress = [@"tel:" stringByAppendingString:address];
		else formattedAddress = [@"mailto:" stringByAppendingString:address];
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
				CKMadridEntity *madridEntity = [madridService copyEntityForAddressString:address];
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
		CKIMEntity *imEntity = [objc_getClass("CKIMEntity") copyEntityForAddressString:address];
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
		CKEntity *entity = [objc_getClass("CKEntity") copyEntityForAddressString:address];			
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
		IMDaemonController *controller = [objc_getClass("IMDaemonController") sharedController];
		CKEntity *entity = [objc_getClass("CKEntity") copyEntityForAddressString:address];
		IMHandle *handle = [entity handle];
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		IMChat *chat = [[objc_getClass("IMChatRegistry") sharedInstance] existingChatForIMHandle:handle];
		CKConversation *conversation = [conversationList conversationForExistingChat:chat];
		if (!conversation) conversation = [conversationList conversationForHandles:@[handle] create:YES];
		if ([conversation _iMessage_canSendToRecipients:@[entity] alertIfUnable:NO] && controller.isConnected)
		{
			NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
			CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
			IMMessage *imMessage = [conversation messageWithComposition:composition];
			[conversation sendMessage:imMessage onService:[objc_getClass("IMService") iMessageService] newComposition:NO];
			[attributedString release];
			[composition release];
		}
		[entity release];
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
			CKSMSEntity *smsEntity = [smsService copyEntityForAddressString:address];
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
			CKIMEntity *imEntity = [objc_getClass("CKIMEntity") copyEntityForAddressString:address];			
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
			CKEntity *entity = [objc_getClass("CKEntity") copyEntityForAddressString:address];			
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
		CKEntity *entity = [objc_getClass("CKEntity") copyEntityForAddressString:address];
		IMHandle *handle = [entity handle];
		CKConversationList *conversationList = [objc_getClass("CKConversationList") sharedConversationList];
		IMChat *chat = [[objc_getClass("IMChatRegistry") sharedInstance] existingChatForIMHandle:handle];
		CKConversation *conversation = [conversationList conversationForExistingChat:chat];
		if (!conversation) conversation = [conversationList conversationForHandles:@[handle] create:YES];
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text];
		CKComposition *composition = [[objc_getClass("CKComposition") alloc] initWithText:attributedString subject:nil];
		IMMessage *imMessage = [conversation messageWithComposition:composition];
		[conversation sendMessage:imMessage onService:[objc_getClass("IMService") smsService] newComposition:NO];
		[attributedString release];
		[composition release];
		[entity release];
	}
}

- (void)sendMessageWithText:(NSString *)text address:(NSString *)address
{
	if ([[[NSProcessInfo processInfo] processName] isEqualToString:@"SpringBoard"])
	{
		if ([self iMessageAvailabilityOfAddress:address] == 1) [self sendIMessageWithText:text address:address];
		else [self sendSMSWithText:text address:address];
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
