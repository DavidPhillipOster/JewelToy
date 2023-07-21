//  Sprite.m
//
//  Created by Giles Williams on Fri Jun 21 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Sprite.h"


@implementation Sprite {
    NSBitmapImageRep*	bitmapImageRep;
    NSSize	size;
}


- (id) init
{
    self = [super init];
    return self;
}

- (id) initWithImage:(NSImage *)textureImage cropRectangle:(NSRect)cropRect size:(NSSize) spriteSize
{
    self = [super init];
    [self makeTextureFromImage:textureImage cropRectangle:cropRect size:spriteSize];
    return self;

}

- (void) dealloc
{
  if (bitmapImageRep) {
    [bitmapImageRep release];
    bitmapImageRep = nil;
  }
  [super dealloc];
}

- (void)blitToX:(float)x Y:(float)y Z:(float)z
{
    [self blitToX:x Y:y Z:z Alpha:1];
}

- (void)blitToX:(float)x Y:(float)y Z:(float)z Alpha:(float)a
{
    if (a < 0.0)
        a = 0.0;	// clamp the alpha value
    if (a > 1.0)
        a = 1.0;	// clamp the alpha value
    [bitmapImageRep drawInRect:NSMakeRect(x, y, size.width, size.height)
                      fromRect:NSMakeRect(0, 0, size.width, size.height)
                     operation:NSCompositingOperationSourceOver
                      fraction:a
                respectFlipped:NO
                         hints:nil];
}

- (void)makeTextureFromImage:(NSImage *)texImage cropRectangle:(NSRect)cropRect size:(NSSize)spriteSize
{
    if (!texImage)
        return;

    NSImage*		image;
    NSRect textureRect = NSMakeRect(0, 0, spriteSize.width, spriteSize.height);

    size = spriteSize;



    image = [[NSImage alloc] initWithSize:spriteSize];

    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(textureRect);
    [texImage drawInRect:textureRect fromRect:cropRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [bitmapImageRep release];
    bitmapImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:textureRect];
    [image unlockFocus];

    [image release];

    //NSLog(@"Texture has :\n%d bitsPerPixel\n%d bytesPerPlane\n%d bytesPerRow",[bitmapImageRep bitsPerPixel],[bitmapImageRep bytesPerPlane],[bitmapImageRep bytesPerRow]);
    //NSLog(@"Texture is :\n%f x %f pixels, using %f x %f",textureRect.size.width,textureRect.size.height,textureCropRect.size.width,textureCropRect.size.height);
}

- (void)replaceTextureFromImage:(NSImage *)texImage cropRectangle:(NSRect)cropRect
{
    NSRect		textureRect = NSMakeRect(0.0,0.0, size.width, size.height);
    NSImage*		image;

    if (!texImage)
        return;

    if ((textureRect.size.width != cropRect.size.width)||(textureRect.size.height != cropRect.size.height))
    {
        NSLog(@"ERROR! replacement texture isn't the same size as original texture");
        NSLog(@"cropRect %f x %f textureSize %f x %f",textureRect.size.width, textureRect.size.height, cropRect.size.width, cropRect.size.height);
        return;
    }

    image = [[NSImage alloc] initWithSize:textureRect.size];

    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(textureRect);
    [texImage drawInRect:textureRect fromRect:cropRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [bitmapImageRep release];
    bitmapImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:textureRect];
    [image unlockFocus];

    [image release];
}

- (void)substituteTextureFromImage:(NSImage *)texImage
{
    NSRect		cropRect = NSMakeRect(0.0,0.0,[texImage size].width,[texImage size].height);
    NSRect		textureRect = NSMakeRect(0.0,0.0,size.width, size.height);
    NSImage*		image;

    if (!texImage)
        return;

    image = [[NSImage alloc] initWithSize:size];

    [image lockFocus];
    [[NSColor clearColor] set];
    NSRectFill(textureRect);
    [texImage drawInRect:textureRect fromRect:cropRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [bitmapImageRep release];
    bitmapImageRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:textureRect];
    [image unlockFocus];

    [image release];
}

@end
