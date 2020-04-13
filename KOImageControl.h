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
//	KO_IMAGE    **_f;       // ## KO_IMAGE -> make these RecImage
//	KO_IMAGE	**origArray;
//	KO_IMAGE	**alteredArray;
//	int         _nImages;
//	BOOL        _imageAllocated;
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

// complex display mode
    BOOL        _cpx;
	int         _cpxMode;	// 0:Mag, 1:Re, 2:Im, 3:Phs, 4:color
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

//- (void)openFiles:(NSArray *)files;
- (void)loadImages;
//- (void)setImages:(KO_IMAGE **)f nImages:(int)n;    // ## KO_IMAGE
//- (void)setImage:(RecImage *)img;
- (void)changeWin:(int)w lev:(int)l from:sender;
- (void)changeImage:(int)y from:(id)sender;
- (void)moveByX:(int)x andY:(int)y from:(id)sender;	// called by upper control (not by view)
- (void)reportCursorAt:(NSPoint)pt from:(id)sender;
- (void)clearCursor;
- (void)updateWinLev;
- (void)displayImage;
- (void)displayImage:(int)ix;

- (void)startTimer;
- (void)stopTimer;
- (void)cineStep;

// accessors
- (NSArray *)files;
//- (KO_IMAGE **)images;  // ## KO_IMAGE
- (RecImage *)image;
- (void)setImage:(RecImage *)img;
- (int)nImages;
- (void)setDispBuf;     // convert img to scaled real image
- (int)imageIndex;	// probably not necessary
- (RecImage *)selectedImage;
- (KOImageView *)view;
- (NSWindow *)window;
//- (NSString *)currentDirectory;
- (KOSlider *)winSlider;
- (KOSlider *)levSlider;
- (KOSlider *)numSlider;
- (KOProfControl *)profile;
- (int)tag;
- (void)setTag:(int)aTag;
//- (BOOL)logP1;

// ### remove KO_IMAGE
// RecImage methods
//- (KO_IMAGE **)koImageWithRecImage:(RecImage *)rec nImg:(int *)n;
//- (RecImage *)recImageWithKOImage:(KO_IMAGE **)f nImg:(int)n;
//- (RecImage *)recImages;

@end

// c-func
float lp1(float a);
