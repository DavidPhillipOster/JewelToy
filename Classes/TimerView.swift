//
//  TimerView.swift
//  JewelToy
//
//  Created by david on 8/3/23.
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

import AppKit

class TimerView : NSView {
    var aTimer:Timer?
    var meter = 0.5
    var decrement = 0.0
    var timer = 0.0
    let color1	= NSColor.red
    let color2	= NSColor.yellow
    let colorOK	= NSColor.green
    let backColor = NSColor.black
    var isRunning = false

    var runOutBlock: () -> Void = {}
    var runOverBlock: () -> Void = {}

    var paused: Bool {
        get { !isRunning }
        set(b){ isRunning = !b }
    }

    override var isOpaque:Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        backColor.setFill()
        NSBezierPath(rect:bounds).fill()
        let r = NSMakeRect(4, 4, meter * (bounds.size.width - 8), bounds.size.height - 8)
        colorOK.setFill()
        if decrement != 0 {
            if meter < 0.3 { color2.setFill() }
            if meter < 0.1 { color1.setFill() }
        }
        NSBezierPath(rect:r).fill()
    }

    func incrementMeter(_ value: Double ) {
        meter += value
        if 1 < meter { meter = 1 }
        self.needsDisplay = true
    }

    func decrementMeter(_ value: Double ) {
        meter -= value
        if meter < 0 { meter = 0 }
        self.needsDisplay = true
    }

    func setTimerRunningEvery(_ every:Double, decrement:Double, whenRunOut:@escaping () -> Void , whenRunOver:@escaping () -> Void) {
        self.decrement = decrement
        meter = 0.5
        runOutBlock = whenRunOut
        runOverBlock = whenRunOver
        aTimer?.invalidate()
        aTimer = Timer.scheduledTimer(withTimeInterval: every, repeats: true, block: { [weak self] bTimer in
            self?.runTimer()
        })
        isRunning = true
    }

    func runTimer() {
      if isRunning {
        if meter == 1 {
          isRunning = false
          runOverBlock()
          return
        }
        decrementMeter(decrement)
        if meter == 0 && decrement != 0 {
            isRunning = false
            runOutBlock()
            runOutBlock = {}    // if the game ends, we don't keep running the game end animation.
        }
      }
    }
}

