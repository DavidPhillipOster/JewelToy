//
//  Xem.swift
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

class Xem {
    enum GemState {
        case unknown
        case resting
        case fading
        case falling
        case shaking
        case erupting
        case moving
        case shivering
    }
    static let Z = -0.25
    var state:GemState = .unknown
    let ERUPT_DELAY = 45
    let FADE_STEPS = 8.0
    let GRAVITY = 1.46
    let dim = 48.0
    let	tink = NSSound(named: "tink")!
    let	sploink = NSSound(named: "sploink")!
    var mute = false
    var isFading: Bool { state == .fading }
    var animationCounter = 0
    var gemType = 0
    var waitForFall = 0
    var vx = 0.0
    var vy = 0.0
    var sprite:Xprite?
    var positionOnBoard = CGPoint.zero
    var positionOnScreen = CGPoint.zero

    init(){}
    init(_ n:Int, sprite:Xprite) {
        gemType = n
        self.sprite = sprite
    }

    func restStep(){
        positionOnScreen = NSMakePoint(positionOnBoard.x*dim, positionOnBoard.y*dim)
        animationCounter = 0
    }

    func fadeStep() {
        positionOnScreen = NSMakePoint(positionOnBoard.x*dim, positionOnBoard.y*dim)
        if 0 < animationCounter { animationCounter -= 1 }
    }

    func shiverStep() {
        positionOnScreen = NSMakePoint(positionOnBoard.x*dim + Double(Int16(arc4random_uniform(3)))-1, positionOnBoard.y*dim)
    }

    func fallStep() {
        if animationCounter < waitForFall {
            positionOnScreen.x = positionOnBoard.x*dim
            animationCounter += 1
        } else if (positionOnScreen.y > positionOnBoard.y*dim) {
            positionOnScreen.y += vy
            positionOnScreen.x = positionOnBoard.x*dim
            vy -= GRAVITY;
            animationCounter += 1
        } else {
            if !tink.isPlaying && !mute {tink.play()}
            positionOnScreen.y = positionOnBoard.y * dim;
            state = .resting;
        }
    }

    func shakeStep() {
        positionOnScreen.x = positionOnBoard.x*dim+Double(Int16(arc4random_uniform(5)))-2
        positionOnScreen.y = positionOnBoard.y*dim+Double(Int16(arc4random_uniform(5)))-2
        if animationCounter > 1 {
            animationCounter -= 1
        } else {
            state = .resting
        }
    }

    func eruptStep() {
        if positionOnScreen.y > -dim {
            if ERUPT_DELAY < animationCounter {
                positionOnScreen.x = positionOnBoard.x*dim+Double(Int16(arc4random_uniform(5)))-2
                positionOnScreen.y = positionOnBoard.y*dim+Double(Int16(arc4random_uniform(5)))-2
            } else {
                positionOnScreen.y += vy
                positionOnScreen.x += vx
                vy -= GRAVITY;
            }
            animationCounter -= 1
        } else {
            animationCounter = 0
        }
    }

    func moveStep() {
        if 0 < animationCounter {
            positionOnScreen.y += vy
            positionOnScreen.x += vx
            animationCounter -= 1
        } else {
            state = .resting
        }
    }

    func noop(){
    }

    func animate() -> Int {
        switch state {
        case .unknown: noop()
        case .resting: restStep()
        case .fading: fadeStep()
        case .falling: fallStep()
        case .shaking: shakeStep()
        case .erupting: eruptStep()
        case .moving: moveStep()
        case .shivering: shiverStep()
        }
        return animationCounter
    }

    func fade(){
        if !sploink.isPlaying && !mute {sploink.play()}
        state = .fading
        animationCounter = Int(FADE_STEPS)
    }

    func fall(){
        state = .falling
        waitForFall = Int(arc4random_uniform(6))
        vx = 0
        vy = 0
        animationCounter = 1
    }

    func shiver(){
        state = .shivering
        animationCounter = 0
    }

    func shake() {
        state = .shaking
        animationCounter = 25
    }

    func erupt(){
        vx = Double(Int16(arc4random_uniform(5))-2)
        vy = Double(Int16(arc4random_uniform(7))-2)
        state = .erupting
        animationCounter = ERUPT_DELAY
    }

    func setVelocity(_ x:Int, _ y:Int, _ steps:Int) {
        vx = Double(x)
        vy = Double(y)
        animationCounter = steps
        state = .moving
    }

    func setPositionOnBoard(_ x:Int, _ y:Int){
        positionOnBoard.x = CGFloat(x)
        positionOnBoard.y = CGFloat(y)
    }

    func setPositionOnScreen(_ x:Int, _ y:Int){
        positionOnScreen.x = CGFloat(x)
        positionOnScreen.y = CGFloat(y)
    }

    func drawSprite(){
        if .fading == state {
            sprite?.blit(x: positionOnScreen.x, y: positionOnScreen.y, z: Xem.Z, alpha: CGFloat((Double(animationCounter) / FADE_STEPS)))
        } else {
            sprite?.blit(x: positionOnScreen.x, y: positionOnScreen.y, z: Xem.Z)
        }
    }
}


@objc public class Gem : NSObject {
    let g:Xem
    @objc public var isFading: Bool { g.isFading }
    @objc public var gemType:Int {
        get { g.gemType }
        set(n){ g.gemType = n }
    }
    @objc public var animationCounter:Int {
        get { g.animationCounter }
        set(n) { g.animationCounter = n }
    }
    @objc public var mute: Bool {
        get { g.mute }
        set(n) { g.mute = n }
    }
    @objc public var positionOnScreen: CGPoint { g.positionOnScreen }
    @objc public var sprite:Sprite? {
        get {
            if let s = g.sprite {
                return Sprite(xprite:s)
            } else {
                return nil
            }

        }
        set(s){
            if let sprite = s?.s {
                g.sprite = sprite
            } else {
                g.sprite = nil
            }
        }
    }

    @objc public override init() {
        g = Xem()
    }
    @objc public init(_ n:Int, sprite:Sprite) {
        g = Xem(n, sprite:sprite.s)
    }

    @objc public func setVelocity(_ x:Int, _ y:Int, _ steps:Int) {
        g.setVelocity(x, y, steps)
    }

    @objc public func drawSprite() {
        g.drawSprite()
    }

    @objc public func animate() -> Int {
        return g.animate()
    }

    @objc public func erupt(){
        g.erupt()
    }

    @objc public func fall(){
        g.fall()
    }

    @objc public func fade() {
        g.fade()
    }

    @objc public func shake() {
        g.shake()
    }

    @objc public func shiver() {
        g.shiver()
    }

    @objc public func setPositionOnBoard(_ x:Int, _ y:Int){
        g.setPositionOnBoard(x, y)
    }

    @objc public func setPositionOnScreen(_ x:Int, _ y:Int){
        g.setPositionOnScreen(x, y)
    }
}

