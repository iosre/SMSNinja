#import <CoreTelephony/CTCall.h>

// MobilePhone
typedef struct __CTCall* CTCallRef;

@interface CTCall (undocumented)
+ (CTCall *)callForCTCallRef:(CTCallRef)arg1;
@end

@interface RecentsViewController : UIViewController
- (id)table;
- (NSArray *)calls; // 5
- (id)callAtTableViewIndex:(int)tableViewIndex; // 6
@end

@interface PHRecentsViewController : UIViewController // 7
- (id)table;
- (id)callAtTableViewIndex:(int)tableViewIndex;
@end

@interface RecentCall : NSObject // 5_6
- (instancetype)initWithCTCall:(CTCallRef)arg1;
- (void)deleteUnderlyingCTCall;
- (NSArray *)underlyingCTCalls;
@end

@interface PHRecentCall : NSObject // 7
- (NSString *)callerDisplayName;
- (instancetype)initWithCTCall:(CTCallRef)arg1;
- (void)deleteUnderlyingCTCall;
- (NSArray *)underlyingCTCalls;
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

// IM
@interface IMFileTransfer : NSObject
@property (retain, nonatomic) NSString *localPath;
@property (readonly, assign, nonatomic) NSString* mimeType;
@end

@interface IMDFileTransferCenter : NSObject
+ (instancetype)sharedInstance;
- (IMFileTransfer *)transferForGUID:(NSString *)arg1;
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

@interface IMChatItem : NSObject
@end

@interface IMMessage : NSObject
+ (instancetype)messageFromFZMessage:(FZMessage *)fzmessage sender:(NSString *)sender subject:(NSString *)subject;
+ (instancetype)messageFromIMMessageItem:(IMMessageItem *)arg1 sender:(NSString *)arg2 subject:(NSString *)arg3; // 8
@end

@interface IMService : NSObject
+ (instancetype)smsService; // 6_7
+ (instancetype)iMessageService;
@end

@interface IMServiceImpl : IMService
@end

@interface IMChat : NSObject
@property (readonly, nonatomic) NSArray *participants;
@property (readonly, assign, nonatomic) IMMessage* lastMessage;
@property (readonly, nonatomic) unsigned int messageCount;
@property (readonly, nonatomic) BOOL hasMoreMessagesToLoad;
- (IMChatItem *)chatItemForMessage:(IMMessage *)message;
- (NSArray *)chatItemsForMessages:(NSArray *)arg1; // 8
- (NSArray *)chatItemsForItems:(NSArray *)arg1; // 8
- (void)leave;
- (BOOL)deleteChatItem:(IMChatItem *)item;
- (void)deleteChatItems:(NSArray *)arg1; // 8
@end

@interface IMAccount : NSObject
@property (readonly, nonatomic) BOOL isActive;
@property (readonly, nonatomic) BOOL isConnected;
@property (readonly, nonatomic) BOOL isOperational;
@end

@interface IMAccountController : NSObject
+ (instancetype)sharedInstance;
- (IMAccount *)bestAccountForService:(IMServiceImpl *)arg1;
- (BOOL)activateAccount:(IMAccount *)arg1;
@end

@interface IMHandle : NSObject
@property (readonly, nonatomic) NSString *ID;
@property (readonly, assign, nonatomic) NSString* normalizedID;
@property (readonly, assign, nonatomic) NSString* displayID;
@end

@interface IMChatRegistry : NSObject
+ (instancetype)sharedInstance;
- (IMChat *)existingChatWithChatIdentifier:(NSString *)arg1;
- (IMChat *)existingChatForIMHandle:(IMHandle *)arg1;
- (IMChat *)chatForIMHandle:(IMHandle *)arg1; // 8
@end

@interface IMAVChatParticipant : NSObject
@property (readonly, nonatomic) IMHandle *imHandle;
@end

@interface IMAVChat : NSObject
@property (nonatomic) unsigned int state;
@property (retain, nonatomic) NSArray *participants;
@property (readonly, nonatomic) IMAVChatParticipant *localParticipant;
@property (retain, nonatomic) NSString *conferenceID;
- (void)declineInvitation;
@end

@interface IMAVInvitationController : NSObject // 5_6
+ (void)declineInvitationRequestFromBuddy:(IMHandle *)arg1 forConference:(NSString *)arg2;
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
@end

@interface IMDChatRegistry : NSObject
+ (instancetype)sharedInstance;
- (IMDChat *)existingChatForID:(NSString *)arg1 account:(IMDAccount *)arg2;
- (void)removeMessage:(FZMessage *)arg1 fromChat:(IMDChat *)arg2;
- (void)removeChat:(IMDChat *)arg1;
@end

@interface IMDaemonController : NSObject
@property (readonly, nonatomic) BOOL isConnected;
+ (instancetype)sharedController;
@end

@interface IMDChatStore : NSObject
+ (instancetype)sharedInstance;
- (void)deleteChatWithGUID:(NSString *)arg1; // 5
- (void)deleteChat:(IMDChat *)arg1; // 6_7
@end

// ChatKit
@interface CKConversationListCell : UITableViewCell
@end

@interface _CKConversation : NSObject // 5
- (NSArray *)messages;
- (NSArray *)recipient;
- (NSArray *)recipients;
- (unsigned)recipientCount;
- (BOOL)isEmpty;
- (void)resetCaches;
@end

@interface CKSubConversation : _CKConversation // 5
- (void)deleteAllMessagesAndRemoveGroup;
@end

@interface CKMessage : NSObject
@property (assign, nonatomic) CKSubConversation* conversation; // 5
- (BOOL)hasBeenSent;
- (NSArray *)parts;
- (NSString *)text;
- (NSString *)sender;
- (NSString *)address;
- (unsigned)messagePartCount;
@end

@interface CKService : NSObject // 5
+ (instancetype)availableServices;
- (void)deleteMessage:(CKMessage *)message fromConversation:(_CKConversation *)conversation;
@end

@interface CKIMMessage : NSObject
@end

@interface CKComposition : NSObject // 7_8
- (instancetype)initWithText:(NSAttributedString *)arg1 subject:(NSAttributedString *)arg2;
@end

@interface CKConversation : NSObject // 6_7_8
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSArray *recipientStrings;
- (CKIMMessage *)newMessageWithComposition:(id)arg1; // 6_7
- (IMMessage *)messageWithComposition:(CKComposition *)arg1; // 8
- (void)deleteAllMessagesAndRemoveGroup;
- (BOOL)_iMessage_canSendToRecipients:(NSArray *)recipients withAttachments:(NSArray *)attachments alertIfUnable:(BOOL)unable; // 6_7
- (BOOL)_iMessage_canSendToRecipients:(NSArray *)arg1 alertIfUnable:(BOOL)arg2; // 8
- (void)sendMessage:(id)arg1 newComposition:(BOOL)arg2; // 8
- (void)sendMessage:(id)arg1 onService:(IMService *)arg2 newComposition:(BOOL)arg3; // 7
@end

@interface CKConversationList : NSObject
+ (instancetype)sharedConversationList;
- (NSArray *)activeConversations;
- (CKSubConversation *)existingConversationForAddresses:(NSArray *)addresses; // 5
- (void)reloadConversations; // 5
- (CKSubConversation *)conversationForRecipients:(NSArray *)recipients create:(BOOL)create service:(CKService *)service; // 5
- (CKSubConversation *)conversationForMessage:(CKMessage *)arg1 create:(BOOL)arg2 service:(CKService *)arg3; // 5
- (CKConversation *)conversationForRecipients:(NSArray *)recipients create:(BOOL)create; // 6_7
- (CKConversation *)conversationForHandles:(NSArray *)arg1 create:(BOOL)arg2; // 8
- (CKConversation *)conversationForExistingChat:(IMChat *)arg1; // 6_7_8
- (CKConversation *)conversationForExistingChatWithAddresses:(NSArray *)arg1; // 6_7
- (void)deleteConversation:(CKConversation *)conversation;
@end

@interface CKConversationListController : UIViewController
@property (nonatomic, assign) CKConversationList *conversationList;
@end

@interface CKAggregateConversation : _CKConversation // 5
- (NSString *)name;
- (NSArray *)recipients;
@end

@interface CKEntity : NSObject
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) NSString *rawAddress;
@property (retain, nonatomic) IMHandle *handle;
+ (instancetype)copyEntityForAddressString:(NSString *)arg1;
+ (instancetype)_copyEntityForAddressString:(NSString *)arg1 onAccount:(IMAccount *)arg2;
@end

@interface CKSMSMessage : CKMessage // 5
- (instancetype)initWithRowID:(int)arg1;
@end

@interface CKMadridMessage : CKMessage // 5
@end

@interface CKSMSMessageDelivery : NSObject // 5
@property (assign, nonatomic) CKSMSMessage *message;
@end

@interface CKSMSEntity : CKEntity // 5
- (NSString *)rawAddress;
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

@interface CKSMSService : CKService // 5
@property (readonly, assign, nonatomic) CKConversationList* conversationList;
+ (instancetype)sharedSMSService;
- (CKSMSEntity *)copyEntityForAddressString:(NSString *)addressString;
- (void)sendMessage:(CKMessage *)message;
- (CKSMSMessage *)_newSMSMessageWithText:(NSString *)text forConversation:(_CKConversation *)conversation;
- (void)beginBulkDeleteMode;
- (void)endBulkDeleteMode;
@end

@interface CKMessageComposition : NSObject // 5_6
+ (instancetype)newCompositionForText:(NSString *)text;
@end

@interface CKMadridService : CKService // 5
- (int)availabilityForAddress:(NSString *)address checkWithServer:(BOOL)server;
+ (instancetype)sharedMadridService;
- (CKMadridEntity *)copyEntityForAddressString:(NSString *)addressString;
+ (BOOL)isConnectedToDaemon;
+ (BOOL)isMadridEnabled;
+ (BOOL)isMadridSupported;
- (BOOL)ensureMadridConnection;
- (BOOL)canSendToRecipients:(NSArray *)recipients withAttachments:(NSArray *)attachments alertIfUnable:(BOOL)unable;
- (BOOL)isAvailable;
- (void)sendMessage:(CKMessage *)message;
- (BOOL)isValidAddress:(NSString *)address;
- (CKMadridMessage *)newMessageWithComposition:(CKMessageComposition *)composition forConversation:(_CKConversation *)conversation;
@end

@interface CKIMEntity : CKEntity // 6
+ (instancetype)copyEntityForAddressString:(NSString *)addressString;
@end

@interface CKPreferredServiceManager : NSObject // 7
+ (instancetype)sharedPreferredServiceManager;
- (int)availabilityForAddress:(NSString *)address onService:(IMService *)service checkWithServer:(BOOL)server;
@end

@interface CKMessageStandaloneComposition : CKMessageComposition // 5_6
@end

// FaceTime
@interface CNFConferenceController : NSObject
- (void)rejectFaceTimeInvitationFrom:(NSURL *)arg1 conferenceID:(NSString *)arg2; // 5
- (void)declineFaceTimeInvitationForConferenceID:(NSString *)arg1 fromHandle:(IMHandle *)arg2; // 6
@end

@interface MPConferenceManager : NSObject
@property (readonly, assign) CNFConferenceController* conferenceController;
- (void)stopAudioPlayer; // 5_6_7
@end

@interface MPTelephonyManager : NSObject
- (void)stopAudioPlayer; // 8
@end

@interface IMAVChatProxy : NSObject // 7_8
- (IMHandle *)otherIMHandle;
- (void)declineInvitation;
@property (readonly, retain, nonatomic) NSArray *remoteParticipants;
@property (readonly, nonatomic) unsigned int state;
@end

@interface IMAVChatParticipantProxy : NSObject // 8
@property (readonly, retain, nonatomic) IMAVChatProxy *avChat;
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
+ (instancetype)sharedMessageCenter;
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
- (BOOL)launchApplicationWithIdentifier:(NSString *)arg1 suspended:(BOOL)arg2;
- (NSArray *)_accessibilityRunningApplications;
@end

@interface SBIcon : NSObject
- (void)setBadge:(NSString *)badge;
@end

@interface SBIconModel : NSObject
+ (instancetype)sharedInstance; // 5
- (SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
- (SBIcon *)applicationIconForBundleIdentifier:(NSString *)arg1; // 8
@end

@interface SBIconController : NSObject
+ (instancetype)sharedInstance;
- (SBIconModel *)model;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)arg1;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)arg1; // 8
@end

@interface SBUIController : NSObject
+ (instancetype)sharedInstance;
- (void)activateApplicationFromSwitcher:(SBApplication *)arg1; // 5
@end

@interface SBAppSwitcherController : NSObject // 5_6
+ (instancetype)sharedInstance;
- (void)_removeApplicationFromRecents:(SBApplication *)application;
@end

@interface SBDisplayItem : NSObject // 8
+ (instancetype)displayItemWithType:(NSString *)arg1 displayIdentifier:(NSString *)arg2;
@end

@interface SBAppSwitcherModel : NSObject // 7_8
- (void)remove:(NSString *)bundleIdentifier;
- (void)removeDisplayItem:(SBDisplayItem *)item;
@end

// Others
@interface TUCall : NSObject
@property (nonatomic) int transitionStatus;
@property (readonly, nonatomic) BOOL isVideo;
- (void)disconnect;
- (BOOL)setMuted:(BOOL)arg1;
@end

@interface TUCallCenterCallsCache : NSObject
- (void)stopTrackingCall:(TUCall *)arg1;
@end

@interface TUCallCenter : NSObject
+ (id)sharedInstance;
@property (retain, nonatomic) TUCallCenterCallsCache *callsCache; // @synthesize callsCache=_callsCache;
- (void)disconnectCall:(TUCall *)arg1;
@end

@interface TUPhoneNumber : NSObject
- (NSString *)digits;
@end

@interface TUTelephonyCall : TUCall
- (CTCallRef)call;
@end

@interface TUFaceTimeCall : TUCall // 8
@property (retain, nonatomic) IMAVChatProxy *chat;
@end

@interface TUFaceTimeVideoCall : TUFaceTimeCall // 8
@end

@interface TUFaceTimeAudioCall : TUFaceTimeCall // 8
@end

@interface CommunicationFilterItem : NSObject
@end

@interface UITableViewCellContentView : UIView
@end

@interface CPDistributedMessagingCenter : NSObject
+ (instancetype)centerNamed:(NSString *)named;
- (NSDictionary *)sendMessageAndReceiveReplyName:(NSString *)name userInfo:(NSDictionary *)info;
- (BOOL)sendMessageName:(NSString *)name userInfo:(NSDictionary *)info;
- (void)runServerOnCurrentThread;
- (void)registerForMessageName:(NSString *)messageName target:(id)target selector:(SEL)selector;
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
- (int)_refreshIDStatusForDestination:(NSString*)arg1 service:(NSString*)arg2 listenerID:(NSString*)arg3;
@end

@interface CHRecentCall : NSObject
@property unsigned int callType; // 1 for call, 8 for facetime
@property (copy) NSString *callerId;
@property (nonatomic) BOOL read;
- (NSString *)callerNameForDisplay;
@end

@interface CHManager : NSObject
@property (retain, nonatomic) NSArray *recentCalls;
- (void)deleteCall:(CHRecentCall *)arg1;
- (void)deleteCallAtIndex:(unsigned int)arg1;
@end

@interface TUCallServicesRecentsController : NSObject
@property (retain, nonatomic) CHManager *recentsManager;
@end

@interface TUAudioPlayer : NSObject
- (void)stop;
@end

@interface CallRecord : NSObject
@property (retain, nonatomic) NSString *address;
@property (retain, nonatomic) NSNumber *read;
@property (retain, nonatomic) NSString *unique_id;
@end

@interface CallHistoryDBHandle : NSObject
- (void)deleteObjectWithUniqueId:(NSString *)arg1;
@end
