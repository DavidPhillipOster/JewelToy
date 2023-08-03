//
//  ScoreBubble.m
//  jeweltoy
//
//  Created by Mike Wessler on Sat Jun 15 2002.
//
/*
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 ----====----====----====----====----====----====----====----====----====---- */

#import "ScoreBubble.h"
#import "JewelToy-Swift.h"
@class Sprite;

NSMutableDictionary *stringAttributes;

@implementation ScoreBubble {
    Sprite	*sprite;
}

+(ScoreBubble *)scoreWithValue:(int)val At:(NSPoint)loc Duration:(int)count
{
    return [[[self class] alloc] initWithValue:val At:loc Duration:count];
}

-(instancetype)initWithValue:(int)val At:(NSPoint)loc Duration:(int)count;
{
    NSString *str= [NSString stringWithFormat:@"%d", val];
    NSSize strsize;
    if (self=[super init]) {
	if (!stringAttributes) {
	    stringAttributes= [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"ArialNarrow-Bold" size:18],
		NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, NULL];
	}
	strsize= [str sizeWithAttributes:stringAttributes];
	strsize.width = floor(3 + strsize.width);
	strsize.height = floor(1 + strsize.height);
	_value= val;
	_screenLocation= loc;
	_screenLocation.x -= strsize.width/2;
	_screenLocation.y -= strsize.height/2;
	_animationCount = count;
	_image= [[NSImage alloc] initWithSize:strsize];
	[_image lockFocus];
	stringAttributes[NSForegroundColorAttributeName] = [NSColor blackColor];	
	[str drawAtPoint:NSMakePoint(2,0) withAttributes:stringAttributes];
	stringAttributes[NSForegroundColorAttributeName] = [NSColor yellowColor];	
	[str drawAtPoint:NSMakePoint(1,1) withAttributes:stringAttributes];
	[_image unlockFocus];

        //
        sprite = [[Sprite alloc] initWithImage:_image
                                      cropRect:NSMakeRect(0, 0, _image.size.width, _image.size.height)
                                          size:_image.size];
        //
    }
    return self;
}

-(void)drawSprite
{
    float alpha= (float)_animationCount/20;
    if (alpha>1) {
        alpha= 1;
    }
    [sprite blitWithX:_screenLocation.x
                  y:_screenLocation.y
                  z:SCOREBUBBLE_SPRITE_Z
              alpha:alpha];
}

-(int)animate
{
    if (_animationCount>0) {
        _screenLocation.y++;
        _animationCount--;
    }
    return _animationCount;
}

@end
