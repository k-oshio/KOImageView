/*
	KOImageControl.m
	Control object for image view
	
	K. Oshio
	8-16-2001	Initial (IBrowserControl -> PVControl)
	
 */
 
#import "KOImageControl.h"
#import "KOImageView.h"
#import "KOSlider.h"
#import "KOScaleView.h"
#import "KOProfControl.h"

#import <RecKit/RecKit.h>

int max_val = 4000; // constant

// returns new color image. raw is freed.
// cpxMode   : 0:mag, 1:real, 2:imag, 3:phase, 4:phase color
// imageType : 0:integer image, 1:real(float) image, 2:complex iamge, 3:color(vector) image
// dispMode  : 0:integer -> real, 1:real -> real, 2:cpx -> mag, 3:cpx -> real, 4:cpx -> imag,
//              5:cpx -> p3, 6:cpx ->phase (real), 7:cpx->phase color, 8:color->color
/*
float
lp1(float a)
{
	float	b;

	if (a > 0) {
	//	b = log(a + 1.0);
		b = pow(a, 0.2);
	} else {
	//	b = -log(-a + 1);
		b = -pow(-a, 0.2);
	}
	return b;
}
*/

@implementation KOImageControl

- (id)initFromNib
{
	NSArray	*objs;
	self = [self init];
	[[NSBundle mainBundle] loadNibNamed:@"ImageBrowser" owner:self topLevelObjects:&objs];

	return self;
}

- (id)init
{
	self = [super init];
    _files = nil;
	_img = _dispBuf = nil;
    _timer = nil;
    _cineMode = 0;	// space
    _cineDelta = 1;
    _frameRate = 10.0;	// fps
	_cpxMode = 0;
	_zoomFactor = 1.0;
    _flip = NO;
    _rot = 0;

	return self;
}

- (void)awakeFromNib
{
	[_winSlider setMin:1
                max:16000
                value:1000
                continuous:YES
                nonlinear:YES
                tag:0];
	[_levSlider setMin:-16000
                max:16000
                value:500
                continuous:YES
                nonlinear:YES
                tag:1];
	[_numSlider setMin:0
                max:0
                value:0
                continuous:YES
                nonlinear:NO
                tag:2];
	[self updateWinLev];
	if (_scaleView) {
		[_scaleView initScale:64 withView:_view];
		[_scaleView display];
	}
}

- (void)open
{
	int			sts;
	int			len;
	NSString	*path;
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];

	[openPanel setAllowsMultipleSelection:YES];
    sts = (int)[openPanel runModal];
    if (sts != NSModalResponseOK) return;
    _files = [openPanel URLs];
	[self loadImages];

// initially invisible
	path = [[[openPanel URLs] objectAtIndex:0] path];
	len = (int)[path length];
	len -= 40;
	if (len < 0) len = 0;
	path = [path substringFromIndex:len];
	[_window setTitle:path];
    [_window makeKeyAndOrderFront:self];
}

// cpx
- (RecImage *)selectedImage
{
    int            ix;
    ix = [self imageIndex];
    return [_img sliceAtIndex:ix];
}

// real
- (RecImage *)selectedBuf
{
    int            ix;
    ix = [self imageIndex];
    return [_dispBuf sliceAtIndex:ix];
}

/*
- (RecImage *)selectedImageAndCpxMode // slice, real/imag/phase
{
    RecImage    *img = [self selectedImage];
    switch (_cpxMode) {
    case 0 :    // mag
        [img magnitude];
        break;
    default :
    case 1 :
        [img takeRealPart];
        break;
    case 2 :
        [img takeImagPart];
        break;
    case 3 :
        [img phase];
        break;
    }
    return img;
}
*/

- (void)loadImages
{
//    const char *path;
 	RecImage	*img;	// testing ... ###

    // RecImage
	if ((img = [RecImage imageFromFile:[[_files objectAtIndex:0] path] relativePath:NO])) {
        // recimage ... -> make 3D (removde upper loops)
	} else
	// RecKit KOImage
	if ((img = [RecImage imageWithKOImage:[[_files objectAtIndex:0] path]])) {
    // ### do nothing
    } else
	// DICOM
	if ((img = [RecImage imageWithDicomFiles:_files])) {
    // ## do nothing
	}

    switch ([img type]) {
    case RECIMAGE_REAL :
        _imgType = RECIMAGE_REAL;
        break;
    case RECIMAGE_COMPLEX :
        _imgType = RECIMAGE_COMPLEX;
        break;
    case RECIMAGE_COLOR :
    case RECIMAGE_VECTOR :
        _imgType = RECIMAGE_COLOR;
        break;
    default :
        _imgType = RECIMAGE_COMPLEX;
        break;
    }
    [self setImage:img];
    [self setDispBuf];
    
    // set slider etc (old setImages:)
    // update n-slider (before displayImage)
    [_numSlider setMin:0 andMax:[img zDim]-1];
//    [_numSlider setValue:0];

    // view
    [self updateWinLev];
    [self displayImage];
    if (_scaleView) {
        [_scaleView initScale:64 withView:_view];
        [_scaleView display];
    }
}

- (void)setDispBuf     // convert img to scaled color image
{
    RecImage    *tmp;
    float       *p, *q;             // input
    float       *r, *g, *b;         // output
    float       mg, th;
    float       *gray;
    float       max_val;
    int         full_int = 4000;
    int         i, n;

    if (_imgType == RECIMAGE_COLOR ||
        (_imgType == RECIMAGE_COMPLEX && _cpxMode == 4)) {
        _dispBuf = [RecImage imageOfType:RECIMAGE_COLOR withImage:_img];
        r = [_dispBuf real];
        g = r + [_dispBuf dataLength];
        b = g + [_dispBuf dataLength];
        gray = NULL;
    } else {
        _dispBuf = [RecImage imageOfType:RECIMAGE_REAL withImage:_img];
        gray = [_dispBuf data];
        r = g = b = NULL;
    }
    max_val = fmax([_img maxVal], -[_img minVal]);
    _dispScale = max_val / full_int;

    switch (_imgType) {
// real
    case RECIMAGE_REAL :
        p = [_img data];
        n = [_img dataLength];
        for (i = 0; i < n; i++) {
            gray[i] = p[i] / _dispScale;
        }
        break;
// complex -> real
    case RECIMAGE_COMPLEX :
        tmp = [_img copy];
        //  0:Mag, 1:Re, 2:Im, 3:Phs, 4:color
        switch (_cpxMode) {
        default :
        case 0 :     // mag
            [tmp magnitude];
            p = [tmp data];
            n = [tmp dataLength];
            for (i = 0; i < n; i++) {
                gray[i] = p[i] / _dispScale;
            }
            break;
        case 1 :     // real
            [tmp takeRealPart];
            p = [tmp data];
            n = [tmp dataLength];
            for (i = 0; i < n; i++) {
                gray[i] = p[i] / _dispScale;
            }
            break;
        case 2 :     // imag
            [tmp takeImagPart];
            p = [tmp data];
            n = [tmp dataLength];
            for (i = 0; i < n; i++) {
                gray[i] = p[i] / _dispScale;
            }
            break;
        case 3 :     // phase
            [tmp phase];
            p = [tmp data];
            n = [tmp dataLength];
            for (i = 0; i < n; i++) {
                gray[i] = p[i] * 1000;
            }
            break;
        case 4 :     // color
            p = [tmp real];
            q = [tmp imag];
            n = [tmp dataLength];
            for (i = 0; i < n; i++) {
                mg = sqrt(p[i]*p[i] + q[i]*q[i]);
                th = atan2(q[i], p[i]);
                
                // === (3-27-2013) ==
                if (th < - 2*M_PI/3) {
                    r[i] = 0;
                    g[i] = mg * 3 * (-2*M_PI/3 - th) / M_PI;
                    b[i] = mg;
                } else
                if (th < - M_PI / 3.0) {
                    r[i] = mg * 3 * (th + 2*M_PI/3) / M_PI;
                    g[i] = 0;
                    b[i] = mg;
                } else
                if (th < 0) {
                    r[i] = mg;
                    g[i] = 0;
                    b[i] = mg * 3 * (-th) / M_PI;
                } else
                if (th < M_PI/3) {
                    r[i] = mg;
                    g[i] = mg * 3 * (th) / M_PI;
                    b[i] = 0;
                } else
                if (th < 2.0 * M_PI / 3.0) {
                    r[i] = mg * 3 * (2*M_PI/3 - th) / M_PI;
                    g[i] = mg;
                    b[i] = 0;
                } else {
                    r[i] = 0;
                    g[i] = mg;
                    b[i] = mg * 3 * (th - 2*M_PI/3) / M_PI;
                }
            }
            [_dispBuf multByConst:1.0 / _dispScale];
            break;
        }
        break;
        // color
    case RECIMAGE_COLOR :
       [_dispBuf copyImageData:_img];
        [_dispBuf multByConst:1.0 / _dispScale];
        break;
    }

// flip / rot
     //   - (void)rotate:(int)code
    //    - (void)yFlip
    if (_flip) {
        [_dispBuf yFlip];
    }
    if (_rot > 0) {
        [_dispBuf rotate:_rot];
    }
    [_view initImage:[_dispBuf xDim]:[_dispBuf yDim]];
}

- (void)openRawXDim:(int)xDim yDim:(int)yDim zDim:(int)zDim pixSize:(int)size order:(int)order type:(int)type
{
    // not implemented yet ###
}

typedef struct {
	int				magic;	// KO_MAGIC3
	int				type;
	int				xdim;
	int				ydim;
	int				zdim;
	int				fill[3];
}	KO_HDR3;	// 32 bytes

- (void)saveAsKOImage
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    NSString    *path;
    int         sts;
    
    if (!savePanel) savePanel = [NSSavePanel savePanel];
    sts = (int)[savePanel runModal];
    if (sts != NSModalResponseOK) {
        return;
    } else {
        path = [[savePanel URL] path];
        [_img saveAsKOImage:path];
    }
}

// Save All Images as PDF (actually tiff... pdf doesn't work)
- (void)saveAllAsPDF
{
	NSSavePanel	*savePanel = [NSSavePanel savePanel];
	NSData		*data;
	NSString	*path, *path2;
    RecImage    *slc;
	int			i, sts;
	
	if (!savePanel) savePanel = [NSSavePanel savePanel];
    sts = (int)[savePanel runModal];
	if (sts != NSModalResponseOK) {
		return;
	} else {
		path = [[savePanel URL] path];
		for (i = 0; i < [_dispBuf zDim]; i++) {
			// make path
			path2 = [NSString stringWithFormat:@"%@%03d.tiff", path, i];
		//	path2 = [NSString stringWithFormat:@"%@%03d.pdf", path, i];
            slc = [_dispBuf sliceAtIndex:i];
			[_view displayImageData:slc];
			data = [[_view imageRep] TIFFRepresentation];
		// data = [_view dataWithPDFInsideRect:[_view bounds]];
			[data writeToFile:path2 atomically:YES];
		}
		[self displayImage];
	}
}

// display with current win/lev and image number
- (void)displayImage
{
    RecImage    *slice;
    int         ix;

    ix = [self imageIndex];
    slice = [_dispBuf sliceAtIndex:ix];
    [_view setZoom:_zoomFactor];
    [_view displayImageData:slice];
}

- (void)displayImage:(int)ix
{
	if (ix >= 0 && ix < [self nImages]) {
		[_numSlider setValue:ix];
		[self displayImage];
	}
	[_appControl imageChanged:self];
}

// update win/lev with current slider settings
- (void)updateWinLev
{
	[_view setWin:[_winSlider intValue]
			andLev:[_levSlider intValue]];
}

// relative change
- (void)changeWin:(int)w lev:(int)l from:sender
{
    [_winSlider changeValueBy:w];
    [_levSlider changeValueBy:l];
    if (w != 0 || l != 0) {
		[self updateWinLev];
		[self displayImage];
	}
}

- (IBAction)autoWinLev:(id)sender;
{
//	int		    i;
	int		    max_pix, min_pix;
	int		    win, lev;
	int		    ix = [_numSlider intValue];
	RecImage    *cur;

	if (_dispBuf == nil) return;
	cur = [_dispBuf sliceAtIndex:ix];
	
	min_pix = [cur minVal];
	max_pix = [cur maxVal];
	if (min_pix == max_pix) return;
	win = max_pix - min_pix;
	lev = (min_pix + max_pix) / 2;
	
    [_winSlider setValue:win];
    [_levSlider setValue:lev];
	[self updateWinLev];
	[self displayImage];
}

- (void)changeImage:(int)delta from:(id)sender
{
    if (delta != 0) {
		[_numSlider changeValueBy:delta];
		[self displayImage];
	}
	[_appControl imageChanged:self];
}

// action methods
- (IBAction)forward:(id)sender
{
	[self changeImage:1 from:self];
}

- (IBAction)backward:(id)sender
{
	[self changeImage:-1 from:self];
}

- (IBAction)sliderMoved:(id)sender
{
	switch ([(NSSlider *)sender tag]) {
	case 0:		// win
	case 1:		// lev
		[self updateWinLev];
		[self displayImage];
		break;
	default:	// Num
		[self displayImage];
		[_appControl imageChanged:self];
		break;
	}
}

- (IBAction)setInterp:(id)sender
{
	[_view setInterpolation:(BOOL)[(NSButton *)sender state]];
	[self displayImage];
}

- (IBAction)setSquare:(id)sender
{
	[_view setSquarePixel:(int)[(NSMenuItem *)[sender selectedCell] tag]];
    [_view setImageRect];
	[self displayImage];
}

- (IBAction)setFlip:(id)sender
{
//	[_view setFlipInView:(int)[(NSButton *)sender state]];
    if ([(NSButton *)sender state] == 1) {
        _flip = YES;
    } else {
        _flip = NO;
    }
    [self setDispBuf];
	[self displayImage];
}

- (IBAction)setRotate:(id)sender
{
//	[_view setRotateInView:(int)[(NSMenuItem *)[sender selectedCell] tag]];
    _rot = (int)[(NSMenuItem *)[sender selectedCell] tag];
    [self setDispBuf];
	[self displayImage];
}

- (IBAction)zoomIn:(id)sender
{
	_zoomFactor += 0.5;
	if (_zoomFactor > 4.0) _zoomFactor = 4.0;
	[_view setZoom:_zoomFactor];
    [_view clearCursor];
	[self displayImage];
}

- (IBAction)zoomOut:(id)sender
{
	_zoomFactor -= 0.5;
	if (_zoomFactor < 1.0) _zoomFactor = 1.0;
	[_view setZoom:_zoomFactor];
    [_view clearCursor];
	[self displayImage];
}

- (void)moveByX:(int)x andY:(int)y from:(id)sender
{
    [_view moveByX:x andY:y];
}

- (void)reportCursorAt:(NSPoint)pt from:(id)sender
{
    RecImage    *cur = [self selectedImage];
    float       *data;  // red
    int         x = pt.x;
    int         y = pt.y;
    int         xDim = [_dispBuf xDim];
    int         yDim = [_dispBuf yDim];
	int		    val;

	if (_dispBuf == nil) return;
    data = [cur data];

    if (x >= 0 && x < xDim &&
        y >= 0 && y < yDim) {
        val = data[y * xDim + x];

        // report cursor pos & value
        [_xField setIntValue:x];
        [_yField setIntValue:y];
        [_vField setIntValue:val];

        // draw cursor
        [_view setCursorAt:pt];
    } else {
        [_xField setIntValue:0];
        [_yField setIntValue:0];
        [_vField setIntValue:0];
        [_view clearCursor];
    }
    [_view display];
}

- (void)clearCursor
{
    [_view clearCursor];
    [_view display];
}

- (IBAction)startStopCine:(id)sender
{
    if ([(NSButton *)sender state] == NSOnState) {
        [self startTimer];
    } else {
        [self stopTimer];
    }
}

- (IBAction)colorModeChanged:(id)sender
{
	int		mode = (int)[(NSMenuItem *)[sender selectedCell] tag];
	[_view setColorMode:mode];
	[self displayImage];
	if (_scaleView) {
		[_scaleView initScale:64 withView:_view];
		[_scaleView display];
	}
}

- (IBAction)cursorModeChanged:(id)sender
{
	int		mode = (int)[(NSMenuItem *)[sender selectedCell] tag];
	[_view setCursorMode:mode];
	[_view display];		// erase cursor
}

- (void)startTimer
{
    if (_timer == nil) {
        _timer = [NSTimer
                    scheduledTimerWithTimeInterval:(1.0 / _frameRate)
                    target:self
               //     selector:(SEL)"cineStep" // stop working at 10.7
                    selector:@selector(cineStep)
                    userInfo:nil
                    repeats:YES];
    }
}

- (void)stopTimer
{
    if (_timer != nil) {
        [_timer invalidate];
    //    [_timer autorelease];
        _timer = nil;
    }
}

- (void)cineStep
{
    int			img = [_numSlider intValue];
    int         nImages = [self nImages];

    if (nImages < 2) return;
    if (_cineMode == 0) {	// space
        img += _cineDelta;
        if (img >= nImages) {
            img = nImages-1;
            _cineDelta = -1;
        }
        if (img < 0) {
            img = 0;
            _cineDelta = 1;
        }
        [_numSlider setValue:img];
        [self displayImage];
    } else {
        img += 1;
        if (img >= nImages) img = 0;
        [_numSlider setValue:img];
        [self displayImage];
    }
}

- (IBAction)cineModeChanged:(id)sender
{
    _cineMode = (int)[(NSMenuItem *)[sender selectedCell] tag];
    if (_timer != nil) {
        [self stopTimer];
        [self startTimer];
    }
}

- (IBAction)cpxModeChanged:(id)sender
{
    _cpxMode = (int)[(NSMenuItem *)[sender selectedCell] tag];
	[self setDispBuf];
    [self displayImage];
	[_appControl imageChanged:self];
}

- (IBAction)frameRateChanged:(id)sender
{
    int	tag = (int)[(NSMenuItem *)[sender selectedCell] tag];

    switch (tag) {
    case	0 :
        _frameRate = 5.0;
        break;
    case	1 :
    default :
        _frameRate = 10.0;
        break;
    case	2 :
        _frameRate = 20.0;
        break;
    case	3 :
        _frameRate = 40.0;
        break;
    case	4 :
        _frameRate = 60.0;
        break;
    }
    if (_timer != nil) {
        [self stopTimer];
        [self startTimer];
    }
}

- (IBAction)setLogP1:(id)sender
{
	_logP1 = [(NSButton *)sender state];
	[self setDispBuf];
	[self autoWinLev:self];
}

- (IBAction)reload:(id)sender
{
    [self loadImages];
}

// accessors
- (NSArray *)files
{
	return _files;
}

- (int)nImages
{
	return [_img zDim];
}

- (RecImage *)image
{
	return _img;
}

- (RecImage *)dispBuf
{
    return _dispBuf;
}

- (void)setImage:(RecImage *)img
{
    _img = img;
}

- (int)imageIndex
{
	return [_numSlider intValue];
}

- (KOImageView *)view
{
	return _view;
}

- (NSWindow *)window
{
	return _window;
}

//- (NSString *)currentDirectory
//{
//	return curDir;
//}

- (KOSlider *)winSlider
{
    return _winSlider;
}

- (KOSlider *)levSlider
{
    return _levSlider;
}

- (KOSlider *)numSlider
{
    return _numSlider;
}

- (KOProfControl *)profile
{
    return _profile;
}

- (int)cpxMode
{
    return _cpxMode;
}

- (int)imgType
{
    return _imgType;
}

- (int)tag;
{
    return _tag;
}

- (void)setTag:(int)aTag
{
    _tag = aTag;
}

//- (BOOL)logP1
//{
//	return _logP1;
//}

// Window delegate
- (void)windowWillClose:(NSNotification *)aNotification
{
//    NSLog(@"KOImageControl:windowWillClose");
    [self stopTimer];
    // this will release self
//    [[NSApp delegate] removeFromArray:self];
}

@end
