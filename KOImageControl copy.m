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

float
calc_max_val(KO_IMAGE **ff, int n)
{
    int     i, j;
    float   *p, *q, *p3;
    float   mx;

    mx = 0;
    for (i = 0; i < n; i++) {
		switch (ff[i]->type) {
        case KO_COMPLEX :
 //           mx = mx * mx;
            p = (float *)ff[i]->real[0];
            q = (float *)ff[i]->imag[0];
            for (j = 0; j < ff[i]->size; j++) {
				if (mx < fabs(p[j])) mx = fabs(p[j]);
				if (mx < fabs(q[j])) mx = fabs(q[j]);
            }
//            mx = sqrt(mx);
            break;
        case KO_REAL : 
            p = (float *)ff[i]->real[0];
            for (j = 0; j < ff[i]->size; j++) {
                if (fabs(p[j]) > mx) mx = fabs(p[j]);
            }
            break;
        case KO_COLOR :
            p = (float *)ff[i]->real[0];
            q = (float *)ff[i]->imag[0];
            p3 = (float *)ff[i]->p3[0];
            for (j = 0; j < ff[i]->size; j++) {
				if (mx < fabs(p[j])) mx = fabs(p[j]);
				if (mx < fabs(q[j])) mx = fabs(q[j]);
                if (mx < fabs(p3[i])) mx = fabs(p3[j]);
            }
            break;
        default :
            mx = max_val;
            break;
        }
    }

// if within this range, don't adjust
    if (mx > 400 && mx < 8000) {
        mx = max_val;
    }
	if (isnan(mx)) {
		mx = max_val;
	}
	if (isinf(mx)) {
		mx = max_val;
	}
    return mx;
}

// returns new color image. raw is freed.
// cpxMode   : 0:mag, 1:real, 2:imag, 3:phase, 4:phase color
// imageType : 0:integer image, 1:real(float) image, 2:complex iamge, 3:color(vector) image
// dispMode  : 0:integer -> real, 1:real -> real, 2:cpx -> mag, 3:cpx -> real, 4:cpx -> imag,
//              5:cpx -> p3, 6:cpx ->phase (real), 7:cpx->phase color, 8:color->color
KO_IMAGE *
cpx2real(KO_IMAGE *raw, int cpxMode, float f_max)
{
    KO_IMAGE    *col; // real or color image
    float       *r, *g, *b;
    float       *p, *q, *p3;
    short       *pi;
    int         i;
    float       mg, th;
    int         dispMode = 0;

    switch (raw->type) {
    case KO_INTEGER :
        dispMode = 0;
        break;
    case KO_REAL :
    default :
        dispMode = 1;
        break;
    case KO_COMPLEX:
        switch (cpxMode) {
        case 0 : // mag
            dispMode = 2;   // cpx->mg
            break;
        case 1 : // real
            dispMode = 3;   // cpx->real
            break;
        case 2 : // imag
            dispMode = 4;   // cpx->imag
            break;
        case 3 : // phase
            dispMode = 6;   // cpx->phase
            break;
        case 4 : // color
            dispMode = 7;   // cpx->color
            break;
        }
        break;
    case KO_COLOR:
        switch (cpxMode) {
        case 4 :
        default :
            dispMode = 8;   // rgb color
            break;
        case 0 :
        case 1 :
            dispMode = 3;   // real
            break;
        case 2 :
            dispMode = 4;   // imag;
            break;
        case 3 :
            dispMode = 5;   // p3
            break;
        }
        break;
    }

// alloc col (KO_IMAGE)
    if (dispMode == 7 || dispMode == 8) {
		col = new_image(raw->xdim, raw->ydim, KO_COLOR);
    } else {
		col = new_image(raw->xdim, raw->ydim, KO_REAL);
    }
// copy data
	switch (dispMode) {
	case 0 :	// integer
		r = (float *)col->real[0];
		pi = (short *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = pi[i];
        }
        break;
	case 1 :	// real
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p[i] * max_val / f_max;
        }
        break;
	case 2 :	// cpx -> mag
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = sqrt(p[i]*p[i] + q[i]*q[i]) * max_val / f_max;
        }
		break;
	case 3 :	// cpx -> real
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p[i] * max_val / f_max;
        }
		break;
	case 4 :	// cpx -> imag
		r = (float *)col->real[0];
		p = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p[i] * max_val / f_max;
        }
		break;
	case 5 :	// cpx -> p3
		r = (float *)col->real[0];
        p3 = (float *)raw->p3[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p3[i] * max_val / f_max;
        }
		break;
	case 6 :	// cpx -> phase
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			th = atan2(q[i], p[i]);
			r[i] = th * max_val / M_PI;
        }
		break;
	case 7 :	// phase color
		r = (float *)col->real[0];
		g = (float *)col->imag[0];
		b = (float *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			mg = p[i]*p[i] + q[i]*q[i];
			mg = sqrt(mg) / f_max;
			th = atan2(q[i], p[i]);
            // === new version (3-27-2013) ==
            if (th < - 2*M_PI/3) {
                r[i] = 0;
                g[i] = max_val * mg * 3 * (-2*M_PI/3 - th) / M_PI;
                b[i] = max_val * mg;
            } else
            if (th < - M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (th + 2*M_PI/3) / M_PI;
                g[i] = 0;
                b[i] = max_val * mg;
            } else
            if (th < 0) {
                r[i] = max_val * mg;
                g[i] = 0;
                b[i] = max_val * mg * 3 * (-th) / M_PI;
            } else
            if (th < M_PI/3) {
                r[i] = max_val * mg;
                g[i] = max_val * mg * 3 * (th) / M_PI;
                b[i] = 0;
            } else
            if (th < 2.0 * M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (2*M_PI/3 - th) / M_PI;
                g[i] = max_val * mg;
                b[i] = 0;
            } else {
                r[i] = 0;
                g[i] = max_val * mg;
                b[i] = max_val * mg * 3 * (th - 2*M_PI/3) / M_PI;
            }
        }
		break;
	case 8 :	// RGB color
		r = (float *)col->real[0];
		g = (float *)col->imag[0];
		b = (float *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        p3 = (float *)raw->p3[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p[i] * max_val / f_max;
            g[i] = q[i] * max_val / f_max;
            b[i] = p3[i] * max_val / f_max;
        }
		break;
	}
    free_image(raw);

    return col;
}

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

KO_IMAGE *
cpx2realX(KO_IMAGE *raw, int mode, float f_max)
{
    KO_IMAGE    *col = nil;
    short       *r = 0, *g = 0, *b = 0;
    float       *p, *q, *p3;
	short       *sp;
    int         i;
    float       mg, th1;
//    float   th2, th3;
    int         disp_mode = KO_REAL;;

// special cases
	if (raw->type == KO_REAL) {
		disp_mode = 5;
	}
	if (raw->type == KO_INTEGER) {
		disp_mode = 6;
	}
	if (raw->type == KO_COLOR) {
		disp_mode = 7;
	}

	switch (disp_mode) {
	case 0 :	// mag
	case 1 :	// real
	case 2 :	// imag
	case 3 :	// imag
	default :
		col = new_image(raw->xdim, raw->ydim, KO_INTEGER);
		r = (short *)col->real[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
		break;
	case 4 :	// phase color
		col = new_image(raw->xdim, raw->ydim, KO_COLOR);
		r = (short *)col->real[0];
		g = (short *)col->imag[0];
		b = (short *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
		break;
	case 5 :	//real -> real
		col = new_image(raw->xdim, raw->ydim, KO_INTEGER);
		r = (short *)col->real[0];
		p = (float *)raw->real[0];
		break;
	case 6 :	// integer -> real
		col = new_image(raw->xdim, raw->ydim, KO_INTEGER);
		r = (short *)col->real[0];
		sp = (short *)raw->real[0];
		break;
	case 7 :	// RGB color
		col = new_image(raw->xdim, raw->ydim, KO_COLOR);
		r = (short *)col->real[0];
		g = (short *)col->imag[0];
		b = (short *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
		p3 = (float *)raw->p3[0];
		break;
	}

	switch (disp_mode) {
	case 0:	// Mag
	default:
		for (i = 0; i < raw->size; i++) {
			mg = p[i]*p[i] + q[i]*q[i];
			mg = sqrt(mg) / f_max;
			r[i] = mg * max_val;    // max_val: constant
		}
		break;
	case 1:	// Re
		for (i = 0; i < raw->size; i++) {
			mg = p[i] / f_max;
			r[i] = mg * max_val;
		}
		break;
	case 5:	// real to real
		for (i = 0; i < raw->size; i++) {
			mg = p[i] / f_max;
			r[i] = mg * max_val;
		}
		break;
	case 6:	// int to real
		for (i = 0; i < raw->size; i++) {
			mg = sp[i] / f_max;
			r[i] = mg * max_val;
		}
		break;
	case 2:	// Im
		for (i = 0; i < raw->size; i++) {
			mg = q[i] / f_max;
			r[i] = mg * max_val;
		}
		break;
	case 3:	// Phs
		for (i = 0; i < raw->size; i++) {
			th1 = atan2(q[i], p[i]);
			r[i] = th1 * max_val / M_PI;
		}
		break;
	case 4:	// Phase color, mg -> brt, phs -> hue
		for (i = 0; i < raw->size; i++) {
			mg = p[i]*p[i] + q[i]*q[i];
			mg = sqrt(mg) / f_max;
			th1 = atan2(q[i], p[i]);
            /*
			th2 = th1 + 2 * M_PI / 3;
			th3 = th1 + 4 * M_PI / 3;
            // === sensitivity-adjusted ===
			r[i] = (0.5 * cos(th1) + 0.5) * max_val * mg * 0.4; // 0.5
			g[i] = (0.5 * cos(th2) + 0.5) * max_val * mg * 0.3; // 0.6
			b[i] = (0.5 * cos(th3) + 0.5) * max_val * mg * 1.0; // 1.0
            */
            // === new version (3-27-2013) ==
            if (th1 < - 2*M_PI/3) {
                r[i] = 0;
                g[i] = max_val * mg * 3 * (-2*M_PI/3 - th1) / M_PI;
                b[i] = max_val * mg;
            } else
            if (th1 < - M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (th1 + 2*M_PI/3) / M_PI;
                g[i] = 0;
                b[i] = max_val * mg;
            } else
            if (th1 < 0) {
                r[i] = max_val * mg;
                g[i] = 0;
                b[i] = max_val * mg * 3 * (-th1) / M_PI;
            } else
            if (th1 < M_PI/3) {
                r[i] = max_val * mg;
                g[i] = max_val * mg * 3 * (th1) / M_PI;
                b[i] = 0;
            } else
            if (th1 < 2.0 * M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (2*M_PI/3 - th1) / M_PI;
                g[i] = max_val * mg;
                b[i] = 0;
            } else {
                r[i] = 0;
                g[i] = max_val * mg;
                b[i] = max_val * mg * 3 * (th1 - 2*M_PI/3) / M_PI;
            }
		}
		break;
	case 7:	// RGB Color
		for (i = 0; i < raw->size; i++) {
			r[i] = p[i] * max_val;
			g[i] = q[i] * max_val;
			b[i] = p3[i] * max_val;
		}
		break;
	}
    free_image(raw);
    return col;
}

@implementation KOImageControl

- (id)initFromNib
{
	NSArray	*objs;
	self = [self init];
//    [NSBundle loadNibNamed:@"ImageBrowser" owner:self];
	[[NSBundle mainBundle] loadNibNamed:@"ImageBrowser" owner:self topLevelObjects:&objs];

	return self;
}

- (id)init
{
	self = [super init];
    _files = nil;
	_f = origArray = alteredArray = NULL;
	_nImages = 0;
    _timer = nil;
    _cineMode = 0;	// space
    _cineDelta = 1;
    _frameRate = 10.0;	// fps
	_cpxMode = 0;
	_zoomFactor = 1.0;

	return self;
}

- (void)dealloc
{
	int	i;

//    NSLog(@"KOImageControl:dealloc");
    if (_f) {
        for (i = 0; i < _nImages; i++) {
            free_image(_f[i]);
        }
        free(_f);
    }
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
//	curDir = [[(KOImageControl *)[[NSApp keyWindow] delegate] currentDirectory] copy];
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

// not done yet ######
- (void)openRawXDim:(int)xDim yDim:(int)yDim zDim:(int)zDim
		size:(int)size order:(int)order type:(int)type
{
	int			sts;
	int			len;
	NSString	*path;
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];

	[openPanel setAllowsMultipleSelection:NO];
    sts = [openPanel runModal];
    if (sts != NSModalResponseOK) return;
    _files = [openPanel URLs];
printf("openRaw::: not done yet ###\n", xDim, yDim, zDim);
printf("x/y/z = %d/%d/%d\n", xDim, yDim, zDim);
return;

// load raw image ###
//	[self loadImages];

// initially invisible
	path = [[[openPanel URLs] objectAtIndex:0] path];
	len = [path length];
	len -= 40;
	if (len < 0) len = 0;
	path = [path substringFromIndex:len];
	[_window setTitle:path];
    [_window makeKeyAndOrderFront:self];
}

// ### RecImage methods
// ### remove KO_IMAGE
- (KO_IMAGE **)koImageWithRecImage:(RecImage *)rec nImg:(int *)n
{
	KO_IMAGE		**ko;
	int				xdim, ydim, zdim;
	int				i, ix, k, dataLen;	// i:xy index:[0..dataLen-1], k:z index
	int				type, koType;
	float			*p, *data;

	type = [rec type];
	data = [rec data];
	switch (type) {
	case RECIMAGE_REAL :
	default :
		koType = KO_REAL;
		break;
	case RECIMAGE_COMPLEX :
	case RECIMAGE_MAP :
		koType = KO_COMPLEX;
		break;
	}
	xdim = [rec xDim];
	ydim = [rec yDim];
//	zdim = [rec outerLoopDim];
	zdim = [rec nImages];
	ko = new_image_array(xdim, ydim, koType, zdim);
	// copy data
	dataLen = xdim * ydim;
	ix = 0;
	for (k = 0; k < zdim; k++) {
		p = ko[k]->real[0];
		for (i = 0; i < dataLen; i++) {
			p[i] = data[ix++];
		}
	}
	if (koType == KO_COMPLEX) {
		for (k = 0; k < zdim; k++) {
			p = ko[k]->imag[0];
			for (i = 0; i < dataLen; i++) {
				p[i] = data[ix++];
			}
		}
	}
	*n = zdim;
	return ko;
}

- (RecImage *)recImageWithKOImage:(KO_IMAGE **)f nImg:(int)n
{
	RecImage	*img;
	int			type;
	int			koType;
	float		*p, *data;
	int			i, k, ix, dataLen;

	if (f == NULL) return NULL;
	koType = f[0]->type;

	switch (koType) {
	case KO_REAL :
	default :
		type = RECIMAGE_REAL;
		break;
	case KO_COMPLEX :
		type = RECIMAGE_COMPLEX;
		break;
	}
	img = [RecImage imageOfType:type xDim:f[0]->xdim yDim:f[0]->ydim zDim:n];
	data = [img data];
	dataLen = [img xDim] * [img yDim];

	ix = 0;
	for (k = 0; k < n; k++) {
		p = f[k]->real[0];
		for (i = 0; i < dataLen; i++) {
			data[ix++] = p[i];
		}
	}
	if (koType == KO_COMPLEX) {
		for (k = 0; k < n; k++) {
			p = f[k]->imag[0];
			for (i = 0; i < dataLen; i++) {
				data[ix++] = p[i];
			}
		}
	}
	
	return img;
}

- (void)setImage:(RecImage *)img
{
	KO_IMAGE	**f;
	int			nImg;

	nImg = [img zDim];
	f = [self koImageWithRecImage:img nImg:&nImg];
	[self setImages:f nImages:nImg];
}

- (RecImage *)recImages
{
	RecImage	*img;
	img = [self recImageWithKOImage:_f nImg:_nImages];
	return img;
}

- (RecImage *)selectedImage
{
	RecImage	*img;
	KO_IMAGE	**f;
	int			ix;

	f = [self images];
	ix = [self imageIndex];
	img = [self recImageWithKOImage:f + ix nImg:1];

	return img;
}
// ### RecImage methods

- (void)loadImages
{
//    const char *path;
	int			i, n;
	KO_IMAGE	**f = NULL;
    float       f_max_val = 0;
//    float       tmp_thres = 1.0e30;
//    float       tmp_inv = 1.0e-30;
	RecImage	*img;	// testing ... ###
//    int			xdim, ydim;

// load images -> f
	n = (int)[_files count];
	if (_indicator) {
		[_indicator setPercentage:0];
		[_indicator setTitle:@"Loading..."];
		[_indicator show:self];
	}

//
//	### rewrite below part ...
//		supported formats are:
//			image_block, single KOImage, RecImage, DICOM
// 1. implement imageWithOldImage: in RecKit
// 2. rewrite KOImageControl using RecImage (remove KO_IMAGE)
//

    // RecImage
	if ((img = [RecImage imageFromFile:[[_files objectAtIndex:0] path] relativePath:NO])) {
		// convert to KOImage
		f = [self koImageWithRecImage:img nImg:&n];
        f_max_val = calc_max_val(f, n);
        for (i = 0; i < n; i++) {
			_cpx = (f[i]->type == KO_COMPLEX);
			f[i] = [self cpx2real:f[i] mode:_cpxMode max:f_max_val];
        }
	} else
	// KO_IMAGE (saved by RecKit)
	if ((img = [RecImage imageWithKOImage:[[_files objectAtIndex:0] path]])) {
		// convert to KOImage
		f = [self koImageWithRecImage:img nImg:&n];
        f_max_val = calc_max_val(f, n);
        for (i = 0; i < n; i++) {
			_cpx = (f[i]->type == KO_COMPLEX);
			f[i] = [self cpx2real:f[i] mode:_cpxMode max:f_max_val];
        }
	} else
	// DICOM
	if ((img = [RecImage imageWithDicomFiles:_files])) {
		// convert to KOImage
		f = [self koImageWithRecImage:img nImg:&n];
        f_max_val = calc_max_val(f, n);
        for (i = 0; i < n; i++) {
			_cpx = (f[i]->type == KO_COMPLEX);
			f[i] = [self cpx2real:f[i] mode:_cpxMode max:f_max_val];
        }
	}
/* implement below part in RecImage
	else
	// block (saveAsKOImage:)
    if ((f = get_image_block((char *)[[[_files objectAtIndex:0] path] UTF8String], &i)) != NULL) { 
        n = i;
        f_max_val = calc_max_val(f, n);
        if ((f_max_val > tmp_thres) || (f_max_val < -tmp_thres)) {
            for (i = 0; i < n; i++) {
                mul_image(f[i], tmp_inv);
            }
            f_max_val *= tmp_inv;
        }
        for (i = 0; i < n; i++) {
			_cpx = (f[i]->type == KO_COMPLEX);
		//	f[i] = cpx2real(f[i], _cpxMode, f_max_val);
			f[i] = [self cpx2real:f[i] mode:_cpxMode max:f_max_val];
        }
    } else {
		// multiple KO_IMAGE
        // if get_image fails, empty image (null pointer) is inserted
        f = (KO_IMAGE **)malloc(sizeof(KO_IMAGE *) * n);
		_cpx = YES;
    //    f_max_val = calc_max_val(f, n);
        for (i = 0; i < n; i++) {
            path = [[[_files objectAtIndex:i] path] UTF8String];
            // ========= get image =======
            f[i] = get_any_image((char *)path);
            if (_indicator) [_indicator setPercentage: i * 100.0 / n];
			f_max_val = calc_max_val(f+i, 1);
		//	f[i] = cpx2real(f[i], _cpxMode, f_max_val);
			f[i] = [self cpx2real:f[i] mode:_cpxMode max:f_max_val];
        }
	}
*/
	if (_indicator) [_indicator hide:self];

// if not successfull, do nothing and keep old images
	if (n <= 0 || f == NULL || f[0] == NULL) return;

	[self setImages:f nImages:n];
}

- (void)setImages:(KO_IMAGE **)f nImages:(int)n
{
	int		xdim, ydim;
	int		i;

// free old images
	if (origArray != NULL) {
			for (i = 0; i < _nImages; i++) {
				free_image(origArray[i]);
			}
			free(origArray);
			if (alteredArray) free(alteredArray);
	}

// set i-var
    _f = origArray = f;
	_nImages = n;
	alteredArray = (KO_IMAGE **)malloc(sizeof(KO_IMAGE *) * n);

// update n-slider (before displayImage)
	[_numSlider setMin:0 andMax:n-1];
	[_numSlider setValue:0];

// set view
// bug... view doesn't know size of each image (if different)
    xdim = ydim = 0;
    for (i = 0; i < n; i++) {
        if (xdim < f[i]->xdim) xdim = f[i]->xdim;
        if (ydim < f[i]->ydim) ydim = f[i]->ydim;
    }
	[_view initImage:xdim:ydim];
	[self updateWinLev];
	[self displayImage];
	if (_scaleView) {
		[_scaleView initScale:64 withView:_view];
		[_scaleView display];
	}
}

- (void)saveSingle
{
	NSSavePanel	*savePanel = [NSSavePanel savePanel];
	NSString	*path;
	int			sts;
	int			ix = [_numSlider intValue];
	
	if (!savePanel) savePanel = [NSSavePanel savePanel];
//	sts = [savePanel runModalForDirectory:NSHomeDirectory() file:nil];
    sts = [savePanel runModal];
	if (sts != NSModalResponseOK) {
		return;
	} else {
		path = [[savePanel URL] path];
	}
	put_image(_f[ix], (char *)[path UTF8String]);  
}

/*
typedef struct {
	int				magic;	// KO_MAGIC3
	int				type;
	int				xdim;
	int				ydim;
	int				zdim;
	int				fill[3];
}	KO_HDR3;	// 32 bytes
- (void)saveAsKOImageX
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSString    *path;
	int         sts;
	
	if (!savePanel) savePanel = [NSSavePanel savePanel];
    sts = [savePanel runModal];
	if (sts != NSOKButton) {
		return;
	} else {
		path = [[savePanel URL] path];
	}

// rewrite below (remove image lib)
	put_image_block(_f, (char *)[path UTF8String], _nImages);  
}
*/

// ## complex case doesn't work (converted to real when loaded)
- (void)saveAsKOImage
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSString    *path;
    FILE        *fp;
	int         sts;
    int         i, j, size, type;
    float       *buf;
    short       *p;
    KO_HDR3     hdr3;

	if (!savePanel) savePanel = [NSSavePanel savePanel];
    sts = [savePanel runModal];
	if (sts != NSModalResponseOK) {
		return;
	} else {
		path = [[savePanel URL] path];
	}

// rewrite below (remove image lib)
//	put_image_block(_f, (char *)[path UTF8String], _nImages);  

	hdr3.magic = 0x494d3344;	// 	"IM3D"
    hdr3.type = _f[0]->type;
    hdr3.xdim = _f[0]->xdim;
    hdr3.ydim = _f[0]->ydim;
    hdr3.zdim = _nImages;

    size = _f[0]->size;
    buf = (float *)malloc(sizeof(float) * size);
    type = hdr3.type;
    if (type == KO_INTEGER) {
        hdr3.type = KO_REAL;
    }

    fp = fopen((char *)[path UTF8String], "w");
    if (fp != NULL) {
        fwrite(&hdr3, sizeof(KO_HDR3), 1, fp);
        switch (type) {
        case    KO_INTEGER :
            for (i = 0; i < _nImages; i++) {
                p = (short *)_f[i]->real[0];
                for (j = 0; j < size; j++) {
                    buf[j] = p[j];
                }
                fwrite(buf, sizeof(float), size, fp);
            }
            break;
        case    KO_REAL :
            for (i = 0; i < _nImages; i++) {
                fwrite((float *)(_f[i]->real[0]), sizeof(float), size, fp);
            }
            break;
        case    KO_COMPLEX :
            for (i = 0; i < _nImages; i++) {
                fwrite((float *)(_f[i]->real[0]), sizeof(float), size, fp);
            }
            for (i = 0; i < _nImages; i++) {
                fwrite((float *)(_f[i]->imag[0]), sizeof(float), size, fp);
            }
            break;
        }
        fclose(fp);
        free(buf);
    }
}

/* Save As TIFF (TIFF works after 10.1)
- (void)saveImageAsTIFF
{
	NSSavePanel	*savePanel = [NSSavePanel savePanel];
	NSData		*data;
	NSString	*path, *path2;
	int			sts;
	
	if (!savePanel) savePanel = [NSSavePanel savePanel];
//	sts = [savePanel runModalForDirectory:NSHomeDirectory() file:nil];
    sts = [savePanel runModal];
	if (sts != NSOKButton) {
		return;
	} else {
		path = [[savePanel URL] path];
		path2 = [NSString stringWithFormat:@"%@.tiff", path];
		data = [[_view imageRep] TIFFRepresentation];
		[data writeToFile:path2 atomically:YES];
	}   
}
*/

// Save All Images as PDF
- (void)saveAllAsPDF
{
	NSSavePanel	*savePanel = [NSSavePanel savePanel];
	NSData		*data;
	NSString	*path, *path2;
	int			i, sts;
	
	if (!savePanel) savePanel = [NSSavePanel savePanel];
//	sts = [savePanel runModalForDirectory:NSHomeDirectory() file:nil];
    sts = (int)[savePanel runModal];
	if (sts != NSModalResponseOK) {
		return;
	} else {
		path = [[savePanel URL] path];
		for (i = 0; i < _nImages; i++) {
			// make path
			path2 = [NSString stringWithFormat:@"%@%03d.tiff", path, i];
		//	path2 = [NSString stringWithFormat:@"%@%03d.pdf", path, i];
			[_view displayImageData:(float *)_f[i]->real[0]];
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
	int		ix = [_numSlider intValue];
	if (_f != NULL && _f[ix] != NULL) {
        switch (_f[ix]->type) {
        case KO_REAL :
            [_view displayImageData:(float *)_f[ix]->real[0]];
            break;
        case KO_COLOR :
            [_view displayColorImage:(float *)_f[ix]->real[0]
                                    :(float *)_f[ix]->imag[0]
                                    :(float *)_f[ix]->p3[0]];
            break;
        default :
            [_view displayImageData:NULL];
            break;
        }
	} else {
		[_view displayImageData:NULL];
	}
}

- (void)displayImage:(int)ix
{
	if (ix >= 0 && ix < _nImages) {
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
	int		i;
	int		max_pix, min_pix;
	int		win, lev;
	int		ix = [_numSlider intValue];
	short	*sp;
	float	*p;
//	short	*p = (short *)_f[ix]->real[0];

	if (_f == NULL) return;
	min_pix = max_pix = 0;
	if (_f[0]->type == KO_INTEGER) {
		sp = (short *)_f[ix]->real[0];
		for (i = 0; i < _f[0]->size; i++) {
			if (sp[i] < min_pix) min_pix = sp[i];
			if (sp[i] > max_pix) max_pix = sp[i];
		}
	} else {
		p = (float *)_f[ix]->real[0];
		for (i = 0; i < _f[0]->size; i++) {
			if (p[i] < min_pix) min_pix = p[i];
			if (p[i] > max_pix) max_pix = p[i];
		}
	}
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
	[_view setFlipInView:(int)[(NSButton *)sender state]];
	[self displayImage];
}

- (IBAction)setRotate:(id)sender
{
	[_view setRotateInView:(int)[(NSMenuItem *)[sender selectedCell] tag]];
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
	int		ix = [_numSlider intValue];
    int     x = pt.x;
    int     y = pt.y;
	int		val;

	if (_f == NULL || _f[ix] == NULL) return;

    if (x >= 0 && x < _f[ix]->xdim &&
        y >= 0 && y < _f[ix]->ydim) {
        val = ((float *)_f[ix]->real[y])[x];

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

    if (_nImages < 2) return;
    if (_cineMode == 0) {	// space
        img += _cineDelta;
        if (img >= _nImages) {
            img = _nImages-1;
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
        if (img >= _nImages) img = 0;
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
	[self loadImages];
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
	[self loadImages];
	[self autoWinLev:self];
}

// accessors
- (NSArray *)files
{
	return _files;
}

- (KO_IMAGE **)images
{
	return _f;
}

- (int)nImages
{
	return _nImages;
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

- (KO_IMAGE *)cpx2real:(KO_IMAGE *)raw mode:(int)cpxMode max:(float)f_max
{
    KO_IMAGE    *col; // real or color image
    float       *r, *g, *b;
    float       *p, *q, *p3;
	float		re, im;
    short       *pi;
    int         i;
    float       mg, th;
    int         dispMode = 0;

    switch (raw->type) {
    case KO_INTEGER :
        dispMode = 0;
        break;
    case KO_REAL :
    default :
        dispMode = 1;
        break;
    case KO_COMPLEX:
        switch (cpxMode) {
        case 0 : // mag
            dispMode = 2;   // cpx->mg
            break;
        case 1 : // real
            dispMode = 3;   // cpx->real
            break;
        case 2 : // imag
            dispMode = 4;   // cpx->imag
            break;
        case 3 : // phase
            dispMode = 6;   // cpx->phase
            break;
        case 4 : // color
            dispMode = 7;   // cpx->color
            break;
        }
        break;
    case KO_COLOR:
        switch (cpxMode) {
        case 4 :
        default :
            dispMode = 8;   // rgb color
            break;
        case 0 :
        case 1 :
            dispMode = 3;   // real
            break;
        case 2 :
            dispMode = 4;   // imag;
            break;
        case 3 :
            dispMode = 5;   // p3
            break;
        }
        break;
    }

// alloc col (KO_IMAGE)
    if (dispMode == 7 || dispMode == 8) {
		col = new_image(raw->xdim, raw->ydim, KO_COLOR);
    } else {
		col = new_image(raw->xdim, raw->ydim, KO_REAL);
    }
// copy data
	switch (dispMode) {
	case 0 :	// integer
		r = (float *)col->real[0];
		pi = (short *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = pi[i];
        }
        break;
	case 1 :	// real
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
			if (_logP1) {
				re = lp1(p[i]);
			} else {
				re = p[i];
			}
            r[i] = re * max_val / f_max;
        }
        break;
	case 2 :	// cpx -> mag
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			if (_logP1) {
				re = lp1(p[i]);
				im = lp1(q[i]);
			} else {
				re = p[i];
				im = q[i];
			}
            r[i] = sqrt(re*re + im*im) * max_val / f_max;
        }
		break;
	case 3 :	// cpx -> real
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
        for (i = 0; i < raw->size; i++) {
			if (_logP1) {
				re = lp1(p[i]);
			} else {
				re = p[i];
			}
            r[i] = re * max_val / f_max;
        }
		break;
	case 4 :	// cpx -> imag
		r = (float *)col->real[0];
		p = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			if (_logP1) {
				im = lp1(p[i]);
			} else {
				im = p[i];
			}
            r[i] = im * max_val / f_max;
        }
		break;
	case 5 :	// cpx -> p3
		r = (float *)col->real[0];
        p3 = (float *)raw->p3[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p3[i] * max_val / f_max;
        }
		break;
	case 6 :	// cpx -> phase
		r = (float *)col->real[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			th = atan2(q[i], p[i]);
			r[i] = th * max_val / M_PI;
        }
		break;
	case 7 :	// phase color
		r = (float *)col->real[0];
		g = (float *)col->imag[0];
		b = (float *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        for (i = 0; i < raw->size; i++) {
			mg = p[i]*p[i] + q[i]*q[i];
			mg = sqrt(mg) / f_max;
			th = atan2(q[i], p[i]);
            // === new version (3-27-2013) ==
            if (th < - 2*M_PI/3) {
                r[i] = 0;
                g[i] = max_val * mg * 3 * (-2*M_PI/3 - th) / M_PI;
                b[i] = max_val * mg;
            } else
            if (th < - M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (th + 2*M_PI/3) / M_PI;
                g[i] = 0;
                b[i] = max_val * mg;
            } else
            if (th < 0) {
                r[i] = max_val * mg;
                g[i] = 0;
                b[i] = max_val * mg * 3 * (-th) / M_PI;
            } else
            if (th < M_PI/3) {
                r[i] = max_val * mg;
                g[i] = max_val * mg * 3 * (th) / M_PI;
                b[i] = 0;
            } else
            if (th < 2.0 * M_PI / 3.0) {
                r[i] = max_val * mg * 3 * (2*M_PI/3 - th) / M_PI;
                g[i] = max_val * mg;
                b[i] = 0;
            } else {
                r[i] = 0;
                g[i] = max_val * mg;
                b[i] = max_val * mg * 3 * (th - 2*M_PI/3) / M_PI;
            }
        }
		break;
	case 8 :	// RGB color
		r = (float *)col->real[0];
		g = (float *)col->imag[0];
		b = (float *)col->p3[0];
		p = (float *)raw->real[0];
		q = (float *)raw->imag[0];
        p3 = (float *)raw->p3[0];
        for (i = 0; i < raw->size; i++) {
            r[i] = p[i] * max_val / f_max;
            g[i] = q[i] * max_val / f_max;
            b[i] = p3[i] * max_val / f_max;
        }
		break;
	}
    free_image(raw);

    return col;
}

// reordering
- (void)reorderWithSize:(int)size
{
	int			i, ix, nPhs, phs, slc;

	if ((_nImages % size) != 0) return;

	// set reordered array (already allocated)
	nPhs = _nImages / size;
	for (i = 0; i < _nImages; i++) {
		phs = i / size;
		slc = i % size;
		ix = slc * nPhs + phs;
		
		alteredArray[ix] = origArray[i];
	}
	_f = alteredArray;
}

- (void)revertOrder
{
	_f = origArray;
}

@end
