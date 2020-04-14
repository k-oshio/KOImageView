/*

	KOImageView.h
	8-9-2001	ImageView -> KOImageView 	K. Oshio

*/

#import <Cocoa/Cocoa.h>
#import "KOImageControl.h"

#define COLOR_MODE_GRAY		0
#define COLOR_MODE_INV		1
#define COLOR_MODE_TRI		2
#define COLOR_MODE_COLOR1	3   // GE
#define COLOR_MODE_COLOR2	4   // heat
#define COLOR_MODE_COLOR3	5   // red / blue

@class RecImage;

#define LUTSIZE 32768	/* 14bit data + sign */

@interface KOImageView:NSView
{
// IB outlet
	IBOutlet id			_control;
//
	int					_colorMode;		// gray / pseudo_color (1, 2) / triangle etc
    int					_cursorMode;	// win / pos / image
// image
	//int					_imageMode;		// 0: 12bit, 1: 36bit color
	NSBitmapImageRep	*_bitmap;		// place to store "image" (24bit)
	NSBitmapImageRep	*_over;			// overlay (24bit)
	BOOL				_overlayOn;
	int					_xdim;			// image size
	int					_ydim;			// image size
	float				_zoomFactor;
	NSRect				_imageRect;
	BOOL				_flipped;
	BOOL				_interp;		// anti-aliasing
	float				_aspect;
// win/lev LUT (12 bit -> 8 bit)
	unsigned char		winLevTab[LUTSIZE];
// color LUT (8bit -> pseudo color)
	int					_r[256];
	int					_g[256];
	int					_b[256];
// frame marker
	BOOL				_isFirstResponder;
// cross-hair cursor
	BOOL				_lineXOn;
	BOOL				_lineYOn;
	int					_lineX;			// in view coordinates
	int					_lineY;			// in view coordinates
// ID
	int					_tag;
}

- (KOImageView *)initWithFrame:(NSRect)frameRect;
- (void)initImage:(int)xdim :(int)ydim;
- (void)enableOver:(BOOL)on;
- (void)setFlipInView:(int)flip;
- (void)setRotateInView:(int)angle;
- (void)setInterpolation:(BOOL)flag;
- (void)displayImageData:(RecImage *)img;
- (void)setColorMode:(int)mode;
- (void)setCursorMode:(int)mode;
- (void)setWin:(int)win andLev:(int)lev;
- (void)setLUT;
- (void)setZoom:(float)zoom;
- (void)setImageRect;
- (void)setSquarePixel:(int)tag;
- (float)zoomFactor;
- (int *)rdata;
- (int *)gdata;
- (int *)bdata;
- (void)clearCursor;
- (void)setCursorAt:(NSPoint)pt;
- (void)moveByX:(int)x andY:(int)y;
- (void)setTag:(int)tag;
//- (int)tag;
- (NSBitmapImageRep *)imageRep;
- (NSBitmapImageRep *)overlay;
- (id)control;
- (NSPoint)pointInImage:(NSPoint)whereInView;
- (NSPoint)pointInView:(NSPoint)whereInImage;

@end
