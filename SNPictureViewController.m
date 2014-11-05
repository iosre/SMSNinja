#import "SNPictureViewController.h"

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#define PICTURES @"/var/mobile/Library/SMSNinja/Pictures/"
#define PRIVATEPICTURES @"/var/mobile/Library/SMSNinja/PrivatePictures/"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#define PICTURES @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/Pictures/"
#define PRIVATEPICTURES @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/PrivatePictures/"
#endif

@implementation SNPictureViewController

@synthesize idString;
@synthesize flag;

- (void)dealloc
{
	[idString release];
	idString = nil;

	[flag release];
	flag = nil;

	[pictureScrollView release];
	pictureScrollView = nil;

	[super dealloc];
}

- (instancetype)init
{
	if (self = [super init])
	{
		pictureScrollView = [[UIScrollView alloc] init];
		pictureScrollView.delegate = self;
		pictureScrollView.frame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
		pictureScrollView.contentSize = CGSizeZero;
		pictureScrollView.showsVerticalScrollIndicator = NO;
		pictureScrollView.showsHorizontalScrollIndicator = NO;
		pictureScrollView.pagingEnabled = YES;
		pictureScrollView.userInteractionEnabled = YES;
		pictureScrollView.backgroundColor = [UIColor whiteColor];
		self.wantsFullScreenLayout = YES;
		if ([self respondsToSelector:@selector(setAutomaticallyAdjustsScrollViewInsets:)])
			self.automaticallyAdjustsScrollViewInsets = NO;

		[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"Save") style:UIBarButtonItemStyleBordered target:self action:@selector(saveToAlbum)] autorelease]];
	}
	return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0)
	{
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
		self.navigationController.navigationBar.barStyle = UIStatusBarStyleDefault;
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	pictureScrollView.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width * picturesCount, pictureScrollView.bounds.size.height);

	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_7_0)
	{
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
		self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	}
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
	[pictureScrollView addGestureRecognizer:tapGesture];
	[tapGesture setNumberOfTapsRequired:1];
	[tapGesture release];

	for (int i = 0; i < 2; i++)
	{
		NSString *fileName = nil;
		if ([self.flag isEqualToString:@"black"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PICTURES, self.idString, i, @"png"];
		else if ([self.flag isEqualToString:@"private"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PRIVATEPICTURES, self.idString, i, @"png"];

		UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileName];
		UIImageView *imageView= [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * i, 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.image = image;
		imageView.tag = i + 1;
		[pictureScrollView addSubview:imageView];
		[image release];
		[imageView release];
	}

	self.title = [NSString stringWithFormat:NSLocalizedString(@"Picture %d/%d", @"Picture %d/%d"), 1, picturesCount];
	[self.view addSubview:pictureScrollView];
}

- (void)restoreTitle:(NSString *)title
{
	if ([self.title isEqualToString:NSLocalizedString(@"Done saving", @"Done saving")]) self.title = title;
}

- (void)saveToAlbum
{
	int currentViewIndex = ceil(pictureScrollView.contentOffset.x / [UIScreen mainScreen].bounds.size.width);
	NSString *fileName = nil;
	if ([self.flag isEqualToString:@"black"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PICTURES, self.idString, currentViewIndex, @"png"];
	else if ([self.flag isEqualToString:@"private"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PRIVATEPICTURES, self.idString, currentViewIndex, @"png"];
	UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileName];
	UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
	[image release];
	NSString *originalTitle = self.title;
	self.title = NSLocalizedString(@"Done saving", @"Done saving");
	[self performSelector:@selector(restoreTitle:) withObject:originalTitle afterDelay:2.0f];
}

- (void)tap:(UITapGestureRecognizer *)gesture
{
	__block BOOL shouldHide = !self.navigationController.navigationBarHidden;
	SNPictureViewController *weakSelf = self;

	if (!shouldHide)
	{
		[[UIApplication sharedApplication] setStatusBarHidden:shouldHide withAnimation:UIStatusBarAnimationFade];
		[self.navigationController setNavigationBarHidden:shouldHide animated:NO];
	}

	[UIView transitionWithView:self.navigationController.view
		duration:0.25f
		options:UIViewAnimationOptionTransitionCrossDissolve
		animations:^{
			[[UIApplication sharedApplication] setStatusBarHidden:shouldHide withAnimation:UIStatusBarAnimationFade];
			[weakSelf.navigationController setNavigationBarHidden:shouldHide animated:NO];
		}
completion:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)view
{
	int currentViewIndex = ceil(view.contentOffset.x / [UIScreen mainScreen].bounds.size.width);
	self.title = [NSString stringWithFormat:NSLocalizedString(@"Picture %d/%d", @"Picture %d/%d"), currentViewIndex + 1, picturesCount];
}

- (void)scrollViewDidScroll:(UIScrollView *)view
{
	int currentViewIndex = ceil(view.contentOffset.x / [UIScreen mainScreen].bounds.size.width);
	int currentViewTag = currentViewIndex + 1;

	if ([view viewWithTag:currentViewTag + 1] == nil && currentViewTag != picturesCount) // next
	{
		NSString *fileName = nil;
		if ([self.flag isEqualToString:@"black"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PICTURES, self.idString, currentViewIndex + 1, @"png"];
		else if ([self.flag isEqualToString:@"private"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PRIVATEPICTURES, self.idString, currentViewIndex + 1, @"png"];

		UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileName];
		UIImageView *imageView= [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * (currentViewIndex + 1), 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.image = image;
		imageView.tag = currentViewTag + 1;
		[pictureScrollView addSubview:imageView];
		[image release];
		[imageView release];
	}
	if ([view viewWithTag:currentViewTag - 1] == nil && currentViewTag != 0) // previous
	{
		NSString *fileName = nil;
		if ([self.flag isEqualToString:@"black"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PICTURES, self.idString, currentViewIndex - 1, @"png"];
		else if ([self.flag isEqualToString:@"private"]) fileName = [NSString stringWithFormat:@"%@%@-%d.%@", PRIVATEPICTURES, self.idString, currentViewIndex - 1, @"png"];

		UIImage *image = [[UIImage alloc] initWithContentsOfFile:fileName];
		UIImageView *imageView= [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width * (currentViewIndex - 1), 0.0f, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
		imageView.contentMode = UIViewContentModeScaleAspectFit;
		imageView.image = image;
		imageView.tag = currentViewTag - 1;
		[pictureScrollView addSubview:imageView];
		[image release];
		[imageView release];
	}

	for (UIView *subview in [view subviews])
		if (subview.tag != currentViewTag && subview.tag != currentViewTag - 1 && subview.tag != currentViewTag + 1)
			[subview removeFromSuperview];
}
@end
