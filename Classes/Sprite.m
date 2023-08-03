//  Sprite.m
//
//  Created by Giles Williams on Fri Jun 21 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Sprite.h"


@implementation Sprite {
  NSImage*	_image;
}

- (instancetype) initWithImage:(NSImage *)textureImage cropRectangle:(NSRect)cropRect size:(NSSize) spriteSize
{
    self = [super init];
    if (self) {
      _image = [textureImage copy];
    }
    return self;

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
  [_image drawInRect:NSMakeRect(x, y, _image.size.width, _image.size.height)
            fromRect:NSMakeRect(0, 0, _image.size.width, _image.size.height)
           operation:NSCompositingOperationSourceOver
            fraction:a];
}

- (void)replaceTextureFromImage:(NSImage *)texImage cropRectangle:(NSRect)cropRect
{
    NSRect		textureRect = NSMakeRect(0.0,0.0, _image.size.width, _image.size.height);

    if (!texImage)
        return;

    if ((textureRect.size.width != cropRect.size.width)||(textureRect.size.height != cropRect.size.height))
    {
        NSLog(@"ERROR! replacement texture isn't the same size as original texture");
        NSLog(@"cropRect %f x %f textureSize %f x %f",textureRect.size.width, textureRect.size.height, cropRect.size.width, cropRect.size.height);
        return;
    }
    _image = [texImage copy];
}

- (void)substituteTextureFromImage:(NSImage *)texImage
{
    if (!texImage)
        return;

    _image = [texImage copy];
}

@end
