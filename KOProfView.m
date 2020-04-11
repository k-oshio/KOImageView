/*
	KOProfView.m

	profile view
	7-3-1996		K. Oshio
	7-13-2000       NSBezierPath/NSColor
    9-02-2004       ProfView -> KOProfView

 */

#import "KOImageControl.h"
#import "KOProfControl.h"
#import "KOProfView.h"

@implementation KOProfView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    _nData = 0;
    _plotData = NULL;
    return self;
}

//- (void)dealloc
//{
//    if (_plotData) free(_plotData);
//    [super dealloc];
//}

- (id)setData:(float *)buf :(int)n
{
	int i;

    if (n != _nData) {
        if (_plotData) free(_plotData);
        _plotData = (float *)malloc(sizeof(float) * n);
        _nData = n;
    }

    switch ([_control horizontal]) {
    case 0:		// vertical
		for (i = 0; i < n; i++) {
			_plotData[i] = buf[i];
        }
        break;
    case 1:		// horizontal
		for (i = 0; i < n; i++) {
			_plotData[i] = buf[i];
		}
        break;
    case 2:		// time
		for (i = 0; i < n; i++) {
			_plotData[i] = buf[i];
        }
        break;
    }
	return self;
}

- (void)drawRect:(NSRect)rects
{
	int				i;
	float			step;
	NSRect			bb;
	NSBezierPath	*path;
	NSPoint			pt;
	float			gain = [_control gain];
	int				offs = [_control offs];
	float			mean;
	float			sp = 5.0;

	if (![self canDraw]) return;
	if (_nData == 0) return;

	bb = [self bounds];

	/* clear */
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:bb];

	/* zero-mean */
	mean = 0;
	if ([_control zeroMean]) {
		for (i = 0; i < _nData; i++) {
			mean += _plotData[i];
		}
		mean /= _nData;
	}

	/* draw */
	path = [NSBezierPath bezierPath];
	[path removeAllPoints];
	pt.x = sp;
	pt.y = (_plotData[0] - mean) * gain + offs;
	[path moveToPoint:pt];
	step = (bb.size.width - sp*2) / _nData;
	for (i = 1; i < _nData; i++) {
		pt.x = i * step + sp;
		pt.y = (_plotData[i] - mean) * gain + offs;
		[path lineToPoint:pt];
	}
	[[NSColor darkGrayColor] set];
	[path setLineWidth:1.0];
	[path stroke];

	// x axis
	[path removeAllPoints];
	pt.x = 0;
	pt.y = offs;
	[path moveToPoint:pt];
    pt.x = bb.size.width;
    [path lineToPoint:pt];
    [[NSColor lightGrayColor] set];
    [path setLineWidth:1.0];
    [path stroke];

	return;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
	return YES;
}

- (BOOL)resignFirstResponder
{
	return YES;
}

- (id)copy:(id)sender
{
	NSPasteboard	*pb;
    NSString		*tmpString;
    int				i;

	pb = [NSPasteboard generalPasteboard]; // existing pb
	[pb declareTypes:[NSArray arrayWithObjects:
                NSStringPboardType,
				nil] owner:nil];

    tmpString = [[NSString alloc] init];
    for (i = 0; i < _nData; i++) {
    //    tmpString = [tmpString stringByAppendingFormat: @"%d %f\n", i, _plotData[i]];
        tmpString = [tmpString stringByAppendingFormat: @"%f\n", _plotData[i]];
    }
	[pb setString:tmpString forType:NSStringPboardType];

	return self;
}

// cursor event
- (void)mouseDown:(NSEvent *)thisEvent
{
	[self cursorEvent:thisEvent initial:YES];
}

- (void)mouseDragged:(NSEvent *)thisEvent
{
	[self cursorEvent:thisEvent initial:NO];
}

- (void)cursorEvent:(NSEvent *)theEvent initial:(BOOL)initflag
{
    int             x = 0, y = 0;
    static int      oldX, oldY;
    NSPoint         whereInWindow = [theEvent locationInWindow];

    if (initflag == YES) {
        oldX = whereInWindow.x;
        oldY = whereInWindow.y;
    }
    x = whereInWindow.x - oldX;
    y = whereInWindow.y - oldY;
    if (x != 0 || y != 0) {
        [_control changeGain:x offs:y];
        [self display];
    }
    oldX = whereInWindow.x;
    oldY = whereInWindow.y;
}

@end
