//
//  ScoreBubble.swift
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

/// a numeric score that bubbles toward the top of the window and fades out.
class XcoreBubble {
    static let Z = -0.30
    static var stringAttributes: [NSAttributedString.Key : Any] =
        [ NSAttributedString.Key.font : NSFont(name:"ArialNarrow-Bold", size:18)!,
          NSAttributedString.Key.foregroundColor : NSColor.black ]
    var _animationCount = Int(0)
    var _screenLocation:CGPoint = CGPoint.zero
    let _sprite: Xprite

    init(value: Int, at: CGPoint, duration: Int) {
        let s = "\(value)"
        var strSize = s.size(withAttributes: XcoreBubble.stringAttributes)
        strSize.width = floor(3 + strSize.width)
        strSize.height = floor(1 + strSize.height)
        _screenLocation = at
        _screenLocation.x -= strSize.width/2
        _screenLocation.y -= strSize.height/2
        _animationCount = duration
        let image = NSImage.init(size: strSize)
        image.lockFocus()
        XcoreBubble.stringAttributes[NSAttributedString.Key.foregroundColor] = NSColor.black
        s.draw(at: CGPoint(x:2, y:0), withAttributes: XcoreBubble.stringAttributes)
        XcoreBubble.stringAttributes[NSAttributedString.Key.foregroundColor] = NSColor.yellow
        s.draw(at: CGPoint(x:1, y:1), withAttributes: XcoreBubble.stringAttributes)
        image.unlockFocus()
        _sprite = Xprite(image: image, cropRect: NSMakeRect(0, 0, image.size.width, image.size.height), size: image.size)
    }

    func drawSprite() {
      let alpha = min(1, CGFloat(_animationCount) / 20)
      _sprite.blit(x:_screenLocation.x, y:_screenLocation.y, z:XcoreBubble.Z, alpha: alpha)
    }

    func animate() -> Int {
        if 0  < _animationCount {
            _screenLocation.y += 1
            _animationCount -= 1
        }
        return _animationCount
    }
}


@objc public class ScoreBubble : NSObject {
    let s:XcoreBubble
    @objc public init(value: Int, at: CGPoint, duration: Int) {
        s = XcoreBubble(value: value, at: at, duration: duration)
    }
    @objc public func drawSprite() {
        s.drawSprite()
    }
    @objc public func animate() -> Int {
        return s.animate()
    }
}

