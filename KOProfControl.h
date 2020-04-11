/*
	KOProfControl.h
	
	controler obj for profile win
	K. Oshio	12-21-1992

	2-12-1994   copy:sender	
    9-02-2004   ProfView -> KOProfView
*/

#import <Cocoa/Cocoa.h>

@interface KOProfControl:NSObject
{
	IBOutlet id		_profView;
	IBOutlet id		_profWin;
	IBOutlet id		_xField;
	IBOutlet id		_yField;
	IBOutlet id		_valField;
	IBOutlet id		_gainSlider;
	IBOutlet id		_offsSlider;
	IBOutlet id		_widthField;
	IBOutlet id		_zeroMeanButton;
	IBOutlet id		_realField;
	IBOutlet id		_imagField;
	float			_gain;
	int				_offs;
    int				_width;
	int				_horizontal;
	int				_zeroMean;
}

- setPoint:(int)x :(int)y :(int)val;
- horButtonPressed:sender;
- widthChanged:sender;
- sliderMoved:sender;
- meanButtonPressed:sender;
- (int)zeroMean;
- (void)setHorizontal:(int)val;
- (int)horizontal;
- (float)gain;
- (int)offs;
- (void)drawProfileAt:(NSPoint)pt from:sender;
- (void) changeGain:(int)x offs:(int)y;

@end
