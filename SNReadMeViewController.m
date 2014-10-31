#import "SNReadMeViewController.h"

@implementation SNReadMeViewController

@synthesize myWebView;
@synthesize fake;

- (void)dealloc
{
	[myWebView release];
	myWebView = nil;

	[fake release];
	fake = nil;

	[super dealloc];
}

- (SNReadMeViewController *)init
{
	if ((self = [super init]))
	{
		self.navigationItem.title = NSLocalizedString(@"Readme", @"Readme");
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Huh?", @"Huh?") style:UIBarButtonItemStylePlain target:self action:@selector(kidding)] autorelease];

		myWebView = [[UIWebView alloc] init];
	}
	return self;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[myWebView.scrollView setContentSize:CGSizeMake(myWebView.frame.size.width, myWebView.scrollView.contentSize.height)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	NSString *filePath = nil;
	filePath = [self.fake boolValue] ? [[NSBundle mainBundle] pathForResource:[language stringByAppendingString:@"_fake"] ofType:@"html"] : [[NSBundle mainBundle] pathForResource:language ofType:@"html"];
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) filePath = [self.fake boolValue] ? [[NSBundle mainBundle] pathForResource:@"en_fake" ofType:@"html"] : [[NSBundle mainBundle] pathForResource:@"en" ofType:@"html"];

	myWebView.delegate = self;
	self.view = myWebView;
	[myWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:filePath]]];
}

- (void)kidding
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Hope is a good thing, maybe the best of things. And no good thing ever dies.", @"Hope is a good thing, maybe the best of things. And no good thing ever dies.") delegate:self cancelButtonTitle:NSLocalizedString(@"You idiot!", @"You idiot!") otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}
@end
