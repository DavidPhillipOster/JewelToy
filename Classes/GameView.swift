//
//  GameView.swift
//  JewelToy
//
//  Created by david on 8/4/23.
//

import AppKit

@objc public class GameView : NSView {

    @objc @IBOutlet var gameController:GameController!

    @objc public var animating = false
    var animationStatus = false
    var backgroundColor:NSColor = .purple
    var dragStartPoint = NSPoint.zero
    var game:Xame?
    var hiScoreLegend = NSAttributedString()
    var hiScoreNumbers:[NSNumber] = []
    var hiScoreNames:[String] = []
    @objc public var muted = false
    @objc public var paused = false {
      didSet {
        if paused {
            animationStatus = animating
            animating = false
        } else {
            animating = animationStatus
        }
      }
    }
    var showHighScores = false
    @objc public var showHint = true
    var scoreScroll = 0
    var ticsSinceLastMove = 0
    var backgroundSprite:Xprite = GameView.constructSpriteBackground()
    let crosshairSprite:Xprite = {
        let crossImage = NSImage(named:"cross")!
        return Xprite(image: crossImage, cropRect: CGRect(origin: .zero, size: crossImage.size), size: CGSize(width: DIM, height: DIM))
    }()
    var legendSprite:Xprite?
    let movehintSprite:Xprite = {
        let movehintImage = NSImage(named:"movehint")!
        return Xprite(image: movehintImage, cropRect: CGRect(origin: .zero, size: movehintImage.size), size: CGSize(width: DIM, height: DIM))
    }()
    var gemSpriteArray:[Xprite] = GameView.constructSpriteArray()

    @objc public override init(frame frameRect: NSRect) {
        super.init(frame:frameRect)
        setLengend(image: NSImage(named: "title")!)
    }

    @objc public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setLengend(image: NSImage(named: "title")!)
    }

    public override var isOpaque:Bool { true }

    public override func draw(_ dirtyRect: NSRect) {
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
        if gameController.gameState == GAMESTATE_AWAITINGSECONDCLICK {
            let p = gameController.crossHair1Position
            crosshairSprite.blit(x: p.x, y: p.y, z: -0.5)
        }
        if showHighScores {
            showScores()    // draws the HighScores in legendSprite
        }
        if let legendSprite = legendSprite {
            if 500 < ticsSinceLastMove {
                setLengend(image: NSImage(named: "title")!) // show Logo
            }
            legendSprite.blit(x: 0, y: 0, z: -0.75)
        } else if let game = game, 500 < ticsSinceLastMove && showHint {
            movehintSprite.blit(x: game.hintPoint().x, y: game.hintPoint().y, z: -0.4, alpha: (sin((CGFloat(ticsSinceLastMove)-497.0)/4.0)+1.0)/2.0)
        }
    }

    /// called from timer
    @objc public func animate(){
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

    class func constructSpriteBackground() -> Xprite {
        let backgroundImage:NSImage = {
            if let data = UserDefaults.standard.data(forKey: "backgroundTiffData"),
               let background = NSImage(data:data) {
                return background
            } else {
                return NSImage(named:"background")!
            }
        }()
        return Xprite(image: backgroundImage, cropRect: CGRect(origin: .zero, size: backgroundImage.size), size: CGSize(width: DIM*NUMX, height: DIM*NUMY))
    }

    class func constructSpriteArray() -> [Xprite] {
        let useAlternateGraphics = UserDefaults.standard.bool(forKey: "useAlternateGraphics")
        let useImportedGraphics = UserDefaults.standard.bool(forKey: "useImportedGraphics")
        var gemImageArray:[NSImage] = []
        if useAlternateGraphics && !useImportedGraphics {
            for i in 1...NUMGEM {
                gemImageArray.append(NSImage(named:"\(i)gemA")!)
            }
        } else if useImportedGraphics {
            for i in 1...NUMGEM {
              if let data = UserDefaults.standard.data(forKey: "tiffGemImage\(i)"),
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
        var sprites:[Xprite] = []
        for image in gemImageArray {
            sprites.append(Xprite(image: image, cropRect: CGRect(origin: .zero, size: image.size), size: CGSize(width: DIM, height: DIM)))
            if sprites.count == NUMGEM { break }
        }
        return sprites
    }

    // was newBackground TODO
    func updateBackground() {
        gemSpriteArray = GameView.constructSpriteArray()
        needsDisplay = true
    }

    @objc public func setHTMLLegend(_ html:NSString) {
        if let sp = html.utf8String {
            let d = Data(bytes:sp, count: html.length)
            if let attrS = NSAttributedString(html: d, documentAttributes: nil) {
                setLengend(string: attrS)
            }
        }
    }

    @objc public func setLengend(string:NSAttributedString) {
        setLengend(block:{
            let size = string.size()
            let legendPoint = CGPoint(x:(CGFloat(DIM*NUMX) - size.width)/2, y:(CGFloat(DIM*NUMY) - size.height)/2)
            string.draw(at: legendPoint)
        })
    }

    @objc public func setLengend(image:NSImage) {
        setLengend(block:{
            let legendPoint = CGPoint(x:(CGFloat(DIM*NUMX) - image.size.width)/2, y:(CGFloat(DIM*NUMY) - image.size.height)/2)
            let r = NSMakeRect(0, 0, image.size.width, image.size.height)
            image.draw(at: legendPoint, from: r, operation: .sourceOver, fraction: 1)
        })
    }

    @objc public func setLengendNil() {
        legendSprite = nil
    }
    /// do the boilerplate of creating a full-game sprite.
    ///
    /// @param block - drawing functions to draw into the image.
    func setLengend(block:()->Void) {
        let legendImage = NSImage(size: CGSize(width: DIM*NUMX, height: DIM*NUMY))
        let legendR = NSMakeRect(0, 0, legendImage.size.width, legendImage.size.height)
        legendImage.lockFocus()
        NSColor.clear.set()
        NSBezierPath(rect:legendR).fill()
        block()
        legendImage.unlockFocus()
        legendSprite = Xprite(image: legendImage, cropRect: legendR, size: legendImage.size)
        ticsSinceLastMove = 0
        showHighScores = false
        animating = false
        needsDisplay = true
    }


    public override func mouseDown(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        dragStartPoint = convert(eventLocation, from: nil)
    }

    public override func mouseUp(with event: NSEvent) {
        let eventLocation = event.locationInWindow
        let center = convert(eventLocation, from: nil)
        if gameController.gameState == GAMESTATE_AWAITINGSECONDCLICK {
            gameController.receiveClick(at: Int32(center.x), Int32(center.y))
        } else if gameController.gameState == GAMESTATE_AWAITINGFIRSTCLICK {
            let chx1 = Int32(floor(dragStartPoint.x / CGFloat(DIM)))
            let chy1 = Int32(floor(dragStartPoint.y / CGFloat(DIM)))
            let chx2 = Int32(floor(center.x / CGFloat(DIM)))
            let chy2 = Int32(floor(center.y / CGFloat(DIM)))
            // only one of x,y changed - valid shove
            if (chx2 != chx1) != (chy2 != chy1) {
                gameController.receiveClick(at: Int32(dragStartPoint.x), Int32(dragStartPoint.y))
                gameController.receiveClick(at: Int32(center.x), Int32(center.y))
            } else {
                gameController.receiveClick(at: Int32(center.x), Int32(center.y))
            }
        }
    }

    @objc public func showHighScores(_ scores:[NSNumber], andNames names:[String]) {
        hiScoreNumbers = scores
        hiScoreNames = names
        showHighScores = true
        animating = false
        scoreScroll = 0;
        needsDisplay = true
    }

    public func showScores() {
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
        legendSprite = Xprite(image: legendImage, cropRect: legendR, size: legendImage.size)
        showHighScores = false
    }
    @objc public func setLastMoveDate() {
        ticsSinceLastMove = 0
    }

    @objc public func graphicSetUp() {
    }
    @objc public func newBackground() {
        updateBackground()
    }
    @objc public func setGame(_ game:Game) {
        self.game = game.g
    }
    @objc public func spriteArray() -> [Sprite] {
        var a:[Sprite] = []
        for s in gemSpriteArray {
            a.append(Sprite(xprite: s))
        }
        return a
    }

    @objc public func setHTMLHiScoreLegend(_ s:NSString) {
        if let sp = s.utf8String {
            let d = Data(bytes:sp, count: s.length)
            if let attrS = NSAttributedString(html: d, documentAttributes: nil) {
                hiScoreLegend = attrS
            }
        }
    }

}

