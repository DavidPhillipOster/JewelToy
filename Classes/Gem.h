/* ----====----====----====----====----====----====----====----====----====----
Gem.h (jeweltoy)

JewelToy is a simple game played against the clock.
Copyright (C) 2001  Giles Williams

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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#define GEMSTATE_RESTING	1
#define GEMSTATE_FADING		2
#define GEMSTATE_FALLING	3
#define GEMSTATE_SHAKING	4
#define GEMSTATE_ERUPTING	5
#define GEMSTATE_MOVING		6
//
// MW...
//
#define GEMSTATE_SHIVERING	7
//

#define FADE_STEPS		8.0
#define GRAVITY			1.46
#define GEM_ERUPT_DELAY		45

//
// Open GL Z value for gems
//
#define GEM_SPRITE_Z		-0.25
//

@class	Sprite;

@interface Gem : NSObject
@property (NS_NONATOMIC_IOSONLY, readonly) int animate;
@property (NS_NONATOMIC_IOSONLY) int gemType;
@property (NS_NONATOMIC_IOSONLY, copy) NSImage *image;
@property (NS_NONATOMIC_IOSONLY, strong) Sprite *sprite;
@property (NS_NONATOMIC_IOSONLY) int state;
@property (NS_NONATOMIC_IOSONLY) int animationCounter;
@property (NS_NONATOMIC_IOSONLY, readonly) NSPoint positionOnScreen;
@property (NS_NONATOMIC_IOSONLY, readonly) NSPoint positionOnBoard;

- (instancetype)	init;

+ (Gem *) gemWithNumber:(int) d andSprite:(Sprite *)aSprite;

- (void) fade;
- (void) fall;
- (void) shake;
- (void) erupt;
// MW...
- (void) shiver;
//

- (void) drawSprite;

- (void) setPositionOnScreen:(int) valx :(int) valy;
- (void) setVelocity:(int) valx :(int) valy :(int) steps;

- (void) setPositionOnBoard:(int) valx :(int) valy;

- (void) setSoundsTink:(NSSound *) tinkSound Sploink:(NSSound *) sploinkSound;

@end
