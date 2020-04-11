/*
	KOProfView.h

	profile view
	K. Oshio
    9-02-2004   ProfView -> KOProfView

 */

#import <Cocoa/Cocoa.h>
#import "KOProfControl.h"

@interface KOProfView:NSView
{
	IBOutlet KOProfControl  *_control;
    float                   *_plotData;
	int                     _nData;
}

- (id)setData:(float *)data :(int)n;
- (void)mouseDown:(NSEvent *)thisEvent;
- (void)mouseDragged:(NSEvent *)thisEvent;
- (void)cursorEvent:(NSEvent *)theEvent initial:(BOOL)initflag;

@end
