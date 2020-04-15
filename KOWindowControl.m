/*
	KOWindowControl.m
	multi-window control object
	
	K. Oshio
	8-8-2005
 */

#import <Cocoa/Cocoa.h>

#import "KOWindowControl.h"
#import "KOImageControl.h"

@implementation KOWindowControl

- init
{
	self = [super init];
    _imageControlArray = [[NSMutableArray alloc] initWithCapacity:10];
	return self;
}

//- (void)dealloc
//{
//    [_imageControlArray release];
//    [super dealloc];
//}

- (void)removeFromArray:(id)obj
{
    NSEnumerator *enumerator = [_imageControlArray objectEnumerator];
    id  anObject;

    while (anObject = [enumerator nextObject]) {
        if (obj == anObject) {
            [_imageControlArray removeObject:obj];
        }
    }
}

- (IBAction)open:(id)sender
{
    KOImageControl  *control;

    // KOWindowControl "owns" KOImageControl instance
    control = [[KOImageControl alloc] initFromNib];
    [control open];
    [_imageControlArray addObject:control];
}

/*
- (IBAction)openRaw:(id)sender
{
    KOImageControl  *control;

	[rawPanel orderOut:self];
    control = [[KOImageControl alloc] initFromNib];
    [control openRawXDim:[rawXField intValue] yDim:[rawYField intValue] zDim:[rawZField intValue]
		size:[rawSize tag] order:[rawOrder tag] type:[rawType tag]];
    [_imageControlArray addObject:control];
}
*/

- (IBAction)saveSingle:(id)sender
{
//    [(KOImageControl *)[[NSApp keyWindow] delegate] saveSingle];
}

- (IBAction)saveAsKOImage:(id)sender   // 3D
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] saveAsKOImage];
}

//- (IBAction)saveImageAsTIFF:(id)sender
//{
//    [(KOImageControl *)[[NSApp keyWindow] delegate] saveImageAsTIFF];
//}

- (IBAction)saveAllAsPDF:(id)sender
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] saveAllAsPDF];
}

- (IBAction)zoomIn:(id)sender
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] zoomIn:self];
}

- (IBAction)zoomOut:(id)sender
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] zoomOut:self];
}

- (IBAction)forward:(id)sender
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] forward:self];
}

- (IBAction)backward:(id)sender
{
    [(KOImageControl *)[[NSApp keyWindow] delegate] backward:self];
}

//- (IBAction)reorderImages:(id)sender
//{
//	int	loopSize = [loopSizeField integerValue];
//	[reorderPanel orderOut:self];
//	[(KOImageControl *)[[NSApp keyWindow] delegate] reorderWithSize:loopSize];
//}

//- (IBAction)revertOrder:(id)sender
//{
//	[reorderPanel orderOut:self];
//	[(KOImageControl *)[[NSApp keyWindow] delegate] revertOrder];
//}

- (void)reportCursorAt:(NSPoint)pt from:sender
{
    NSEnumerator    *enumerator = [_imageControlArray objectEnumerator];
    KOImageControl  *ctr;

    // draw cursor on every image windows
    while (ctr = [enumerator nextObject]) {
        [ctr reportCursorAt:pt from:self];
    }
}

- (void)moveByX:(int)x andY:(int)y from:(id)sender
{
    [sender moveByX:x andY:y];
}

- (void)imageChanged:(id)sender
{
	// implement in sub-class
}

//- (KO_IMAGE **)images
//{
//    return [(KOImageControl *)[[NSApp keyWindow] delegate] images];
//}

- (RecImage *)image
{
    return [(KOImageControl *)[[NSApp keyWindow] delegate] image];
}

//- (int)nImages
//{
//    return [(KOImageControl *)[[NSApp keyWindow] delegate] nImages];
//}

- (int)imageIndex
{
    return [(KOImageControl *)[[NSApp keyWindow] delegate] imageIndex];
}

- (KOProfControl *)profile
{
    return _profile;
}

//- (KOPspaceControl *)pspace
//{
//    return _pspace;
//}

@end
