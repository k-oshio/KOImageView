/*
	KOSliderControl.m
	slider control object for image viewer
	
	K. Oshio
	8-11-2001	2nd attempt
	8-12-2001	quadratic mode
 */

#import "KOSlider.h"

@implementation KOSlider

// private methods (primitives)
- (void)updateSlider:(int)intVal
{
	int		sign;

	if (_nonlinear) {
		sign = (intVal < 0 ? -1 : 1);
		intVal = sign * sqrt(fabs((float)intVal));
	}
	[_slider setIntValue:intVal];
}

- (void)updateText:(int)intVal
{
	int sign;

	if (_nonlinear) {
		sign = (intVal < 0 ? -1 : 1);
		intVal = intVal * intVal * sign;
	}
	if (intVal < _min) intVal = _min;
	if (intVal > _max) intVal = _max;
    _value = intVal;
	[_textField setIntValue:intVal];
}

// public methods
- (id)init
{
	self = [super init];
	_target = nil;
	_textField = nil;
	_slider = nil;
	_continuous = NO;
	_nonlinear = NO;
	_tag = 0;
	_min = _value = 0;
	_max = 100;
	return self;
}

// won't work at init time (before nibs are loaded)
- (void)setMin:(int)minVal max:(int)maxVal value:(int)intVal
	continuous:(BOOL)cflag nonlinear:(BOOL)nflag tag:(int)aTag
{
	_tag = aTag;
	[self setNonlinear:nflag];
	[self setMin:minVal andMax:maxVal];
	[self setValue:intVal];
	[self setContinuous:cflag];
}

- (void)setContinuous:(BOOL)flag
{
	_continuous = flag;
}

- (void)setNonlinear:(BOOL)flag
{
	_nonlinear = flag;
}

- (int)intValue
{
	return _value;
}

- (void)setValue:(int)intValue
{
    if (intValue > _max) intValue = _max;
    if (intValue < _min) intValue = _min;
    _value = intValue;
    [_textField setIntValue:intValue];
	[self updateSlider:intValue];
}

// int value
- (void)changeValueBy:(int)delta
{
//    int	current = [_textField intValue];
    int	current = _value;
	current += delta;
	if (current < _min) current = _min;
	if (current > _max) current = _max;
    _value = current;
	[_textField setIntValue:current];
	[self updateSlider:current];
}

- (void)setMin:(int)min andMax:(int)max
{
	float	floatVal;
	int		sign;
//	float	thickness;
//	NSRect	rect;

// range check (min/max)
	if (min >= max) {
		[_slider setEnabled:NO];
		_min = _max = min;
	} else {
		[_slider setEnabled:YES];
		_min = min;
		_max = max;
	}
// range check (current value)
	if ([_textField intValue] > _max) {
		[_textField setIntValue:_max];
	}
// non-linear mapping
	if (_nonlinear) {
		sign = (max < 0 ? -1 : 1);
		floatVal = sign * sqrt(fabs((float)_max));
		[_slider setMaxValue:(double)floatVal];
		sign = (min < 0 ? -1 : 1);
		floatVal = sign * sqrt(fabs((float)_min));
		[_slider setMinValue:(double)floatVal];

	} else {
		[_slider setMaxValue:(double)_max];
		[_slider setMinValue:(double)_min];
	}
// slider nob thickness (not supported in OSX)
//	rect = [_slider bounds];
//	thickness = rect.size.width / (_max - _min + 1);
//	if (thickness < 19) thickness = 19;
//	[_slider setKnobThickness:thickness];
}

- (IBAction)fieldChanged:sender
{
	int	value = [_textField intValue];
	if (value > _max) {
		value = _max;
	}
	if (value < _min) {
		value = _min;
	}
    [_textField setIntValue:value];
//    [self updateText:value];
    _value = value;
	[self updateSlider:value];
	[_target sliderMoved:self];
}

- (IBAction)sliderMoved:sender
{
	NSEvent	*ev = (NSEvent *)[NSApp currentEvent];
	int		intValue = [_slider intValue];

	[self updateText:intValue];
	if (_continuous == YES || [ev type] == NSLeftMouseUp) {
		[_target sliderMoved:self];
	}
}

- (int)tag
{
	return _tag;
}

- (void)setTag:(int)tag
{
    _tag = tag;
}

@end
