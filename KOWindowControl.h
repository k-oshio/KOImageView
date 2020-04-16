/*
	KOWindowControl.h
	window control object
	
	K. Oshio
	8-8-2005
 */

#import <Cocoa/Cocoa.h>

//#import "KOImageControl.h"
#import "KOProfControl.h"
#import <RecKit/RecKit.h>

@interface KOWindowControl:NSObject
{
	IBOutlet KOProfControl		*_profile;
    NSMutableArray				*_imageControlArray;
// OpenRaw
	IBOutlet NSTextField		*rawXField;
	IBOutlet NSTextField		*rawYField;
	IBOutlet NSTextField		*rawZField;
	IBOutlet NSPopUpButton		*rawSize;
	IBOutlet NSPopUpButton		*rawOrder;
	IBOutlet NSPopUpButton		*rawType;
	IBOutlet NSWindow			*rawPanel;
}

- (id)init;
- (void)removeFromArray:(id)obj;

- (IBAction)open:(id)sender;
- (IBAction)openRaw:(id)sender;
//- (IBAction)saveImageAsTIFF:(id)sender;
- (IBAction)saveAllAsPDF:(id)sender;   // to make qt movie
- (IBAction)saveSingle:(id)sender;      // save slice
- (IBAction)saveAsKOImage:(id)sender;   // 3D

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)backward:(id)sender;

// reordering images
//- (IBAction)reorderImages:(id)sender;
//- (IBAction)revertOrder:(id)sender;

// profile / cursor interface
- (void)reportCursorAt:(NSPoint)pt from:sender;
- (void)moveByX:(int)x andY:(int)y from:(id)sender;
- (RecImage *)image;
- (int)imageIndex;
- (void)imageChanged:(id)sender;

// accessors
- (KOProfControl *)profile;

@end
