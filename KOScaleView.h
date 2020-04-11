/*
	KOScaleView.h		
*/

#import <Cocoa/Cocoa.h>

#import "KOImageView.h"

@interface KOScaleView:NSView
{
	int		_nScale;
	float	*_r;
	float	*_g;
	float	*_b;
}

- (void)initScale:(int)n withView:(id)view;

@end
