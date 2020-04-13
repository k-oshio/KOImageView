/*
	ImageView.m
*/

#import "KOImageView.h"
#import "KOWindowControl.h"
#import <math.h>

@implementation KOImageView

// initWithFrake is not called when loaded from Nib
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	[self initCVs];
	return self;
}

- (void)awakeFromNib
{
	[self initCVs];
}

- (void)initCVs
{
	int	i;
//    self = [super initWithFrame:frameRect];
	_colorMode = COLOR_MODE_GRAY;
	_cursorMode = 0;	// win/lev
	_lineXOn = NO;
	_lineYOn = NO;
	_aspect = -1;
	_bitmap = nil;		// main image view
    _over = nil;
	_xdim = 0;			// image size
	_ydim = 0;			// image size
	_zoomFactor = 1.0;
	_flipped = NO;
	_interp = NO;
	for (i = 0; i < LUTSIZE; i++) {
		winLevTab[i] = 0;
	}
	for (i = 0; i < 256; i++) {
		_r[i] = _g[i] = _b[i] = i;
	}
}

// allways 24 bit color
// dim of image (not view)
- (void)initImage:(int)xDim :(int)yDim
{
	unsigned char *conversion_tmp[5] = {NULL};
	
	_bitmap = [NSBitmapImageRep alloc];
	_xdim = xDim;
	_ydim = yDim;
//	_zoomFactor = 1.0;
    [self setImageRect];
	[self setLUT];
	_flipped = NO;
	_bitmap = [_bitmap initWithBitmapDataPlanes:&conversion_tmp[0]
                          pixelsWide:_xdim
                          pixelsHigh:_ydim
                       bitsPerSample:8
                     samplesPerPixel:3
                            hasAlpha:NO
                            isPlanar:NO
                      colorSpaceName:NSDeviceRGBColorSpace
                         bytesPerRow:_xdim * 3
                        bitsPerPixel:24];

	_over = [NSBitmapImageRep alloc];
	_over = [_over initWithBitmapDataPlanes:&conversion_tmp[0]
						  pixelsWide:_xdim
						  pixelsHigh:_ydim
					   bitsPerSample:8
					 samplesPerPixel:3
							hasAlpha:NO
							isPlanar:NO
					  colorSpaceName:NSDeviceRGBColorSpace
						 bytesPerRow:_xdim * 3
						bitsPerPixel:24];
}

- (void)enableOver:(BOOL)on
{
	_overlayOn = on;
}

- (void)setFlipInView:(int)flip
{
	_flipped = flip;
}

// image (not view) should be rotated
- (void)setRotateInView:(int)angle
{
	NSPoint	center;
	NSRect	bound = [self bounds];
	float	x, y;

	x = bound.size.width;
	y = bound.size.height;

    switch (angle) {
    case 0:
        center.x = 0;
        center.y = 0;
        break;
    case 1:
        center.x = 0;
        center.y = y;
        break;
    case 2:
        center.x = x;
        center.y = y;
        break;
    case 3:
        center.x = x;
        center.y = 0;
        break;
    }
	[self setBoundsRotation:angle * 90.0];
	[self setBoundsOrigin:center];
}

// NSView method
- (BOOL)isFlipped
{
	return _flipped;
}

- (void)setInterpolation:(BOOL)flag
{
	_interp = flag;
}

// display signed 12bit image using current win/lev/color
// xdim/ydim : dim of image (not view)
// img is already color
- (void)displayImageDataX:(RecImage *)img
{
	int				i, j;
	int				intensity;	// 8bit
	unsigned char	*data = [_bitmap bitmapData];
	unsigned char	*ovr_data = [_over bitmapData];

	if (img == nil) {	// no image
		return;
	}
// 12bit -> 8bit -> color
	for (i = j = 0; i < _xdim * _ydim; i++, j+=3) {
//		intensity = p[i] + LUTSIZE/2;
		if (intensity < 0) intensity = 0;
		if (intensity >= LUTSIZE) intensity = LUTSIZE-1;
		data[j]		= _r[winLevTab[intensity]];
		data[j+1]	= _g[winLevTab[intensity]];
		data[j+2]	= _b[winLevTab[intensity]];
	}
// add overlay ###
	if (_overlayOn) {
		for (i = j = 0; i < _xdim * _ydim; i++, j+=3) {
			if ((ovr_data[j] > 0) || (ovr_data[j+1] > 0) || (ovr_data[j+2] > 0)) {
				data[j]		= ovr_data[j];
				data[j+1]	= ovr_data[j+1];
				data[j+2]	= ovr_data[j+2];
			}
		}
	}

	[self display];
}

//- (void)displayColorImage:(short *)r :(short *)g :(short *)b
- (void)displayImageData:(RecImage *)img
{
	int				i, j;
    int             n;
    float           *p;
	int				intensity;	// 8bit
	unsigned char	*data = [_bitmap bitmapData];
    unsigned char    *ovr_data = [_over bitmapData];

	if (img == nil) {	// no image
		return;
	}

// imaga data
    p = [img data];
    n = [img dataLength] * [img pixSize];

// 12bit -> 8bit -> color
	for (i = j = 0; i < n; i++) {
		intensity = p[i] + LUTSIZE/2;
		if (intensity < 0) intensity = 0;
		if (intensity >= LUTSIZE) intensity = LUTSIZE-1;
		data[i] = winLevTab[intensity];
        if (ovr_data[i] > 0) {
            data[i] += ovr_data[i];
        }
	}
	[self display];
}

- (void)drawRect:(NSRect)rects
{
	NSRect	bb;
	NSImageInterpolation interpMode;

	if (_interp) {
		interpMode = NSImageInterpolationHigh;
	} else {
		interpMode = NSImageInterpolationNone;
	}
	[[NSGraphicsContext currentContext]
		setImageInterpolation:interpMode];
	bb = [self bounds];
	if (_bitmap) {
        if (_aspect > 0) {
            [[NSColor darkGrayColor] set];
            NSRectFill(bb);
        }
		[_bitmap drawInRect:_imageRect];
	} else {
		[[NSColor darkGrayColor] set];
		NSRectFill(bb);
	}
	if (_isFirstResponder) {
		[[NSColor lightGrayColor] set];
		bb = [self bounds];
		NSFrameRect(bb);
	}
	if (_lineXOn) {
		[[NSColor lightGrayColor] set];
		bb = [self bounds];
		bb.size.width = 1; bb.origin.x = _lineX;
		NSFrameRect(bb);
	}
	if (_lineYOn) {
		[[NSColor lightGrayColor] set];
		bb = [self bounds];
		bb.size.height = 1; bb.origin.y = _lineY;
		NSFrameRect(bb);
	}
}

// 12->8 LUT
- (void)setWin:(int)win andLev:(int)lev
{ 
	int     i, j, col;
	for (i = 0; i < LUTSIZE; i++) {
        j = i - LUTSIZE/2;
		col = (j - lev) * 256 / win + 128;
		if (col < 0) col = 0;
		if (col > 255) col = 255;
		winLevTab[i] = col;
	}
}

// experimental non-linear win/lev for CT
- (void)setWinX:(int)win andLev:(int)lev
{ 
	int     i, j, col;
    int     m1;
    int     thres = 128;

    m1 = (2500 + LUTSIZE/2 - lev) * 256 / win + 128;
	for (i = 0; i < LUTSIZE; i++) {
        j = i - LUTSIZE/2;
		col = (j - lev) * 256 / win + 128;
		if (col < 0) col = 0;
        if (col > thres) {
            col = (col - thres) * (256 - thres) / (m1 - thres) + thres;
            if (col > 255) col = 255;
        }
		winLevTab[i] = col;
	}
}

// color LUT
- (void)setLUT
{
	int				i, ix;
	int 			aa, bb;

	aa = 0; bb = 50;
	switch (_colorMode) {
	case COLOR_MODE_GRAY : /* gray */
		for (ix = 0; ix < 256; ix++) {
			_r[ix] = ix;
			_g[ix] = ix;
			_b[ix] = ix;
		}
		break;
	case COLOR_MODE_INV : /* inv gray */
		for (ix = 0; ix < 256; ix++) {
			_r[ix] = 255 - ix;
			_g[ix] = 255 - ix;
			_b[ix] = 255 - ix;
		}
		break;
	case COLOR_MODE_TRI : /* inv gray */
		for (ix = 0; ix < 128; ix++) {
			_r[ix] = ix*2;
			_g[ix] = ix*2;
			_b[ix] = ix*2;
		}
		for (ix = 0; ix < 128; ix++) {
			_r[ix + 128] = 255 - ix*2;
			_g[ix + 128] = 255 - ix*2;
			_b[ix + 128] = 255 - ix*2;
		}
		break;
	case COLOR_MODE_COLOR1 : /* pseudocolor 1 */
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 0;
			_g[ix] = 0;
			_b[ix] = 255 * sin(0.5 * i * M_PI / bb);
		}
		aa = 50; bb = 100;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 0;
			_g[ix] = 255 * sin(0.5 * i * M_PI / bb);
			_b[ix] = 255 * cos(0.5 * i * M_PI / bb);
		}
		aa = 150; bb = 100;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 255 * sin(0.5 * i * M_PI / bb);
			_g[ix] = 255 * cos(0.5 * i * M_PI / bb);
			_b[ix] = 0;
		}
		aa = 250; bb = 6;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 255;
			_g[ix] = 255 * sin(0.5 * i * M_PI / bb);
			_b[ix] = 255 * sin(0.5 * i * M_PI / bb);
		}
		break;
	case COLOR_MODE_COLOR2 : /* pseudocolor 2 */
		aa = 0;
		bb = 64;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 255 * sin(0.5 * i * M_PI / bb);
			_g[ix] = 0;
			_b[ix] = 0;
		}
		aa = 64;
		bb = 160;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 255;
			_g[ix] = 255 * sin(0.5 * i * M_PI / bb);
			_b[ix] = 0;
		}
		aa = 224;
		bb = 32;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 255;
			_g[ix] = 255;
			_b[ix] = 255 * sin(0.5 * i * M_PI / bb);
		}
		break;
	case COLOR_MODE_COLOR3 : /* pseudocolor 3 */
		aa = 0;
		bb = 128;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = 0;
			_g[ix] = 255 - i*2;
			_b[ix] = 255 - i*2;
		}
		aa = 128;
		bb = 128;
		for (i = 0; i < bb; i++) {
			ix = i + aa;
			_r[ix] = i*2;
			_g[ix] = 0;
			_b[ix] = 0;
		}
		break;
	}
}

- (int *)rdata
{
	return _r;
}

- (int *)gdata
{
	return _g;
}

- (int *)bdata
{
	return _b;
}

- (NSBitmapImageRep *)imageRep
{
	return _bitmap;
}

- (NSBitmapImageRep *)overlay
{
	return _over;
}

- (void)setColorMode:(int)mode
{
	_colorMode = mode;
	[self setLUT];
}

- (void)setCursorMode:(int)mode
{
    _cursorMode = mode;
}

- (void)setZoom:(float)zoom
{
    _zoomFactor = zoom;
    [self setImageRect];
}

- (void)setImageRect
{
    NSRect  bb = [self bounds];

    _imageRect = [self bounds];
    _imageRect.size.width *= _zoomFactor;
    _imageRect.size.height *= _zoomFactor;
	
    if (_aspect > 0) {
        _imageRect.size.height *= (float)_aspect * _ydim / _xdim;
	}

	// zoom around center of image -> ### around center of visible rect
	// (previous origin position is necessary)
    _imageRect.origin.x = (bb.size.width - _imageRect.size.width) / 2;
    _imageRect.origin.y = (bb.size.height - _imageRect.size.height) / 2;
}

- (float)zoomFactor
{
    return _zoomFactor;
}

- (void)setSquarePixel:(int)tag
{
	switch (tag) {
	case 0:
	default:
		_aspect = -1;	// square image
		break;
	case 1:
		_aspect = 0.8;
		break;
	case 2:
		_aspect = 1.0;
		break;
	case 3:
		_aspect = 1.2;
		break;
	case 4:
		_aspect = 1.4;
		break;
	case 5:
		_aspect = 1.7;
		break;
	case 6:
		_aspect = 2.0;
		break;
	case 7:
		_aspect = 3.0;
		break;
	case 8:
		_aspect = 4.0;
		break;
	}
}

//=========== (view) event handling ============
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (NSPoint)pointInImage:(NSPoint)whereInView
{
    NSPoint	pt;

    pt.x = (whereInView.x - _imageRect.origin.x) * _xdim
            / _imageRect.size.width;
    pt.y = (_imageRect.size.height - (whereInView.y - _imageRect.origin.y))
            * _ydim
            / _imageRect.size.height;

    if (pt.x < 0) pt.x = 0;
    if (pt.x >= _xdim) pt.x = _xdim - 0.01;
    if (pt.y < 0) pt.y = 0;
    if (pt.y >= _ydim) pt.y = _ydim - 0.01;

    return pt;
}

- (NSPoint)pointInView:(NSPoint)whereInImage
{
    NSPoint	pt;

    pt.x = (whereInImage.x) * _imageRect.size.width / _xdim
            + _imageRect.origin.x;
    pt.y = _imageRect.size.height
            - (whereInImage.y) * _imageRect.size.height / _ydim
            + _imageRect.origin.y;

    return pt;
}

- cursorEvent:(NSEvent *)theEvent initial:(BOOL)initflag
{
    KOWindowControl *wc = [NSApp delegate];
    NSPoint         whereInWindow = [theEvent locationInWindow];
    NSPoint         whereInView = [self convertPoint:whereInWindow
                                        fromView:nil];
    NSPoint         whereInImage = [self pointInImage:whereInView];
    unsigned int    modifier = [theEvent modifierFlags];
    int             x = 0, y = 0, ix;
    int             slc = [[[self control] numSlider] intValue];
    static int      oldX, oldY;

    // mode 1, or shift (absolute x/y)
    if (_cursorMode == 1 || (modifier & NSShiftKeyMask)) {
		[wc reportCursorAt:whereInImage from:_control];
		[[wc profile] drawProfileAt:whereInImage from:_control];
        x = whereInImage.x;
        y = whereInImage.y;
        ix = slc * _xdim * _ydim + y * _ydim + x;
	//	[[wc pspace]  setPspaceAtIndex:ix];
    } else {
        // relative x/y
        if (initflag == YES) {
            oldX = whereInView.x;
            oldY = whereInView.y;
            [_control clearCursor];
        }
        x = whereInView.x - oldX;
        y = whereInView.y - oldY;

        // mode 2, or control (shift image)
        if (_cursorMode == 2 ||
			(modifier & NSControlKeyMask)) {
       //     [_control clearCursor];
            if (x != 0 || y != 0) {
            //    [_control moveByX:x andY:y from:self];
                [wc moveByX:x andY:y from:self];	// ### 3-31-2020
            }
		// mode 3, or alt (page)
        } else if (_cursorMode == 3 || (modifier & NSAlternateKeyMask)) {
            if (y != 0) {
                [_control changeImage:-y from:self];
            }
        // mode 0, default (win/lev)
        } else {	// default: win/lev
       //    [_control clearCursor];
            if (x != 0 || y != 0) {
                [_control changeWin:x lev:-y from:self];
            }
        }
        oldX = whereInView.x;
        oldY = whereInView.y;
    }

    return self;
}

- (void)moveByX:(int)x andY:(int)y
{
    NSRect  bb = [self bounds];

    if (_imageRect.size.width < bb.size.width) {
        _imageRect.origin.x = (bb.size.width - _imageRect.size.width) / 2;
    } else {
        _imageRect.origin.x += x;
        if (_imageRect.origin.x > 0) {
            _imageRect.origin.x = 0;
        }
        if (_imageRect.origin.x < bb.size.width - _imageRect.size.width) {
            _imageRect.origin.x = bb.size.width - _imageRect.size.width;
        }
    }

    if (_imageRect.size.height < bb.size.height) {
        _imageRect.origin.y = (bb.size.height - _imageRect.size.height) / 2;
    } else {
        _imageRect.origin.y += y;
        if (_imageRect.origin.y > 0) {
            _imageRect.origin.y = 0;
        }
        if (_imageRect.origin.y < bb.size.height - _imageRect.size.height) {
            _imageRect.origin.y = bb.size.height - _imageRect.size.height;
        }
    }
    [self display];
}

- (void)clearCursor
{
    _lineXOn = _lineYOn = NO;
}

- (void)setCursorAt:(NSPoint)pt
{
    NSPoint whereInView = [self pointInView:pt];
    _lineX = whereInView.x;
    _lineY = whereInView.y;
    _lineXOn = YES;
    _lineYOn = YES;
}

- (void)setTag:(int)tag
{
	_tag = tag;
}

- (NSInteger)tag
{
	return _tag;
}

- (void)scrollWheel:(NSEvent *)thisEvent
{
	float	dy = [thisEvent deltaY];
	int		y = 0;

	if (dy > 0) {
		y = -1;
	}
	if (dy < 0) {
		y = 1;
	}
	[_control changeImage:y from:self];
}

- (void)mouseDown:(NSEvent *)thisEvent
{
	[self cursorEvent:thisEvent initial:YES];
}

- (void)mouseDragged:(NSEvent *)thisEvent
{
	[self cursorEvent:thisEvent initial:NO];
}

// for speed (not set by default)
- (BOOL)isOpaque
{
	return YES;
}

// accepts copy command / key modifier
- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (BOOL)becomeFirstResponder
{
	_isFirstResponder = YES;
	return YES;
}

- (BOOL)resignFirstResponder
{
	NSRect	bb = [self bounds];
	[self setNeedsDisplayInRect:bb];
	_isFirstResponder = NO;
	_lineYOn = _lineXOn = NO;
	return YES;
}

- (id)copy:(id)sender
{
	NSPasteboard	*pb;

	pb = [NSPasteboard generalPasteboard]; // existing pb
	[pb declareTypes:[NSArray arrayWithObjects:
                NSPDFPboardType,
                NSTIFFPboardType,
				nil] owner:nil];
	// PDF (Cocoa)
	[self writePDFInsideRect:[self bounds] toPasteboard:pb];
	// TIFF (Classic/Carbon)
	[pb setData:[_bitmap TIFFRepresentation] forType:NSTIFFPboardType];

	return self;
}

- (id)control
{
    return _control;
}

@end
