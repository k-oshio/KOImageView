#import <Cocoa/Cocoa.h>

@interface KOIndicator : NSObject
{
	IBOutlet id	_indicator;
	IBOutlet id	_titleField;
	IBOutlet id	_numField;
	IBOutlet id	_panel;
}

- (IBAction)show:(id)sender;
- (IBAction)hide:(id)sender;
- (void)setPercentage:(float)perc;
- (void)setTitle:(NSString *)str;

@end
