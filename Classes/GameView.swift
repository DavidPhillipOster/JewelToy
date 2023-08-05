//
//  GameView.swift
//  JewelToy
//
//  Created by david on 8/4/23.
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

class GameView : NSView {

    @objc @IBOutlet var gameController:GameController!

    var animating = false
    var animationStatus = false
    var backgroundColor:NSColor = .purple
    var dragStartPoint = NSPoint.zero
    var game:Game?
    var hiScoreLegend = NSAttributedString()
    var hiScoreNumbers:[NSNumber] = []
    var hiScoreNames:[NSString] = []
    var muted = false
    var paused = false {
      didSet {
        if paused {
            animationStatus = animating
            animating = false
        } else {
            animating = animationStatus
        }
        needsDisplay = true
      }
    }
    var showHighScores = false
    var showHint = true
    var scoreScroll = 0
    var ticsSinceLastMove = 0
    var backgroundSprite:Sprite = GameView.constructSpriteBackground()
    let crosshairSprite:Sprite = {
        let crossImage = NSImage(named:"cross")!
        return Sprite(image: crossImage, cropRect: CGRect(origin: .zero, size: crossImage.size), size: CGSize(width: DIM, height: DIM))
    }()
    var legendSprite:Sprite?
    let movehintSprite:Sprite = {
        let movehintImage = NSImage(named:"movehint")!
        return Sprite(image: movehintImage, cropRect: CGRect(origin: .zero, size: movehintImage.size), size: CGSize(width: DIM, height: DIM))
    }()
    var spriteArray:[Sprite] = GameView.constructSpriteArray()

    @objc override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        setLegend(image: NSImage(named: "title")!)
    }

    @objc required init?(coder: NSCoder) {
        super.init(coder: coder)
        setLegend(image: NSImage(named: "title")!)
    }

    override var isOpaque:Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        backgroundSprite.blit(x: 0, y: 0, z: 0)
        if let game = game {
            if !paused {
                for i in 0..<NUMX {
                    for j in 0..<NUMY {
                        game.gemAt(i, j).drawSprite()
                    }
                }
                game.scoreBubblesDraw()
            }
        }
        if gameController.gameState == .awaitingSecondClick {
            let p = gameController.crossHair1Position
            crosshairSprite.blit(x: p.x, y: p.y, z: -0.5)
        }
        if showHighScores {
            showScores()    // draws the HighScores in legendSprite
        }
        if let legendSprite = legendSprite {
            if 500 < ticsSinceLastMove {
                setLegend(image: NSImage(named: "title")!) // show Logo
            }
            legendSprite.blit(x: 0, y: 0, z: -0.75)
        } else if let game = game, 500 < ticsSinceLastMove && showHint {
            movehintSprite.blit(x: game.hintPoint().x, y: game.hintPoint().y, z: -0.4, alpha: (sin((CGFloat(ticsSinceLastMove)-497.0)/4.0)+1.0)/2.0)
        }
    }

    /// called from timer
    func animate(){
        var needsUpdate = game?.scoreBubblesAnimate() ?? false
        if animating {
            if let game = game {
                var c = 0
                for i in 0..<NUMX {
                    for j in 0..<NUMY {
                        c += game.gemAt(i, j).animate()
                    }
                }
                if 0 == c {
                    gameController.animationEnded()
                }
            }
            needsUpdate = true
        } else {
            ticsSinceLastMove += 1
            if 500 < ticsSinceLastMove {
                needsUpdate = true
            }
        }
        if needsUpdate {
            needsDisplay = true
        }
    }

    class func constructSpriteBackground() -> Sprite {
        let backgroundImage:NSImage = {
            if let data = UserDefaults.standard.data(forKey: "backgroundTiffData"),
               let background = NSImage(data:data) {
                return background
            } else {
                return NSImage(named:"background")!
            }
        }()
        return Sprite(image: backgroundImage, cropRect: CGRect(origin: .zero, size: backgroundImage.size), size: CGSize(width: DIM*NUMX, height: DIM*NUMY))
    }

    class func constructSpriteArray() -> [Sprite] {
        let useAlternateGraphics = UserDefaults.standard.bool(forKey: "useAlternateGraphics")
        let useImportedGraphics = UserDefaults.standard.bool(forKey: "useImportedGraphics")
        var gemImageArray:[NSImage] = []
        if useAlternateGraphics && !useImportedGraphics {
            for i in 1...NUMGEM {
                gemImageArray.append(NSImage(named:"\(i)gemA")!)
            }
        } else if useImportedGraphics {
            for i in 1...NUMGEM {
              if let data = UserDefaults.standard.data(forKey: "tiffGemImage\(i-1)"),
                let gemImage = NSImage(data:data) {
                gemImageArray.append(gemImage)
              }
            }
        }
        if gemImageArray.isEmpty {
            for i in 1...NUMGEM {
                gemImageArray.append(NSImage(named:"\(i)gem")!)
            }
        }
        var sprites:[Sprite] = []
        for image in gemImageArray {
            sprites.append(Sprite(image: image, cropRect: CGRect(origin: .zero, size: image.size), size: CGSize(width: DIM, height: DIM)))
            if sprites.count == NUMGEM { break }
        }
        return sprites
    }

    func updateBackground() {
    // TODO: updateBackground
    }

    func setHTMLLegend(_ html:NSString) {
        if let sp = html.utf8String {
            let d = Data(bytes:sp, count: html.length)
            if let attrS = NSAttributedString(html: d, documentAttributes: nil) {
                setLegend(string: attrS)
            }
        }
    }

    func setLegend(string:NSAttributedString) {
        setLegend(block:{
            let size = string.size()
            let legendPoint = CGPoint(x:(CGFloat(DIM*NUMX) - size.width)/2, y:(CGFloat(DIM*NUMY) - size.height)/2)
            string.draw(at: legendPoint)
        })
    }

    func setLegend(image:NSImage) {
        setLegend(block:{
            let legendPoint = CGPoint(x:(CGFloat(DIM*NUMX) - image.size.width)/2, y:(CGFloat(DIM*NUMY) - image.size.height)/2)
            let r = NSMakeRect(0, 0, image.size.width, image.size.height)
            image.draw(at: legendPoint, from: r, operation: .sourceOver, fraction: 1)
        })
    }

    /// do the boilerplate of creating a full-game sprite.
    ///
    /// @param block - drawing functions to draw into the image.
    func setLegend(block:()->Void) {
        let legendImage = NSImage(size: CGSize(width: DIM*NUMX, height: DIM*NUMY))
        let legendR = NSMakeRect(0, 0, legendImage.size.width, legendImage.size.height)
        legendImage.lockFocus()
        NSColor.clear.set()
        NSBezierPath(rect:legendR).fill()
        block()
        legendImage.unlockFocus()
        legendSprite = Sprite(image: legendImage, cropRect: legendR, size: legendImage.size)
        ticsSinceLastMove = 0
        showHighScores = false
        animating = false
        needsDisplay = true
    }


    override func mouseDown(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        dragStartPoint = convert(eventLocation, from: nil)
    }

    override func mouseUp(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        let center = convert(eventLocation, from: nil)
        if gameController.gameState == .awaitingSecondClick {
            gameController.receiveClick(Int(center.x), Int(center.y))
        } else if gameController.gameState == .awaitingFirstClick {
            let chx1 = Int(floor(dragStartPoint.x / CGFloat(DIM)))
            let chy1 = Int(floor(dragStartPoint.y / CGFloat(DIM)))
            let chx2 = Int(floor(center.x / CGFloat(DIM)))
            let chy2 = Int(floor(center.y / CGFloat(DIM)))
            // only one of x,y changed - valid shove
            if (chx2 != chx1) != (chy2 != chy1) {
                gameController.receiveClick(Int(dragStartPoint.x), Int(dragStartPoint.y))
                gameController.receiveClick(Int(center.x), Int(center.y))
            } else {
                gameController.receiveClick(Int(center.x), Int(center.y))
            }
        }
    }

    func showHighScores(_ scores:[NSNumber], andNames names:[NSString]) {
        hiScoreNumbers = scores
        hiScoreNames = names
        showHighScores = true
        animating = false
        scoreScroll = 0;
        needsDisplay = true
    }

    func showScores() {
        let legendImage = NSImage(size: CGSize(width: DIM*NUMX, height: DIM*NUMY))
        let legendR = NSMakeRect(0, 0, legendImage.size.width, legendImage.size.height)
        legendImage.lockFocus()
        NSColor.clear.set()
        NSBezierPath(rect:legendR).fill()

        NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.5).set()
        NSBezierPath(rect:NSMakeRect(32, 16, CGFloat(DIM*NUMY-64), CGFloat(DIM*NUMY-32))).fill()
        let x = (CGFloat(DIM*NUMY) - hiScoreLegend.size().width)/2.0
        let y = CGFloat(DIM*NUMY) - hiScoreLegend.size().height*1.5 + CGFloat(scoreScroll)
        hiScoreLegend.draw(at: NSMakePoint(x, y))
        let count = min(10, hiScoreNumbers.count)
        var attr:[NSAttributedString.Key : Any] = [NSAttributedString.Key.foregroundColor : NSColor.yellow]
        for i in 0..<count {
            let s1 = "\(hiScoreNumbers[i])" as NSString
            let s2 = hiScoreNames[i] as NSString
            let	q1 = CGPoint(x: 192+20+1, y:384 - 84 - i*30 + scoreScroll - 1)
            let	q2 = CGPoint(x: CGFloat(192-20+1)-s2.size(withAttributes: attr).width, y:CGFloat(384 - 84 - i*30 - 1 + scoreScroll))
            let	p1 = CGPoint(x: 192+20, y:384 - 84 - i*30 + scoreScroll)
            let	p2 = CGPoint(x: CGFloat(192-20)-s2.size(withAttributes: attr).width, y:CGFloat(384 - 84 - i*30 + scoreScroll))
            attr[NSAttributedString.Key.foregroundColor] = NSColor.black
            s1.draw(at: q1, withAttributes: attr)
            s2.draw(at: q2, withAttributes: attr)
            attr[NSAttributedString.Key.foregroundColor] = NSColor.yellow
            s1.draw(at: p1, withAttributes: attr)
            s2.draw(at: p2, withAttributes: attr)
        }

        legendImage.unlockFocus()
        legendSprite = Sprite(image: legendImage, cropRect: legendR, size: legendImage.size)
        showHighScores = false
    }

    func setLastMoveDate() {
        ticsSinceLastMove = 0
    }

    func graphicSetUp() {
        spriteArray = GameView.constructSpriteArray()
    }

    func setHTMLHiScoreLegend(_ s:NSString) {
        if let sp = s.utf8String {
            let d = Data(bytes:sp, count: s.length)
            if let attrS = NSAttributedString(html: d, documentAttributes: nil) {
                hiScoreLegend = attrS
            }
        }
    }

}

