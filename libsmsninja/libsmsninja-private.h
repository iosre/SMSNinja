#import <CoreTelephony/CTCall.h>

// MobilePhone
typedef struct __CTCall* CTCallRef;

@interface CTCall (undocumented)
+ (CTCall *)callForCTCallRef:(CTCallRef)arg1;
@end

@interface RecentsViewController : UIViewController
- (id)table;
- (id)calls; // 5
- (id)callAtTableViewIndex:(int)tableViewIndex; // 6
@end

@interface PHRecentsViewController : UIViewController // 7
- (id)table;
- (id)callAtTableViewIndex:(int)tableViewIndex;
@end

@interface RecentCall : NSObject // 5_6
- (id)initWithCTCall:(CTCallRef)arg1;
- (void)deleteUnderlyingCTCall;
- (id)underlyingCTCalls;
@end

@interface PHRecentCall : NSObject // 7
- (id)callerDisplayName;
- (id)initWithCTCall:(CTCallRef)arg1;
- (void)deleteUnderlyingCTCall;
- (id)underlyingCTCalls;
@end

@interface RecentsTableViewCell : UITableViewCell // 5_6
@end

@interface PHStarkRecentsTableViewCell : UITableViewCell // 7
@end

@interface RecentsTableViewCellContentView : UIView
@property (copy, nonatomic) NSString *callerName;
@end

@interface PHRecentsCell : UITableViewCell // 7
{
	UILabel* _callerNameLabel;
	UILabel* _callerLabelLabel;
}
@property (nonatomic,retain) PHRecentCall * call;
@end

@interface PHRecentsManager : NSObject
- (void)reloadCallsArrayIfNecessary;
@end

@interface DialerLCDField : UIView // 5
- (void)setText:(NSString *)arg1 needsFormat:(BOOL)arg2;
- (NSString *)text;
@end

@interface DialerLCDView : UIView // 6
@property (retain, nonatomic) UILabel *numberLabel;
@end

@interface PHStarkDialerLCDView : UIView // 7
@property (retain) UILabel * mainNumberLabel;
@end

@interface DialerView : UIView
@property (readonly, nonatomic) DialerLCDField *lcd; // 5
@property (retain, nonatomic) DialerLCDView *lcdView; // 6
@end

@interface PHHandsetDialerNameLabelView : UIControl // 7
@property (retain) UILabel *nameAndLabelLabel;
@end

@interface PHHandsetDialerLCDView : UIView // 7
@property (retain) PHHandsetDialerNameLabelView *nameAndLabelView;
@property (nonatomic,retain) UILabel *numberLabel;                   
@end

@interface PHAbstractDialerView : UIView // 7
@property (nonatomic,retain) PHHandsetDialerLCDView *lcdView;
@end

@interface PHHandsetDialerView : PHAbstractDialerView
@end

@interface DialerController : UIViewController
@property (readonly) PHHandsetDialerView * dialerView; // 7
@end

@interface PhoneTabBarController : UITabBarController
@property (retain, nonatomic) DialerController *keypadViewController;
@end

@interface PhoneApplication : UIApplication
- (PhoneTabBarController *)currentViewController;
@end

// IMCore && IMDaemonCore
@interface IMFileTransfer : NSObject
@property (retain, nonatomic) NSString *localPath;
@end

@interface IMDFileTransferCenter : NSObject
+ (id)sharedInstance;
- (IMFileTransfer *)transferForGUID:(id)arg1;
@end

@interface FZMessage : NSObject
@property (readonly, assign, nonatomic) BOOL isFinished;
@property (readonly, nonatomic) BOOL isFromMe;
@property (retain, nonatomic) NSAttributedString *body;
@property (retain, nonatomic) NSArray *fileTransferGUIDs;
@property (retain, nonatomic) NSDate *time; // 5_6
@property (retain, nonatomic) NSDate *timePlayed; // 7
@property (retain, nonatomic) NSDate *timeDelivered; // 7
@property (retain, nonatomic) NSDate *timeRead; // 7
@property (retain, nonatomic) NSString *sender;
@property (retain, nonatomic) NSData *bodyData;
@property (retain, nonatomic) NSString *subject;
@end

@interface IMChatItem : NSObject
@end

@interface IMMessage : NSObject
+ (id)messageFromFZMessage:(FZMessage *)fzmessage sender:(NSString *)sender subject:(NSString *)subject;
+ (id)messageFromIMMessageItem:(id)arg1 sender:(NSString *)arg2 subject:(NSString *)arg3; // 8
@end

@interface IMChat : NSObject
@property (readonly, nonatomic) NSArray *participants;
@property (readonly, assign, nonatomic) IMMessage* lastMessage;
- (IMChatItem *)chatItemForMessage:(IMMessage *)message;
- (NSArray *)chatItemsForMessages:(id)arg1; // 8
- (void)leave;
- (BOOL)deleteChatItem:(id)item;
- (void)deleteChatItems:(id)arg1; // 8
@end

@interface IMChatRegistry : NSObject
+ (id)sharedInstance;
- (IMChat *)existingChatWithChatIdentifier:(NSString *)arg1;
- (id)existingChatForIMHandle:(id)arg1;
@end

@interface IMHandle : NSObject
@property (readonly, nonatomic) NSString *ID;
@property (readonly, assign, nonatomic) NSString* normalizedID;
@property (readonly, assign, nonatomic) NSString* displayID;
@end

@interface IMAVChatParticipant : NSObject
@property (readonly, nonatomic) IMHandle *imHandle;
@end

@interface IMAVChat : NSObject
@property (nonatomic) unsigned int state;
@property (retain, nonatomic) NSArray *participants;
@property (readonly, nonatomic) IMAVChatParticipant *localParticipant;
@end

@interface IMDChat : NSObject
@property (retain) /*FZMessage or IMMessageItem*/ id lastMessage;
@property (copy) NSString *guid;
@end

@interface IMDAccount : NSObject
@end

@interface IMDServiceSession : NSObject
@property (readonly, nonatomic) IMDAccount *account;
@property (nonatomic,readonly) NSString * displayName; 
- (void)leaveChat:(id)arg1 style:(unsigned char)arg2 ;
- (void)unregisterChat:(id)arg1 style:(unsigned char)arg2;
@end

@interface IMDChatRegistry : NSObject
+ (id)sharedInstance;
- (id)existingChatForID:(NSString *)arg1 account:(IMDAccount *)arg2;
- (void)removeMessage:(FZMessage *)arg1 fromChat:(IMDChat *)arg2;
- (void)removeChat:(IMDChat *)arg1;
@end

@interface IMService : NSObject
+ (id)smsService; // 6_7
+ (id)iMessageService;
@end

@interface IMDaemonController : NSObject
@property (readonly, nonatomic) BOOL isConnected;
+ (id)sharedController;
@end

@interface IMItem : NSObject // 8
@property (retain, nonatomic) NSString *sender;
@property (readonly, nonatomic) BOOL isFromMe;
@end

@interface IMMessageItem : IMItem // 8
@property (readonly, nonatomic) BOOL isFinished;
@property (retain, nonatomic) NSAttributedString *body;
@property (retain, nonatomic) NSArray *fileTransferGUIDs;
@property (retain, nonatomic) NSDate *timePlayed;
@property (retain, nonatomic) NSDate *timeDelivered;
@property (retain, nonatomic) NSDate *timeRead;
@property (retain, nonatomic) NSData *bodyData;
@property (retain, nonatomic) NSString *subject;
@end

@interface IMDChatStore : NSObject
+ (id)sharedInstance;
- (void)deleteChatWithGUID:(id)arg1; // 5
- (void)deleteChat:(id)arg1; // 6_7
@end

// ChatKit
@interface CKConversationListCell : UITableViewCell
@end

@interface CKConversationList : NSObject
+ (id)sharedConversationList;
- (id)activeConversations;
- (id)existingConversationForAddresses:(id)addresses; // 5
- (void)reloadConversations; // 5
- (id)conversationForRecipients:(id)recipients create:(BOOL)create service:(id)service; // 5
- (id)conversationForMessage:(id)arg1 create:(BOOL)arg2 service:(id)arg3; // 5
- (id)conversationForRecipients:(id)recipients create:(BOOL)create; // 6_7
- (id)conversationForHandles:(id)arg1 create:(BOOL)arg2; // 8
- (id)conversationForExistingChat:(id)arg1;
- (id)conversationForExistingChatWithAddresses:(id)arg1; // 6_7
@end

@interface CKConversationListController : UIViewController
@property (nonatomic, assign) CKConversationList *conversationList;
@end

@interface CKAggregateConversation : NSObject // 5
- (id)name;
- (NSArray *)recipients;
@end

@interface CKEntity : NSObject
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *rawAddress;
@property (retain, nonatomic) IMHandle *handle;
+ (id)copyEntityForAddressString:(id)arg1;
@end

@interface CKConversation : NSObject // 6_7_8
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSArray *recipientStrings;
- (id)newMessageWithComposition:(id)arg1; // 6_7
- (id)messageWithComposition:(id)arg1; // 8
- (void)deleteAllMessagesAndRemoveGroup;
- (BOOL)_iMessage_canSendToRecipients:(id)recipients withAttachments:(id)attachments alertIfUnable:(BOOL)unable; // 6_7
- (BOOL)_iMessage_canSendToRecipients:(id)arg1 alertIfUnable:(BOOL)arg2; // 8
- (void)sendMessage:(id)arg1 onService:(id)arg2 newComposition:(BOOL)arg3;
@end

@interface _CKConversation : NSObject // 5
- (NSArray *)messages;
- (id)recipient;
- (NSArray *)recipients;
- (unsigned)recipientCount;
- (BOOL)isEmpty;
- (void)resetCaches;
@end

@interface CKSubConversation : _CKConversation // 5
- (void)removeMessage:(id)arg1;
- (id)latestMessage;
- (void)deleteAllMessagesAndRemoveGroup;
- (void)loadAllMessages;
@end

@interface CKMessage : NSObject
@property (assign, nonatomic) CKSubConversation* conversation; // 5
- (BOOL)hasBeenSent;
- (NSArray *)parts;
- (id)text;
- (id)sender;
- (id)address;
- (unsigned)messagePartCount;
@end

@interface CKSMSMessage : CKMessage // 5
- (id)initWithRowID:(int)arg1;
@end

@interface CKSMSMessageDelivery : NSObject // 5
@property (assign, nonatomic) CKSMSMessage *message;
@end

@interface CKSMSEntity : CKEntity // 5
- (id)rawAddress;
@end

@interface CKMadridEntity : CKEntity // 5
@end

@interface CKImageData : NSObject // 5
@property (readonly, assign, nonatomic) NSData* data;
@end

@interface CKCompressibleImageMediaObject : NSObject // 5
- (CKImageData *)imageData;
@end

@interface CKMessagePart : NSObject
- (int)type;
- (id)text; // NSString in 5, NSConcreteAttributedString in 6
- (CKCompressibleImageMediaObject *)mediaObject;
@end

@interface CKService : NSObject // 5
+ (id)availableServices;
- (void)deleteMessage:(id)message fromConversation:(id)conversation;
@end

@interface CKSMSService : CKService // 5
@property (readonly, assign, nonatomic) CKConversationList* conversationList;
+ (id)sharedSMSService;
- (id)copyEntityForAddressString:(id)addressString;
- (void)sendMessage:(id)message;
- (id)_newSMSMessageWithText:(id)text forConversation:(id)conversation;
- (id)newMessageWithMessage:(id)message forConversation:(id)conversation isForward:(BOOL)forward;
- (void)markAllMessagesInConversationAsRead:(id)conversationAsRead;
- (void)deleteMessage:(id)arg1 fromConversation:(id)arg2;
- (void)beginBulkDeleteMode;
- (void)endBulkDeleteMode;
@end

@interface CKMadridService : CKService // 5
- (int)availabilityForAddress:(id)address checkWithServer:(BOOL)server;
+ (id)sharedMadridService;
- (id)copyEntityForAddressString:(id)addressString;
+ (BOOL)isConnectedToDaemon;
+ (BOOL)isMadridEnabled;
+ (BOOL)isMadridSupported;
- (BOOL)ensureMadridConnection;
- (BOOL)canSendToRecipients:(id)recipients withAttachments:(id)attachments alertIfUnable:(BOOL)unable;
- (BOOL)isAvailable;
- (void)sendMessage:(id)message;
- (BOOL)isValidAddress:(id)address;
- (id)newMessageWithComposition:(id)composition forConversation:(id)conversation;
@end

@interface CKIMEntity : NSObject // 6
+ (id)copyEntityForAddressString:(id)addressString;
@end

@interface CKPreferredServiceManager : NSObject // 7
+ (id)sharedPreferredServiceManager;
- (int)availabilityForAddress:(id)address onService:(id)service checkWithServer:(BOOL)server;
@end

@interface CKMessageComposition : NSObject // 5_6
+ (id)newCompositionForText:(id)text;
@end

@interface CKMessageStandaloneComposition : CKMessageComposition // 5_6
@end

@interface CKComposition : NSObject // 7_8
- (id)initWithText:(NSAttributedString *)arg1 subject:(NSAttributedString *)arg2;
@end

@interface CKIMMessage : NSObject
@end

@interface CKMadridMessage : CKMessage // 5
@end

// FaceTime
@interface CNFConferenceController : NSObject
- (void)rejectFaceTimeInvitationFrom:(id)arg1 conferenceID:(id)arg2; // 5
- (void)declineFaceTimeInvitationForConferenceID:(id)arg1 fromHandle:(id)arg2; // 6
@end

@interface MPConferenceManager : NSObject
@property (readonly, assign) CNFConferenceController* conferenceController;
@end

@interface IMAVChatProxy : NSObject // 7_8
- (id)otherIMHandle;
- (void)declineInvitation;
@property (readonly, retain, nonatomic) NSArray *remoteParticipants;
@property (readonly, nonatomic) unsigned int state;
@end

@interface IMAVChatParticipantProxy : NSObject // 8
@property (readonly, retain, nonatomic) IMAVChat *avChat;
@end

// CoreTelephony
@interface CTPhoneNumber : NSObject
@property (readonly, assign) NSString* digits;
@end

@interface CTAsciiAddress : NSObject
- (NSString *)address;
@end

@interface CTMessage : NSObject
@property (copy, nonatomic) NSString* contentType;
@property (copy, nonatomic) /*CTPhoneNumber or CTAsciiAddress*/ id sender;
@property (readonly, assign) NSArray* items;
@end

@interface CTMessageCenter : NSObject
+ (id)sharedMessageCenter;
- (CTMessage *)incomingMessageWithId:(unsigned)anId;
@end

@interface CTMessagePart : NSObject
@property (copy, nonatomic) NSData* data;
@property (copy, nonatomic) NSString* contentType;
@end

// SpringBoard
@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
@end

@interface SpringBoard : UIApplication
- (BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
- (NSArray *)_accessibilityRunningApplications;
@end

@interface SBIcon : NSObject
- (void)setBadge:(NSString *)badge;
@end

@interface SBIconModel : NSObject
+ (id)sharedInstance; // 5
- (SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
- (id)applicationIconForBundleIdentifier:(id)arg1; // 8
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
- (SBIconModel *)model;
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(id)arg1;
- (id)applicationWithBundleIdentifier:(id)arg1; // 8
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (void)activateApplicationFromSwitcher:(SBApplication *)arg1; // 5
@end

@interface SBAppSwitcherController : NSObject // 5_6
+ (id)sharedInstance;
- (void)_removeApplicationFromRecents:(SBApplication *)application;
@end

@interface SBAppSwitcherModel : NSObject // 7
- (void)remove:(NSString *)bundleIdentifier;
@end

// Others
@interface TUTelephonyCall : NSObject
- (CTCallRef)call;
@end

@interface TUPhoneNumber : NSObject
- (NSString *)digits;
@end

@interface CommunicationFilterItem : NSObject
@end

@interface UITableViewCellContentView : UIView
@end

@interface CPDistributedMessagingCenter : NSObject
+ (id)centerNamed:(id)named;
- (NSDictionary *)sendMessageAndReceiveReplyName:(id)name userInfo:(id)info;
- (BOOL)sendMessageName:(id)name userInfo:(id)info;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(id)messageName target:(id)target selector:(SEL)selector;
- (void)stopServer;
@end

@interface NSConcreteNotification : NSNotification
@end

@interface SMSApplication : UIApplication
- (NSDictionary *)snHandleMessageNamed:(NSString *)name withUserInfo:(NSDictionary *)userInfo;
@end

@interface UIApplication (libstatusbar)
- (void)addStatusBarImageNamed:(NSString*)name removeOnExit:(BOOL)remove;
- (void)addStatusBarImageNamed:(NSString*)name;
- (void)removeStatusBarImageNamed:(NSString*)name;
@end

@interface IDSIDQueryController : NSObject // 8
- (int)_refreshIDStatusForDestination:(id)arg1 service:(id)arg2 listenerID:(id)arg3;
@end

@interface CHRecentCall : NSObject
@property (copy) NSString *callerId;
@property (nonatomic) BOOL read;
- (NSString *)callerNameForDisplay;
@end

@interface CHManager : NSObject
@property (retain, nonatomic) NSArray *recentCalls;
@end
