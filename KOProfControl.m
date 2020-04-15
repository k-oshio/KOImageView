/*
	KOProfControl.m
	
	controler obj for profile win
	7-3-1996	K. Oshio
*/

#import "KOProfControl.h"
#import "KOProfView.h"
#import "KOImageControl.h"

@implementation KOProfControl

- init
{
	self = [super init];
	_gain = 0.25;
	_offs = 0;
	_horizontal = 1;
	_zeroMean = 0;
	return self;
}

- setPoint:(int)x :(int)y :(int)val;
{
	[_xField setIntValue:x];
	[_yField setIntValue:y];
	[_valField setIntValue:val];
	return self;
}

//###   use dispBuf ... mag/phase etc are already calculated
//###   just use red channel for color modes
- (void)drawProfileAt:(NSPoint)pt from:(KOImageControl *)ctl
{
    KOImageControl  *control = ctl;
	RecImage    *img = [control image];
    RecImage    *slc = [control selectedImage];
//    int         cpxMode = [control cpxMode];

	float		*p, *q;
	int			i, xDim, yDim, nImg, n;
	int			x, y;
    int			di, dj;
    float		val, mx;
	float		re, im;
	NSString	*tmpString;
	char		tmpCstr[256];
    float       *buf;

	x = pt.x;
	y = pt.y;

	xDim = [img xDim];
	yDim = [img yDim];
	nImg = [img zDim];
 
 // report cursor at current slicer   
    p = [slc real];
	re = p[y * xDim + x];
	if ([img type] == RECIMAGE_COMPLEX) {
		q = [slc imag];
		im = q[y * xDim + x];
	} else {
		im = 0;
	}
	sprintf(tmpCstr, "%8.4e", re);
	tmpString = [NSString stringWithCString:tmpCstr encoding:NSUTF8StringEncoding];
	[_realField setStringValue:tmpString];
	sprintf(tmpCstr, "%8.4e", im);
	tmpString = [NSString stringWithCString:tmpCstr encoding:NSUTF8StringEncoding];
	[_imagField setStringValue:tmpString];

    switch (_horizontal) {
    case 0:	// vertical
		p = [slc data];
		n = yDim;
        buf = (float *)malloc(sizeof(float) * n);
		for (i = 0; i < yDim; i++) {
            buf[i] = 0;
            for (di = -_width; di < _width + 1; di++) {
                if (i + di >= 0 && i + di < xDim) {
                    buf[i] += p[(i + di) * xDim + x];
                }
            }
            buf[i] /= (_width * 2 + 1);
		}
        [self setPoint:x:y:p[y*xDim + x]];
        break;
    case 1:		// horizontal
		n = xDim;
        buf = (float *)malloc(sizeof(float) * n);
		for (i = 0; i < xDim; i++) {
            buf[i] = 0;
            for (di = -_width; di < _width + 1; di++) {
                if (i + di >= 0 && i + di < xDim) {
                    buf[i] += p[y * xDim + i + di];
                }
            }
            buf[i] /= (_width * 2 + 1);
		}
        [self setPoint:x:y:p[y*xDim + x]];
        break;
    case 2:		// time
		n = nImg;
        buf = (float *)malloc(sizeof(float) * n);
        p = [img data];
        for (i = 0; i < n; i++) {
            val = 0;
            for (di = - _width; di < _width + 1; di++) {
            for (dj = - _width; dj < _width + 1; dj++) {
                val += p[i * yDim * xDim + (y + di) * xDim + x + dj];
            }
            }
            buf[i] = val / (_width * 2 + 1) / (_width * 2 + 1);
        }
        [self setPoint:x:y:p[y * xDim + x]];
        break;
    }

	// remove baseline
	if (_zeroMean) {
		float mean = 0;
		for (i = 0; i < n; i++) {
			mean += buf[i];
		}
		mean /= n;
		for (i = 0; i < n; i++) {
			buf[i] -= mean;
		}
	}
 
    // scale
    mx = fmax([img maxVal], -[img minVal]);
    for (i = 0; i < n; i++) {
        buf[i] *= 1000.0 / mx;
    }

	[_profView setData:buf:n];
	[_profView display];
    free(buf);
}

- horButtonPressed:sender
{
	_horizontal = (int)[(NSButtonCell *)[sender selectedCell] tag];
	return self;
}

- widthChanged:sender
{
    _width = [_widthField intValue];
    return self;
}

- sliderMoved:sender
{
	_gain = [_gainSlider floatValue];
	_offs = [_offsSlider intValue];
	[_profView display];
	return self;
}

- meanButtonPressed:sender
{
	_zeroMean = [sender intValue];
	[_profView display];
	return self;
}

- (int)zeroMean
{
	return _zeroMean;
}

- (void)setHorizontal:(int)val
{
    _horizontal = val;
}

- (int)horizontal
{
	return _horizontal;
}

- (float)gain
{
	return _gain;
}

- (int)offs
{
	return _offs;
}

- (void) changeGain:(int)x offs:(int)y
{
    _gain += (float)x * 0.001;
    if (_gain < 0) _gain = 0;
    if (_gain > 1.0) _gain = 1.0;

    _offs += (float)y;
    if (_offs < -500) _offs= -500;
    if (_offs > 500) _offs = 500;

    [_gainSlider setFloatValue:_gain];
    [_offsSlider setFloatValue:_offs];
}

@end
