/*
	SliderControl.h
	Abstract slider

	3-13-1996	initial coding 	K. Oshio
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface KOSlider:NSObject
{
	IBOutlet id		_target;		// target object
	IBOutlet id		_textField;		// NSTextField
	IBOutlet id		_slider;		// NSSlider
	BOOL			_continuous;	// if generates action at every modification
	BOOL			_nonlinear;		// if quadratic
	int				_tag;			// tag to identify instances
	int				_min;			// actual min value (slider uses normalized range)
	int				_max;			// actual max value (slider uses normalized range)
    int             _value;
}

- (void)setMin:(int)minVal max:(int)maxVal value:(int)intVal
	continuous:(BOOL)flag nonlinear:(BOOL)nlnr tag:(int)aTag;
- (void)setMin:(int)min andMax:(int)max;
- (void)setContinuous:(BOOL)flag;
- (void)setNonlinear:(BOOL)flag;

- (int)intValue;
- (void)setValue:(int)intValue;
- (void)setTag:(int)tag;
- (void)changeValueBy:(int)delta;
- (IBAction)sliderMoved:(id)sender;
- (IBAction)fieldChanged:(id)sender;
- (int)tag;

@end
