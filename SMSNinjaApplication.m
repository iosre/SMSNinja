#import "SMSNinjaApplication.h"
#import <objc/runtime.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#endif

static SMSNinjaApplication *currentApplication;

static void QuitApp(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[currentApplication applicationWillTerminate:currentApplication];
	exit(0); // 失效？看看SpringBoard里面有没有关闭一个App的方法
}

@implementation SMSNinjaApplication

@synthesize window = _window;

- (void)dealloc
{
	[_window release];
	_window = nil;

	[_viewController release];
	_viewController = nil;

	[navigationController release];
	navigationController = nil;

	[super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	_viewController = [[SNMainViewController alloc] init];
	navigationController = [[UINavigationController alloc] initWithRootViewController:_viewController];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	[self showPasswordAlert];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, QuitApp, CFSTR("com.apple.springboard.lockcomplete"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	currentApplication = self;
}
/*
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	if ([self isLocked])
	{
		[self applicationWillTerminate:application];
		exit(0);
	}
}
*/
- (void)applicationWillTerminate:(UIApplication *)application
{
	[self updateBadgeAndSquareAndIcon];
	CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
	[messagingCenter sendMessageName:@"RemoveIconFromSwitcher" userInfo:nil];
}

- (void)showPasswordAlert
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:SETTINGS] && [[[NSDictionary dictionaryWithContentsOfFile:SETTINGS] objectForKey:@"startPassword"] length] != 0)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Let me in!", @"Let me in!") otherButtonTitles:NSLocalizedString(@"Never mind", @"Never mind") , nil];
		[alertView setAlertViewStyle:UIAlertViewStyleSecureTextInput];
		[alertView show];
		[alertView release];
	}
	else
	{
		_viewController.fake = nil;
		_viewController.fake = [NSNumber numberWithBool:NO];
		self.window.rootViewController = navigationController;
		[_window makeKeyAndVisible];
	}
}

- (void)updateBadgeAndSquareAndIcon
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:SETTINGS];
	CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninja.springboard"];
	[messagingCenter sendMessageName:@"UpdateBadge" userInfo:nil];
	if ([[dictionary objectForKey:@"appIsOn"] boolValue])
	{
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if ([[dictionary objectForKey:@"shouldShowPurpleSquare"] boolValue] && [fileManager fileExistsAtPath:@"/var/mobile/Library/SMSNinja/UnreadPrivateInfo"]) [messagingCenter sendMessageName:@"ShowPurpleSquare" userInfo:nil];
		else [messagingCenter sendMessageName:@"HidePurpleSquare" userInfo:nil];
		if ([[dictionary objectForKey:@"shouldHideIcon"] boolValue]) [messagingCenter sendMessageName:@"HideIcon" userInfo:nil];
		else [messagingCenter sendMessageName:@"ShowIcon" userInfo:nil];
	}
	else
	{
		[messagingCenter sendMessageName:@"HidePurpleSquare" userInfo:nil];
		[messagingCenter sendMessageName:@"ShowIcon" userInfo:nil];
	}
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
	UITextField *textField = [alertView textFieldAtIndex:0];
	textField.placeholder = NSLocalizedString(@"Password here", @"Password here");
	textField.clearButtonMode = UITextFieldViewModeWhileEditing;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *password = [alertView textFieldAtIndex:0].text;

	if (buttonIndex == 0)
	{
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:SETTINGS];
		if ([[dictionary objectForKey:@"startPassword"] isEqualToString:password] && [password length] != 0)
		{
			_viewController.fake = nil;
			_viewController.fake = [NSNumber numberWithBool:NO];
			self.window.rootViewController = navigationController;
			[_window makeKeyAndVisible];
		}
		else if ([[dictionary objectForKey:@"fakePassword"] isEqualToString:password] && [password length] != 0)
		{
			_viewController.fake = nil;
			_viewController.fake = [NSNumber numberWithBool:YES];
			self.window.rootViewController = navigationController;
			[_window makeKeyAndVisible];
		}
		else exit(0);
	}
	else exit(0);
}
@end
