/* ----====----====----====----====----====----====----====----====----====----
Game.h (jeweltoy)

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

@class Gem;

@interface Game : NSObject
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSMutableArray *scoreBubbles;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL checkBoardForThrees;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL boardHasMoves;
@property (NS_NONATOMIC_IOSONLY, readonly) NSPoint hintPoint;
@property (NS_NONATOMIC_IOSONLY, readonly) int score;
@property (NS_NONATOMIC_IOSONLY, readonly) float collectGemsFaded;
@property (NS_NONATOMIC_IOSONLY, readonly) int bonusMultiplier;

- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithSpritesFrom:(NSArray *) spriteArray NS_DESIGNATED_INITIALIZER;

- (void) setSpritesFrom:(NSArray *) spriteArray;

- (int) randomGemTypeAt:(int)x :(int)y;
- (Gem *) gemAt:(int)x :(int)y;

- (void) setMuted:(BOOL)value;

- (void) swap:(int)x1 :(int)y1 and:(int)x2 :(int)y2;
- (void) unswap;

- (BOOL) testForThreeAt:(int) x :(int) y;
- (BOOL) checkForThreeAt:(int) x :(int) y;
- (BOOL) finalTestForThreeAt:(int) x :(int) y;
- (void) showAllBoardMoves;

- (void) removeFadedGemsAndReorganiseWithSpritesFrom:(NSArray *) spriteArray;
- (void) shake;
- (void) erupt;
- (void) explodeGameOver;
- (void) wholeNewGameWithSpritesFrom:(NSArray *) spriteArray;

- (void) increaseBonusMultiplier;

@end
