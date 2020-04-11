/*
	KOScaleView.m
	
*/

#import "KOScaleView.h"

@implementation KOScaleView

- (void)initScale:(int)n withView:(KOImageView *)view
{
	int		i, ix;
	int		*rdata = [view rdata];
	int		*gdata = [view gdata];
	int		*bdata = [view bdata];

    if (_r) free(_r);
    if (_g) free(_g);
    if (_b) free(_b);
	_nScale = n;
	_r = (float *)malloc(n * sizeof(float));
	_g = (float *)malloc(n * sizeof(float));
	_b = (float *)malloc(n * sizeof(float));
	for (i = 0; i < n; i++) {
		ix = 255 * i / (n - 1);
		_r[i] = rdata[ix] / 255.0;
		_g[i] = gdata[ix] / 255.0;
		_b[i] = bdata[ix] / 255.0;
	}
}

//- (void)dealloc
//{
//    if (_r) free(_r);
//    if (_g) free(_g);
//    if (_b) free(_b);
//	[super dealloc];
//}

- (void)drawRect:(NSRect)rects
{
	NSRect	bb;
	int	i, size;

	bb = [self bounds];
	size = bb.size.height;
	bb.size.height /= _nScale;
	for (i = 0; i < _nScale; i++) {
		bb.origin.y = size / _nScale * i;
		[[NSColor colorWithDeviceRed:_r[i]
					green:_g[i]
					blue:_b[i]
					alpha:1.0] set];
		NSRectFill(bb);
	}
}

- (BOOL)isOpaque
{
	return YES;
}

@end
