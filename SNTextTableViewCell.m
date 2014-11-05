#import "SNTextTableViewCell.h"

@implementation SNTextTableViewCell
- (void)layoutSubviews
{
	[super layoutSubviews];

	for (UIView *view in [self.contentView subviews])
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			CGRect originalRect = self.textLabel.frame;
			originalRect.size.width = [self.textLabel.text sizeWithFont:self.textLabel.font].width;
			self.textLabel.frame = originalRect;
			((UITextField *)view).contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
			((UITextField *)view).textAlignment = NSTextAlignmentCenter;
			((UITextField *)view).frame = CGRectMake(self.textLabel.frame.origin.x + self.textLabel.bounds.size.width + 9.0f, self.textLabel.frame.origin.y, self.contentView.bounds.size.width - self.textLabel.frame.origin.x - self.textLabel.bounds.size.width - 9.0f, self.textLabel.bounds.size.height);
			break;
		}
	}
}
@end
