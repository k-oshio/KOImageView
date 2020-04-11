//
//	KOPspaceControl.h
//
//

#import "KOPspaceControl.h"
#import "KOImageView.h"
#import "KOimageControl.h"
#import <RecKit/RecKit.h>

@implementation KOPspaceControl

- (id)init
{
	self = [super init];
    pIm = nil;
	return self;
}

- (void)awakeFromNib
{
	[winSlider setMin:1
                max:8000
                value:4000
                continuous:YES
                nonlinear:YES
                tag:0];
	[levSlider setMin:-8000
                max:8000
                value:0
                continuous:YES
                nonlinear:YES
                tag:1];
}

- (void)setPspaceAtIndex:(int)index
{
    ix = index;
    [self drawPspace];
}

- (void)drawPspace
{
    short           *p, *q;             // buffer
    float           *re, *im;           // RecImage
    float           mx;
    int             i, n;

    if (pIm == nil) return;

    re = pIm[ix]->real[0];
    im = pIm[ix]->imag[0];

    n = pIm[0]->size;
    p = (short *)malloc(sizeof(short) * n);
    q = (short *)malloc(sizeof(short) * n);

    mx = 0;
    for (i = 0; i < n; i++) {
        if (mx < fabs(re[i])) {
            mx = fabs(re[i]);
        }
        if (mx < fabs(im[i])) {
            mx = fabs(im[i]);
        }
    }
    mx = 2000 / mx;
    for (i = 0; i < n; i++) {
        p[i] = re[i] * mx;
        q[i] = im[i] * mx;
    }
//    [realView displayImageData:p]; // data is copied to view
//    [imagView displayImageData:q]; // data is copied to view

    free(p);
    free(q);
}


- (IBAction)open:(id)sender
{
	int			sts;
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
    char        *path;
    int         xDim, yDim;

	[openPanel setAllowsMultipleSelection:NO];
    sts = (int)[openPanel runModal];
    if (sts != NSModalResponseOK) return;
    path = (char *)[[[openPanel URL] path] UTF8String];
//    pImage = [RecImage imageWithKOImage:[[openPanel URL] path]];
    pIm = get_image_block(path, &nImg);
    xDim = pIm[0]->xdim;
    yDim = pIm[0]->ydim;
    [realView initImage:xDim :yDim];
    [imagView initImage:xDim :yDim];
    [self setPspaceAtIndex:0];
}

- (IBAction)sliderMoved:(id)sender
{
    int     win = [winSlider intValue];
    int     lev = [levSlider intValue];
	[realView setWin:win andLev:lev];
	[imagView setWin:win andLev:lev];
    [self drawPspace];
}

@end
