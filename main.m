#import "SMSNinja-private.h"

int main(int argc, char **argv)
{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	int ret = UIApplicationMain(argc, argv, @"SMSNinjaApplication", @"SMSNinjaApplication");
	[p drain];
	return ret;
}
