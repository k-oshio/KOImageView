/*
	KOImageControl.h
	image disp control object

	K. Oshio
	3-6-1996	Initial (Disp/DidpWin -> ImageControl)

*/

#import <Cocoa/Cocoa.h>

//#import "KOImageView.h"
#import "KOScaleView.h"
#import "KOSlider.h"
#import "KOIndicator.h"
#import "KOProfControl.h"
#import "KOWindowControl.h"

//#import "image.h"   // remove image lib dependency

@class KOImageView;
//@class KOWindowControl;
@class RecImage;

@interface KOImageControl:NSObject
{
// outlets
	IBOutlet id					_view;
	IBOutlet id					_scaleView;
	IBOutlet id					_profile;
	IBOutlet KOWindowControl	*_appControl;
	IBOutlet NSWindow			*_window;
	IBOutlet KOSlider			*_winSlider;
	IBOutlet KOSlider			*_levSlider;
	IBOutlet KOSlider			*_numSlider;
	IBOutlet NSTextField		*_xField;
	IBOutlet NSTextField		*_yField;
	IBOutlet NSTextField		*_vField;
	IBOutlet KOIndicator		*_indicator;

// image file type
	BOOL		rawImage;

// image data
	NSArray     *_files;
	RecImage	*_img;      // image in file is kept unchanged (cpx)
    RecImage    *_dispBuf;  // scaled color image for display
    float       _dispScale;

// cine loop
    NSTimer     *_timer;
    float       _frameRate;
    int         _cineMode;
    int         _cineDelta;

// zoom / pan
	float       _zoomFactor;

// flip / rot
    BOOL        _flip;  // YES, NO
    int         _rot;   // 0:off, 1:90, 2:180, 3:270

// complex display mode
	int         _cpxMode;	// 0:Mag, 1:Re, 2:Im, 3:Phs, 4:color
    int         _imgType;   // RECIMAGE_REAL, RECIMAGE_COMPLEX, RECIMAGE_COLOR
	BOOL		_logP1;

// ID
	int         _tag;
}

- (id)init;
- (id)initFromNib;

- (void)open;
//- (void)saveImageAsTIFF;
- (void)saveAllAsPDF;
//- (void)saveSingle;
- (void)saveAsKOImage;   // 3D
- (IBAction)forward:(id)sender;
- (IBAction)backward:(id)sender;
- (IBAction)sliderMoved:(id)sender;
- (IBAction)setInterp:(id)sender;
- (IBAction)setSquare:(id)sender;
- (IBAction)setFlip:(id)sender;
- (IBAction)setRotate:(id)sender;
- (IBAction)startStopCine:(id)sender;
- (IBAction)cineModeChanged:(id)sender;
- (IBAction)cpxModeChanged:(id)sender;
- (IBAction)frameRateChanged:(id)sender;
- (IBAction)colorModeChanged:(id)sender;
- (IBAction)cursorModeChanged:(id)sender;
- (IBAction)autoWinLev:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)setLogP1:(id)sender;
- (IBAction)reload:(id)sender;

- (void)loadImages;
- (void)changeWin:(int)w lev:(int)l from:sender;
- (void)changeImage:(int)y from:(id)sender;
- (void)moveByX:(int)x andY:(int)y from:(id)sender;	// called by upper control (not by view)
- (void)reportCursorAt:(NSPoint)pt from:(id)sender;
- (void)clearCursor;
- (void)updateWinLev;
- (void)displayImage;
- (void)displayImage:(int)ix;
- (void)openRawXDim:(int)xDim yDim:(int)yDim zDim:(int)zDim pixSize:(int)size order:(int)order type:(int)type;

- (void)startTimer;
- (void)stopTimer;
- (void)cineStep;

// accessors
- (NSArray *)files;
- (RecImage *)image;            // 3D
- (RecImage *)selectedImage;    // slice (cpx)
- (RecImage *)dispBuf;
- (RecImage *)selectedBuf;     // slice, real (imag, phase etc)
- (void)setImage:(RecImage *)img;
- (int)nImages;
- (void)setDispBuf;     // convert img to scaled real image
- (int)imageIndex;	// probably not necessary
- (KOImageView *)view;
- (NSWindow *)window;
- (KOSlider *)winSlider;
- (KOSlider *)levSlider;
- (KOSlider *)numSlider;
- (KOProfControl *)profile;
- (int)cpxMode;
- (int)imgType;
- (int)tag;
- (void)setTag:(int)aTag;
//- (BOOL)logP1;

@end

// c-func
float lp1(float a);
