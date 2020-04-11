#import "KOIndicator.h"

@implementation KOIndicator

- (IBAction)show:(id)sender
{
	[_indicator setIndeterminate:NO];
	[_indicator setMinValue:0];
	[_indicator setMaxValue:100];
	// this brings the panel in front of all other windows
	// don't know how to limit ordering within application
	[_panel setLevel:NSNormalWindowLevel];
	[_panel makeKeyAndOrderFront:self]; 
}

- (IBAction)hide:(id)sender;
{
	[_panel orderOut:self];
}

- (void)setTitle:(NSString *)str
{
	[_titleField setStringValue:str];
	[_titleField display];
}

- (void)setPercentage:(float)perc;
{
	NSString *str;
	[_indicator setDoubleValue:perc];
	[_indicator display];
	str = [NSString stringWithFormat:@"%d %%", (int)perc];
	[_numField setStringValue:str];
	[_numField display];
}

@end
