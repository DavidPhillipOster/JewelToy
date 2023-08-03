/* ----====----====----====----====----====----====----====----====----====----
MyTimerView.m (jeweltoy)

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

#import "MyTimerView.h"

typedef void (^Block)(void);

@implementation MyTimerView {
    float meter;
    float decrement;
    Block runOutBlock;
    Block runOverBlock;
    NSTimer	*timer;
    BOOL	isRunning;

    NSColor	*color1;
    NSColor	*color2;
    NSColor	*colorOK;
    NSColor	*backColor;
}


- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
      meter	= 0.5;
      color1	= [NSColor redColor];
      color2	= [NSColor yellowColor];
      colorOK	= [NSColor greenColor];
      backColor	= [NSColor blackColor];
      isRunning	= NO;
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    NSRect dotRect;

    [backColor set];
    NSRectFill(self.bounds);   // Equiv to [[NSBezierPath bezierPathWithRect:[self bounds]] fill]

    dotRect.origin.x = 4;
    dotRect.origin.y = 4;
    dotRect.size.width  = meter * (self.bounds.size.width - 8);
    dotRect.size.height = self.bounds.size.height - 8;
    
    [colorOK set];
    //
    // another MW change...
    //
    if (decrement!=0)
    {
        if (meter < 0.3) [color2 set];
        if (meter < 0.1) [color1 set];
    }

    NSRectFill(dotRect);   // Equiv to [[NSBezierPath bezierPathWithRect:dotRect] fill]
}

- (BOOL)isOpaque {
    return YES;
}

// Utility
- (void) setPaused:(BOOL) value
{
    isRunning = !value;
}

- (void) incrementMeter:(float) value
{
    meter += value;
    if (meter > 1) meter = 1;
    [self setNeedsDisplay:YES];
}

- (void) setDecrement:(float) value
{
    decrement = value;
}

- (void) decrementMeter:(float) value
{
    meter -= value;
    if (meter < 0) meter = 0;
    [self setNeedsDisplay:YES];
}

- (void) setTimerRunningEvery:(NSTimeInterval) timeInterval
            decrement:(float) value
            whenRunOut:(Block) runOutBlk
            whenRunOver:(Block) runOverBlk
{
    decrement = value;
    runOutBlock = runOutBlk;
    runOverBlock = runOverBlk;
    if (timer)
    {
        [timer invalidate];
    }
    timer = [NSTimer	scheduledTimerWithTimeInterval:timeInterval
                target:self
                selector:@selector(runTimer)
                userInfo:self
                repeats:YES];
    isRunning = YES;
}

- (void) runTimer
{
    if (isRunning)
    {
        if (meter == 1)
        {
            isRunning = NO;
            // [target performSelector:runOverSelector];
            if (runOverBlock)runOverBlock();
            return;
        }
        [self decrementMeter:decrement];
        if (meter == 0 && decrement!=0)	// MW change added '&& decrement'
        {
            isRunning = NO;
            // [target performSelector:runOutSelector];
            if (runOutBlock) runOutBlock();
            return;
        }
    }
}

- (void) setTimer:(float)value
{
    isRunning = NO;
    meter = value;
    [self setNeedsDisplay:YES];
}

- (float) meter
{
    return meter;
}


@end
