//
//	KOPspaceControl.h
//
//

#import <Cocoa/Cocoa.h>

//@class RecImage;
#import "image.h"   // remove image lib dependency

@interface KOPspaceControl:NSObject
{
	IBOutlet id		realView;   // KOImageView
	IBOutlet id		imagView;   // KOImageView
	IBOutlet id		winSlider;  // KOSlider
	IBOutlet id		levSlider;  // KOSlider
//    RecImage        *pImage;    // pspace image (slc, x, y, px, py)
    KO_IMAGE        **pIm;
    int             nImg;
    int             ix;
}

- (id)init;
- (void)drawPspace;
- (void)setPspaceAtIndex:(int)ix;
- (IBAction)open:(id)sender;
- (IBAction)sliderMoved:(id)sender;

@end
