//  Sprite.swift
//  JewelToy
//
//  Created by david on 8/3/23.
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

// TODO: cropRect ignored for now.
class Xprite {
    var image:NSImage

    init(image: NSImage, cropRect:CGRect, size:CGSize) {
        self.image = image
    }

    func blit(x:CGFloat, y:CGFloat, z:CGFloat, alpha:CGFloat = 1.0) {
        image.draw(in: NSMakeRect(x, y, image.size.width, image.size.height),
                   from: NSMakeRect(0, 0, image.size.width, image.size.height),
                   operation: .sourceOver, fraction: max(0, min(alpha, 1)))
    }

    func replace(image: NSImage, cropRect:CGRect) {
        assert(image.size.width == self.image.size.width && image.size.height == self.image.size.height)
        self.image = image
    }

    func substitute(image: NSImage) {
        assert(image.size.width == self.image.size.width && image.size.height == self.image.size.height)
        self.image = image
    }

}

@objc public class Sprite : NSObject {
    let s:Xprite
    @objc public init(image: NSImage, cropRect:CGRect, size:CGSize) {
        s = Xprite(image:image, cropRect: cropRect, size: size)
    }
    @objc public func blit(x:CGFloat, y:CGFloat, z:CGFloat, alpha:CGFloat = 1.0) {
        s.blit(x:x, y:y, z:z, alpha: alpha)
    }
    @objc public func replace(image: NSImage, cropRect:CGRect) {
        s.replace(image:image, cropRect: cropRect)
    }
    @objc public func substitute(image: NSImage) {
        s.substitute(image:image)
    }
}

