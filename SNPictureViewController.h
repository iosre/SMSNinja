#import "SMSNinja-private.h"

@interface SNPictureViewController : UIViewController <UIScrollViewDelegate>
{
@public
    int picturesCount;
@private
    UIScrollView *pictureScrollView;
}
@property (nonatomic, retain) NSString *idString;
@property (nonatomic, retain) NSString *flag;
- (void)tap:(UITapGestureRecognizer *)gesture;
- (void)saveToAlbum;
- (void)restoreTitle:(NSString *)title;
@end