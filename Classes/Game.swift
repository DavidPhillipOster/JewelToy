//
//  Game.swift
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

class Game {
    var board:[Gem] = {
        var a:[Gem] = []
        for i in 0..<NUMX*NUMY {
            a.append(Gem())
        }
        return a
    }()
    var bonusMultiplier = 1
    var cascade = 0
    var gemsFaded = 0
    var hintX = 0
    var hintY = 0
    var muted:Bool = false {
        didSet {
          for gem in board {
            gem.mute = muted
          }
        }
    }
    var scoreBubbles:[ScoreBubble] = []
    var score = 0
    var sx1 = 0
    var sy1 = 0
    var sx2 = 0
    var sy2 = 0

    init(){}
    init(sprites:[Sprite]) {
        for i in 0..<NUMX {
            for j in 0..<NUMY {
              let r = randomGemTypeAt(i, j)
              let gem = Gem(r, sprite: sprites[r])
              gem.setPositionOnBoard(i, j)
              gem.setPositionOnScreen(i*DIM, j*DIM)
              gem.shake()
              board[j*NUMY+i] = gem
            }
        }
    }

    func randomGemTypeAt(_ x:Int, _ y:Int) -> Int {
        let c = (x+y) % 2
        let r = arc4random_uniform(UInt32(NUMGEM));
        if c != 0 {
            return Int(r & 6)	// even
        }
        if r == 6 {
          return 1	// catch returning 7
        }
        return Int(r | 1)
    }

    func collectGemsFaded() -> CGFloat {
        let result = CGFloat(gemsFaded)
        gemsFaded = 0
        return result
    }

    func gemAt(_ x:Int, _ y:Int) -> Gem {
        return board[y*NUMY+x]
    }

    func hintPoint() -> CGPoint {
        return CGPoint(x:CGFloat(hintX*DIM), y:CGFloat(hintY*DIM))
    }

    func increaseBonusMultiplier() {
        bonusMultiplier += 1
    }

    func setSprites(_ sprites:[Sprite]){
        for i in 0..<NUMX {
            for j in 0..<NUMY {
                board[j*NUMY+i].sprite = sprites[gemAt(i,j).gemType]
            }
        }
    }

    func removeFadedGemsAndReorganiseWithSprites(_ sprites:[Sprite]) {
        for i in 0..<NUMX {
            var column:[Gem] = []
            var y = 0
            var fades = 0
            for j in 0..<NUMY {
                let gem = gemAt(i,j)
                if !gem.isFading {
                    column.append(gem)
                    if CGFloat(y*DIM) < gem.positionOnScreen.y {
                        gem.fall()
                    }
                    y += 1
                } else {
                    fades += 1
                }
            }
            // transfer faded gems to top of column
            for j in 0..<NUMY {
                let gem = gemAt(i,j)
                if gem.isFading {
                    let r = Int(arc4random_uniform(UInt32(NUMGEM)))
                    gem.gemType = r
                    gem.sprite = sprites[r]
                    column.append(gem)
                    gem.setPositionOnScreen(i*DIM, (7+fades)*DIM)
                    gem.fall()
                    y += 1
                    gemsFaded += 1
                    fades -= 1
                }
            }
            // reorganise column
            for j in 0..<NUMY {
              board[j*NUMY+i] = column[j]
              column[j].setPositionOnBoard(i, j)
            }
        }
    }

    func boardHasMoves() -> Bool {
        var result = false
        for j in 0..<NUMY {
            for i in 0..<(NUMX-1) {
                swap(i,j, i+1, j)
                result = checkForThreeAt(i, j) || checkForThreeAt(i+1, j)
                unswap()
                if result {
                    hintX = i
                    hintY = j
                    return result
                }
            }
        }
        for i in 0..<NUMX {
            for j in 0..<(NUMY-1) {
                swap(i,j, i, j+1)
                result = checkForThreeAt(i, j) || checkForThreeAt(i, j+1)
                unswap()
                if result {
                    hintX = i
                    hintY = j
                    return result
                }
            }
        }
        return result
    }

    func checkBoardForThrees() -> Bool {
        var result = false
        cascade += 1
        for i in 0..<NUMX {
            for j in 0..<NUMY {
                if !board[j*NUMY + i].isFading {
                    if testForThreeAt(i,j) {
                        result = true
                    }
                }
            }
        }
        if !result {
            cascade = 1
        }
        return result
    }

    func checkForThreeAt(_ x:Int, _ y:Int) -> Bool {
        let gem = gemAt(x, y)
        let gemType = gem.gemType
        var tx = x
        var ty = y
        var cx = x
        var cy = y
        while 0 < tx && gemAt(tx-1, y).gemType == gemType { tx -= 1 }
        while cx < (NUMX-1) && gemAt(cx+1, y).gemType == gemType { cx += 1 }
        if 2 <= cx - tx {   // horizontal line
            return true
        }
        while 0 < ty && gemAt(x, ty-1).gemType == gemType { ty -= 1 }
        while cy < (NUMY-1) && gemAt(x, cy+1).gemType == gemType { cy += 1 }
        if 2 <= cy - ty {   //vertical line
            return true
        }
        return false
    }

    func finalTestForThreeAt(_ x:Int, _ y:Int) {
        let gem = gemAt(x, y)
        if gem.isFading {
            return
        }
        let gemType = gem.gemType
        var tx = x
        var ty = y
        var cx = x
        var cy = y
        while 0 < tx && gemAt(tx-1, y).gemType == gemType { tx -= 1 }
        while cx < (NUMX-1) && gemAt(cx+1, y).gemType == gemType { cx += 1 }
        if 2 <= cx - tx {   // horizontal line
            for i in tx...cx {
                gemAt(i, y).fade()
            }
        }
        while 0 < ty && gemAt(x, ty-1).gemType == gemType { ty -= 1 }
        while cy < (NUMY-1) && gemAt(x, cy+1).gemType == gemType { cy += 1 }
        if 2 <= cy - ty {   //vertical line
            for j in ty...cy {
                gemAt(x, j).fade()
            }
        }
    }

    func testForThreeAt(_ x:Int, _ y:Int) -> Bool {
        let gem = gemAt(x, y)
        var result = gem.isFading
        let gemType = gem.gemType
        var bonus = 0
        var linebonus = 0
        var scorePerGem = 0
        var scorebubble_x:CGFloat = -1.0
        var scorebubble_y:CGFloat = -1.0
        var tx = x
        var ty = y
        var cx = x
        var cy = y
        while 0 < tx && gemAt(tx-1, y).gemType == gemType { tx -= 1 }
        while cx < (NUMX-1) && gemAt(cx+1, y).gemType == gemType { cx += 1 }
        if 2 <= cx - tx {   // horizontal line
            linebonus = 0
            scorePerGem = (cx-tx)*5
            for i in tx...cx {
                linebonus += scorePerGem
                board[y*NUMY + i].fade()
                var j = (NUMY-1)
                while j > y {
                    if !board[j*NUMY+i].isFading {
                        board[j*NUMY+i].shiver()
                    }
                    j -= 1
                }
            }
            scorebubble_x = CGFloat(tx) + CGFloat(cx-tx)/CGFloat(2.0)
            scorebubble_y = CGFloat(y)
            bonus += linebonus
            result = true
        }
        while 0 < ty && gemAt(x, ty-1).gemType == gemType { ty -= 1 }
        while cy < (NUMY-1) && gemAt(x, cy+1).gemType == gemType { cy += 1 }
        if 2 <= cy - ty {   //vertical line
            linebonus = 0
            scorePerGem = (cy-ty)*5
            for j in ty...cy {
                linebonus += scorePerGem
                board[j*NUMY + x].fade()
            }
            var j = (NUMY-1)
            while j > cy {
                if !board[j*NUMY + x].isFading {
                    board[j*NUMY + x].shiver()
                }
                j -= 1
            }
            // to center scorebubble ...
            if scorebubble_x < 0 { // only if one hasn't been placed already ! (for T and L shapes)
                scorebubble_x = CGFloat(x)
                scorebubble_y = CGFloat(ty) + CGFloat(cy-ty)/2.0
            } else {
                scorebubble_x = CGFloat(x)
                scorebubble_y = CGFloat(y)
            }
            bonus += linebonus
            result = true
        }
        if 1 <= cascade {
            bonus *= cascade
        }
        if 0 < bonus {
            let p = CGPoint(x:scorebubble_x*CGFloat(DIM)+CGFloat(DIM/2), y:scorebubble_y*CGFloat(DIM)+CGFloat(DIM/2))
            scoreBubbles.append(ScoreBubble(value: bonus*bonusMultiplier, at: p, duration: 40))
        }
        score += bonus * bonusMultiplier
        return result
    }

    func swap(_ x1:Int, _ y1:Int, _ x2:Int, _ y2:Int) {
      let swap = gemAt(x1, y1)
      board[ y1*NUMY + x1] = board[ y2*NUMY + x2]
      board[ y1*NUMY + x1].setPositionOnBoard(x1, y1)

      board[ y2*NUMY + x2] = swap
      board[ y2*NUMY + x2].setPositionOnBoard(x2, y2)
      sx1 = x1
      sy1 = y1
      sx2 = x2
      sy2 = y2
    }

    func unswap() {
        swap(sx1, sy1, sx2, sy2)
    }

    func erupt() {
        if !muted {
            NSSound(named: "yes")?.play()
        }
        for gem in board {
            gem.erupt()
        }
    }

    func explodeGameOver() {
        if !muted {
            NSSound(named: "explosion")?.play()
        }
        showAllBoardMoves()
    }

    // return true if this did anything
    func scoreBubblesAnimate() -> Bool {
        var needsUpdate = false
        var index:Int = scoreBubbles.count - 1
        while 0 <= index {
            let bubble = scoreBubbles[index]
            let more = bubble.animate()
            if more == 0 {
                scoreBubbles.remove(at: index)
            }
            needsUpdate = true
            index -= 1
        }
        return needsUpdate
    }

    func scoreBubblesDraw() {
        for bubble in scoreBubbles {
            bubble.drawSprite()
        }
    }

    func shake() {
        for gem in board {
            gem.shake()
        }
    }

    func showAllBoardMoves() {
    // horizontal moves
        for j in 0..<NUMY {
            for i in 0..<(NUMY-1) {
              swap(i, j, i+1, j)
              finalTestForThreeAt(i, j)
              finalTestForThreeAt(i+1, j)
              unswap()
            }
        }
    // vertical moves
        for i in 0..<NUMX {
            for j in 0..<(NUMY-1) {
              swap(i, j, i, j+1)
              finalTestForThreeAt(i, j)
              finalTestForThreeAt(i, j+1)
              unswap()
            }
        }
    // over the entire board, set the animationtime for the marked gems higher
        for i in 0..<NUMX {
            for j in 0..<NUMY {
                if board[j*NUMY+i].isFading {
                    board[j*NUMY+i].erupt()
                    board[j*NUMY+i].animationCounter = 1
                } else {
                    board[j*NUMY+i].erupt()
                }
            }
        }
    }

    func wholeNewGame(sprites:[Sprite]) {
        for i in 0..<NUMX {
            for j in 0..<NUMY {
                let r = randomGemTypeAt(i, j)
                let gem = gemAt(i, j)
                gem.gemType = r
                gem.sprite = sprites[r]
                gem.setPositionOnBoard(i, j)
                gem.setPositionOnScreen(i*DIM, (15-j)*DIM)
                gem.fall()
            }
        }
        score = 0
        gemsFaded = 0
        bonusMultiplier = 1
    }
}
