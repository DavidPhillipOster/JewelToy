//
//  GameController.swift
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

enum GameState {
  case awaitingGame
  case gameOver
  case awaitingFirstClick
  case awaitingSecondClick
  case fraculating
  case swapping
  case fading
  case falling
  case unswapping
  case exploding
  case finishedFraculating
}

class GameController : NSObject {
    @objc @IBOutlet var  aboutPanel:NSPanel?
    @objc @IBOutlet var  prefsPanel:NSPanel?
    @objc @IBOutlet var  gameView:GameView?

    @objc @IBOutlet var prefsStandardGraphicsButton:NSButton?
    @objc @IBOutlet var prefsAlternateGraphicsButton:NSButton?
    @objc @IBOutlet var prefsAlternateGraphicsImageView:NSImageView?
    @objc @IBOutlet var prefsCustomBackgroundCheckbox:NSButton?
    @objc @IBOutlet var prefsSelectFolderButton:NSButton?
    @objc @IBOutlet var prefsCustomBackgroundFolderTextField:NSTextField?
    @objc @IBOutlet var iv1:NSImageView?
    @objc @IBOutlet var iv2:NSImageView?
    @objc @IBOutlet var iv3:NSImageView?
    @objc @IBOutlet var iv4:NSImageView?
    @objc @IBOutlet var iv5:NSImageView?
    @objc @IBOutlet var iv6:NSImageView?
    @objc @IBOutlet var iv7:NSImageView?
    @objc @IBOutlet var easyGameButton:NSButton?
    @objc @IBOutlet var hardGameButton:NSButton?
    @objc @IBOutlet var toughGameButton:NSButton?
    @objc @IBOutlet var easyGameMenuItem:NSMenuItem?
    @objc @IBOutlet var hardGameMenuItem:NSMenuItem?
    @objc @IBOutlet var toughGameMenuItem:NSMenuItem?
    @objc @IBOutlet var abortGameButton:NSButton?
    @objc @IBOutlet var pauseGameButton:NSButton?
    @objc @IBOutlet var muteButton:NSButton?
    @objc @IBOutlet var abortGameMenuItem:NSMenuItem?
    @objc @IBOutlet var pauseGameMenuItem:NSMenuItem?
    @objc @IBOutlet var muteMenuItem:NSMenuItem?
    @objc @IBOutlet var freePlayMenuItem:NSMenuItem?
    @objc @IBOutlet var showHighScoresMenuItem:NSMenuItem?
    @objc @IBOutlet var resetHighScoresMenuItem:NSMenuItem?
    @objc @IBOutlet var scoreTextField:NSTextField?
    @objc @IBOutlet var bonusTextField:NSTextField?
    @objc @IBOutlet var timerView:TimerView?
    @objc @IBOutlet var gameWindow:NSWindow?
    @objc @IBOutlet var hiScorePanel:NSPanel?
    @objc @IBOutlet var hiScorePanelScoreTextField:NSTextField?
    @objc @IBOutlet var hiScorePanelNameTextField:NSTextField?

    var abortGame = false
    let SPEED_LIMIT	= 5000.0
    var chx1 = 0
    var chy1 = 0
    var chx2 = 0
    var chy2 = 0
    var freePlay = false
    var gameLevel = 0
    var gameSpeed = CGFloat(1)
    var gameTime = 3600.0
    var highScores:[[Any]] = []
    var gameState:GameState = .awaitingGame

    let gemMoveSpeed = 6
    let gemMoveSize = DIM
    let gemMoveSteps = DIM / 6
    let GEMS_FOR_BONUS = 100.0


    var muted = false
    let noMoreMovesString:NSString = NSLocalizedString("NoMoreMovesHTML", comment: "") as NSString
    let jeweltoyStartString:NSString = NSLocalizedString("JewelToyStartHTML", comment: "") as NSString
    let gameOverString:NSString = NSLocalizedString("GameOverHTML", comment: "") as NSString
    let game = Game()
    var paused = false
    var timer:Timer?
    let TIMER_INTERVAL = 0.04
    let titleImage = NSImage(named: "title")
    var useAlternateGraphics = UserDefaults.standard.bool(forKey: "useAlternateGraphics")
    var useImportedGraphics = UserDefaults.standard.bool(forKey: "useImportedGraphics")
    var useCustomBackgrounds = UserDefaults.standard.bool(forKey: "useCustomBackgrounds")
    var customBackgroundFolderPath:String?
    var wasPausedDuringPrefs = false
    var whatNext: () -> Void = {}

    override init(){
        super.init()
        if let hs = UserDefaults.standard.array(forKey: "highScores") as? [[Any]] {
            highScores = hs
        }
        if highScores.count < 8 {
            highScores = makeBlankHiScores()
        }
        customBackgroundFolderPath = UserDefaults.standard.string(forKey: "customBackgroundFolderPath")
        if nil == customBackgroundFolderPath {
            if let s = UserDefaults.standard.string(forKey: "PicturesFolderPath") {
                customBackgroundFolderPath = NSLocalizedString(s, comment: "")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        gameView?.game = game
    }

    @objc func windowWillClose(_ note:NSNotification) {
        if let obj = note.object  {
            if aboutPanel?.isEqual(obj) ?? false {
                aboutPanel = nil
            } else if prefsPanel?.isEqual(obj) ?? false {
                if let prefsAlternateGraphicsButton {
                    useAlternateGraphics = prefsAlternateGraphicsButton.state == .on
                    UserDefaults.standard.set(useAlternateGraphics, forKey: "useAlternateGraphics")
                    UserDefaults.standard.set(useImportedGraphics && useAlternateGraphics, forKey:"useImportedGraphics")
                }
                if let prefsCustomBackgroundCheckbox {
                    useCustomBackgrounds = prefsCustomBackgroundCheckbox.state == .on
                    UserDefaults.standard.set(useCustomBackgrounds, forKey: "useCustomBackgrounds")
                }
                UserDefaults.standard.removeObject(forKey: "customBackgroundFolderPath")
                if let prefsCustomBackgroundFolderTextField {
                    UserDefaults.standard.set(prefsCustomBackgroundFolderTextField.stringValue, forKey: "customBackgroundFolderPath")
                }
                if let gameView {
                    gameView.graphicSetUp()
                    gameView.updateBackground()
                    game.setSprites(gameView.spriteArray)
                    if !(gameState == .awaitingGame || gameState == .gameOver) {
                        gameView.needsDisplay = true
                    }
                }
                prefsPanel = nil
                if wasPausedDuringPrefs {
                    togglePauseMode(nil)
                }
            } else if gameWindow?.isEqual(obj) ?? false {
                NSApp.terminate(self)
            }
        }
    }

    // high scores is an array of arrays, 0th is an array, length 8 of strings 1st is an array length 10 of NSNumber integers
    func makeBlankHiScores() ->[[Any]] {
        var scores:[[Any]] = []
        let name = Bundle.main.localizedString(forKey: "AnonymousName", value: "Anonymous", table: nil) as NSString
        for _ in 1...4 {
            var names:[NSString] = []
            var nums:[NSNumber] = []
            for _ in 1...10 {
                names.append(name)
                nums.append(NSNumber(integerLiteral: 100))
            }
            scores.append(names)
            scores.append(nums)
        }
        return scores
    }

    @IBAction func prefsGraphicDropAction(_ sender: Any?) {
        if let importedImage = prefsAlternateGraphicsImageView?.image {
            var cropR = CGRect(x: 0, y: 0, width: importedImage.size.width/CGFloat(NUMGEM), height: importedImage.size.height)
            let gemR = CGRect(x: 0, y: 0, width: DIM, height: DIM)
            for i in 0..<NUMGEM {
                let gemImage = NSImage(size: gemR.size)
                let key = "tiffGemImage\(i)"
                cropR.origin.x = CGFloat(i) * importedImage.size.width/CGFloat(NUMGEM)
                gemImage.lockFocus()
                NSColor.clear.set()
                NSBezierPath(rect:gemR).fill()
                importedImage.draw(in: gemR, from: cropR, operation: .sourceOver, fraction: 1)
                gemImage.unlockFocus()
                UserDefaults.standard.set(gemImage.tiffRepresentation, forKey: key)
                if 0 == i { iv1?.image = gemImage }
                if 1 == i { iv2?.image = gemImage }
                if 2 == i { iv3?.image = gemImage }
                if 3 == i { iv4?.image = gemImage }
                if 4 == i { iv5?.image = gemImage }
                if 5 == i { iv6?.image = gemImage }
                if 6 == i {
                    iv7?.image = gemImage
                }
            }
            useImportedGraphics = true
        }
    }

    @IBAction func prefsCustomBackgroundCheckboxAction(_ sender: Any?) {
        if prefsCustomBackgroundCheckbox?.isEqual(sender) ?? false {
            prefsSelectFolderButton?.isEnabled = prefsCustomBackgroundCheckbox?.state == .on
            prefsCustomBackgroundFolderTextField?.isEnabled = prefsCustomBackgroundCheckbox?.state == .on
        }
    }

    @IBAction func prefsSelectFolderButtonAction(_ sender: Any?) {
        let op = NSOpenPanel()
        op.canChooseDirectories = true
        op.canChooseFiles = false
        op.allowsMultipleSelection = false
        let urlS = prefsCustomBackgroundFolderTextField?.stringValue
        if let urlS, !urlS.isEmpty {
            op.directoryURL = URL(fileURLWithPath: urlS)
        }
        op.beginSheetModal(for: prefsPanel!) { response in
            if response == .OK {
                var urlS = op.urls.first?.path ?? ""
                if !urlS.isEmpty {
                    let homeUrlS = NSHomeDirectory()
                    if urlS.hasPrefix(homeUrlS) {
                        urlS = "~" + urlS.suffix(from: homeUrlS.endIndex)
                    }
                    self.prefsCustomBackgroundFolderTextField?.stringValue = urlS
                    self.customBackgroundFolderPath = urlS
                }
            }
        }
    }


    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.isEqual(easyGameMenuItem) {
            return easyGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(hardGameMenuItem) {
            return hardGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(toughGameMenuItem) {
            return toughGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(freePlayMenuItem) {
            return easyGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(toughGameMenuItem) {
            return toughGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(abortGameMenuItem) {
            return abortGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(pauseGameMenuItem) {
            return pauseGameButton?.isEnabled ?? false
        }
        //
        // only allow viewing and reset of scores between games
        //
        if menuItem.isEqual(showHighScoresMenuItem) {
            return easyGameButton?.isEnabled ?? false
        }
        if menuItem.isEqual(resetHighScoresMenuItem) {
            return easyGameButton?.isEnabled ?? false
        }
        return true
    }

    @IBAction func startNewGame(_ sender: Any?) {
        easyGameButton?.isEnabled = false
        hardGameButton?.isEnabled = false
        toughGameButton?.isEnabled = false
        abortGameButton?.isEnabled = true
        pauseGameButton?.isEnabled = true
        abortGame = false
        gameSpeed = 1.0
        gameLevel = 0

        if easyGameButton?.isEqual(sender) ?? false || easyGameMenuItem?.isEqual(sender) ?? false {
            gameLevel = 0
            gameTime = 600.0 // ten minutes
            gameView?.setHTMLLegend(Bundle.main.localizedString(forKey: "EasyHighScoresHTML", value: nil, table: nil) as NSString)
        }
        if hardGameButton?.isEqual(sender) ?? false || hardGameMenuItem?.isEqual(sender) ?? false {
            gameLevel = 1
            gameTime = 180.0 // three minutes
            gameView?.setHTMLLegend(Bundle.main.localizedString(forKey: "HardHighScoresHTML", value: nil, table: nil) as NSString)
        }
        if toughGameButton?.isEqual(sender) ?? false || toughGameMenuItem?.isEqual(sender) ?? false {
            gameLevel = 2
            gameTime = 90.0 // one and a half minutes
            gameView?.setHTMLLegend(Bundle.main.localizedString(forKey: "ToughHighScoresHTML", value: nil, table: nil) as NSString)
        }
        if freePlayMenuItem?.isEqual(sender) ?? false {
            gameLevel = 3
            gameTime = 3600.0 // one hour FWIW
            gameView?.setHTMLLegend(Bundle.main.localizedString(forKey: "FreePlayHighScoresHTML", value: nil, table: nil) as NSString)
            freePlay = true
        } else {
            freePlay = false
        }
        if let gameView {
            game.wholeNewGame(sprites: gameView.spriteArray)
            scoreTextField?.stringValue = "\(game.score)"
            bonusTextField?.stringValue = "x\(game.bonusMultiplier)"
            game.muted = muted
            gameView.game = game
            gameView.legendSprite = nil
            gameView.paused = false
            gameView.muted = muted
            gameView.showHint = !freePlay
            timerView?.setTimerRunningEvery(0.5/gameSpeed, decrement: 0.5/gameTime,
                whenRunOut: { [weak self] in self?.runOutOfTime() },
                whenRunOver: { [weak self] in self?.bonusAwarded() })
            if freePlay {
                timerView?.decrement = 0.0
                timerView?.timer = 0.0
            }
            timerView?.paused = true
            gameView.setLastMoveDate()
            startAnimation({ [weak self] in self?.waitForFirstClick() })
        }
    }

    @IBAction func abortGame(_ sender:Any?) {
        abortGameButton?.isEnabled = false
        if paused {
            togglePauseMode(nil)
        }
        pauseGameButton?.isEnabled = false
        abortGame = true
        waitForFirstClick()
    }

    @IBAction func receiveHiScoreName(_ sender:Any?) {
        if let hiScorePanel,
            let hiScorePanelScoreTextField,
            let hiScorePanelNameTextField {

            let score = hiScorePanelScoreTextField.intValue
            let name = hiScorePanelNameTextField.stringValue as NSString
            hiScorePanel.endSheet(hiScorePanel)
            hiScorePanel.close()
            var gameNames = highScores[gameLevel*2] as? [NSString] ?? []
            var gameScores = highScores[gameLevel*2+1] as? [NSNumber] ?? []
            if gameScores.count == 10 && gameNames.count == 10 {
                for i in 0..<10 {
                    if gameScores[i].intValue < score {
                        gameScores.insert(NSNumber(value: score), at: i)
                        gameScores.remove(at: 10)
                        gameNames.insert(name, at: i)
                        gameNames.remove(at:10)
                        highScores[gameLevel*2] = gameNames
                        highScores[gameLevel*2+1] = gameScores
                        UserDefaults.standard.removeObject(forKey: "highScores")
                        UserDefaults.standard.set(highScores, forKey: "highScores")
                        break;
                    }
                }
            } else {
            // complain!
            }
            gameState = .gameOver
            setHighScoreLegend()
            gameView?.showHighScores(gameScores, andNames: gameNames)
            gameView?.setLastMoveDate()
        }
    }

    @IBAction func togglePauseMode(_ sender:Any?) {
        if pauseGameButton?.isEqual(sender) ?? false {
            paused = pauseGameButton!.state == .on
        } else {
            paused = !paused
            pauseGameButton?.state = paused ? .on : .off
        }
        timerView?.paused = paused
        gameView?.paused = paused
        if paused {
            let s = Bundle.main.localizedString(forKey: "PausedHTML", value: nil, table: nil) as NSString
            gameView?.setHTMLLegend(s)
            pauseGameMenuItem?.title = Bundle.main.localizedString(forKey: "ContinueGameMenuItemTitle", value: nil, table: nil)
        } else {
            gameView?.legendSprite = nil
            pauseGameMenuItem?.title = Bundle.main.localizedString(forKey: "PauseGameMenuItemTitle", value: nil, table: nil)
        }
    }

    @IBAction func toggleMute(_ sender:Any?) {
        if muteButton?.isEqual(sender) ?? false {
            muted = muteButton!.state == .on
        } else {
            muted = !muted
        }
        muteButton?.state = muted ? .on : .off
        gameView?.muted = muted
        game.muted = muted
        if muted {
            muteMenuItem?.title = Bundle.main.localizedString(forKey: "UnMuteGameMenuItemTitle", value: nil, table: nil)
        } else {
            muteMenuItem?.title = Bundle.main.localizedString(forKey: "MuteGameMenuItemTitle", value: nil, table: nil)
        }
    }

    @IBAction func orderFrontAboutPanel(_ sender:Any?) {
        if nil == aboutPanel {
            var top:NSArray? = nil
            Bundle.main.loadNibNamed("About", owner: self, topLevelObjects: &top)
        }
        aboutPanel?.makeKeyAndOrderFront(self)
    }

    @IBAction func orderFrontPreferencesPanel(_ sender:Any?) {
        if nil == prefsPanel {
            var top:NSArray? = nil
            Bundle.main.loadNibNamed("Preferences", owner: self, topLevelObjects: &top)
        }
        prefsStandardGraphicsButton?.state = !useAlternateGraphics ? .on : .off
        prefsAlternateGraphicsButton?.state = useAlternateGraphics ? .on : .off

        prefsCustomBackgroundCheckbox?.state = useCustomBackgrounds ? .on : .off
        if let customBackgroundFolderPath {
            prefsCustomBackgroundFolderTextField?.stringValue = customBackgroundFolderPath
        }
        prefsSelectFolderButton?.isEnabled = prefsCustomBackgroundCheckbox?.state == .on
        prefsCustomBackgroundFolderTextField?.isEnabled = prefsCustomBackgroundCheckbox?.state == .on
        if let _ = UserDefaults.standard.data(forKey: "tiffGemImage0") {
            for i in 0..<7 {
                if let data = UserDefaults.standard.data(forKey: "tiffGemImage\(i)"),
                    let gemImage = NSImage(data: data) {
                    if 0 == i { iv1?.image = gemImage }
                    if 1 == i { iv2?.image = gemImage }
                    if 2 == i { iv3?.image = gemImage }
                    if 3 == i { iv4?.image = gemImage }
                    if 4 == i { iv5?.image = gemImage }
                    if 5 == i { iv6?.image = gemImage }
                    if 6 == i { iv7?.image = gemImage }
                }
            }
        }
        prefsPanel!.makeKeyAndOrderFront(self)
        wasPausedDuringPrefs = !paused && !(gameState == .awaitingGame || gameState == .gameOver)
        if wasPausedDuringPrefs {
            togglePauseMode(nil)
        }
    }

    @IBAction func showHighScores(_ sender:Any?) {
        setHighScoreLegend()
        let gameNames = highScores[gameLevel*2] as? [NSString] ?? []
        let gameScores = highScores[gameLevel*2+1] as? [NSNumber] ?? []
        gameLevel = (gameLevel + 1) % 4
        gameView?.showHighScores(gameScores, andNames: gameNames)
        gameView?.setLastMoveDate()
    }

    @IBAction func resetHighScores(_ sender:Any?) {
        highScores = makeBlankHiScores()
        UserDefaults.standard.set(highScores, forKey: "highScores")
        showHighScores(sender)
    }

    func runOutOfTime() {
        gameState = .gameOver
        abortGameButton?.isEnabled = false
        pauseGameButton?.isEnabled = false
        abortGame = true
        gameView?.setHTMLLegend(gameOverString)
        game.shake()
        startAnimation({ [weak self] in self?.waitForNewGame() })
    }

    func checkHiScores() {
        let gameNames = highScores[gameLevel*2] as? [NSString] ?? []
        let gameScores = highScores[gameLevel*2+1] as? [NSNumber] ?? []
        for i in 0..<10 {
            if gameScores[i].intValue < game.score {
                hiScorePanelScoreTextField?.stringValue = "\(game.score)"
                if let hiScorePanel {
                    gameWindow?.beginSheet(hiScorePanel, completionHandler: nil)
                }
            }
        }
        setHighScoreLegend()
        gameView?.showHighScores(gameScores, andNames: gameNames)
    }

    func bonusAwarded() {
        gameView?.updateBackground()
        if !muted {
            NSSound(named: "yes")?.play()
        }
        if !freePlay {
            game.increaseBonusMultiplier()
            timerView?.decrementMeter(0.5)
        } else {
            game.increaseBonusMultiplier()
            timerView?.decrementMeter(1)
        }
        if gameSpeed < SPEED_LIMIT {
            gameSpeed = gameSpeed * 1.5
        }
        timerView?.setTimerRunningEvery(0.5/gameSpeed, decrement: 0.5/gameTime,
                                        whenRunOut:{  [weak self] in self?.runOutOfTime()  },
                                        whenRunOver: {  [weak self] in self?.bonusAwarded() })
        if freePlay {
            timerView?.decrement = 0
        }
    }

    func startAnimation(_ andThen:@escaping () -> Void) {
        if nil == timer {
            timer = Timer(timeInterval: TIMER_INTERVAL, repeats: true, block: { [weak self] timer in
                self?.gameView?.animate()
            })
            RunLoop.current.add(timer!, forMode: .common)
        }
        whatNext = andThen
        gameView?.animating = true
    }

    func animationEnded() {
        gameView?.animating = false
        whatNext()
        gameView?.needsDisplay = true
    }

    func waitForNewGame() {
        gameState = .awaitingGame
        checkHiScores()
        if let gameView,
            let titleImage {
            game.wholeNewGame(sprites: gameView.spriteArray)
            gameView.setLegend(image: titleImage)
            easyGameButton?.isEnabled = true
            hardGameButton?.isEnabled = true
            toughGameButton?.isEnabled = true
            abortGameButton?.isEnabled = false
            pauseGameButton?.isEnabled = false
        }
    }

    func newBoard1() {
        game.erupt()
        startAnimation({ [weak self] in self?.newBoard2() })
    }

    func newBoard2() {
        if let gameView {
            for i in 0..<NUMX {
                for j in 0..<NUMY {
                    let gem = game.gemAt(i, j)
                    let r = Int(arc4random_uniform(UInt32(NUMGEM)))
                    gem.gemType = r
                    gem.sprite = gameView.spriteArray[r]
                    gem.setPositionOnBoard(i, j)
                    gem.setPositionOnScreen(i*DIM, (i+j+8)*DIM)
                    gem.fall()
                }
            }
            gameView.updateBackground()
            gameView.legendSprite = nil
            startAnimation({ [weak self] in self?.testForThreesAgain() })
        }
    }

    func waitForFirstClick() {
        timerView?.paused = false
        if abortGame {
            timerView?.timer = 0.5
            timerView?.decrement = 0.0
            gameState = .gameOver
            game.explodeGameOver()
            startAnimation({ [weak self] in self?.waitForNewGame() })
            return
        }
        if !game.boardHasMoves() {
            timerView?.paused = false
            gameView?.setHTMLLegend(noMoreMovesString)
            game.shake()
            if freePlay {
                startAnimation({ [weak self] in self?.runOutOfTime() })
            } else {
                startAnimation({ [weak self] in self?.newBoard1() })
            }
            return
        }
        gameState = .awaitingFirstClick
    }

    func receiveClick(_ x:Int, _ y:Int) {
        if paused {
            return
        }
        if (x < 0)||(x > (DIM*NUMX - 1))||(y < 0)||(y > (DIM*NUMY - 1)) {
            return
        }
        let dim = CGFloat(DIM)
        if gameState == .awaitingFirstClick {
            chx1 = Int(floor(CGFloat(x) / dim))
            chy1 = Int(floor(CGFloat(y) / dim))
            gameState = .awaitingSecondClick
            gameView?.needsDisplay = true
            return
        }
        if gameState == .awaitingSecondClick {
            chx2 = Int(floor(CGFloat(x) / dim))
            chy2 = Int(floor(CGFloat(y) / dim))
            if (chx2 != chx1) != (chy2 != chy1) {	// xor!
                let d = (chx1-chx2)*(chx1-chx2)+(chy1-chy2)*(chy1-chy2)
                if d == 1 {
                    gameState = .fraculating
                    gameView?.needsDisplay = true
                    gameView?.setLastMoveDate()
                    timerView?.paused = true
                    tryMoveSwapping(chx1, chy1, chx2, chy2)
                    return
                }
            }
        }
        chx1 = Int(floor(CGFloat(x) / dim))
        chy1 = Int(floor(CGFloat(y) / dim))
        gameState = .awaitingSecondClick
        gameView?.needsDisplay = true
    }

    func tryMoveSwapping(_ x1:Int, _ y1:Int, _ x2:Int, _ y2:Int) {
        var xx1:Int
        var yy1:Int
        var xx2:Int
        var yy2:Int
        if x1 != x2 {
            if x1 < x2 {
                xx1 = x1
                xx2 = x2
            } else {
                xx1 = x2
                xx2 = x1
            }
            yy1 = y1
            yy2 = y2
        } else {
            if y1 < y2 {
                yy1 = y1
                yy2 = y2
            } else {
                yy1 = y2
                yy2 = y1
            }
            xx1 = x1
            xx2 = x2
        }
        // store swap positions
        chx1 = xx1
        chy1 = yy1
        chx2 = xx2
        chy2 = yy2;
        if chx1 < chx2 {	// swapping horizontally
            game.gemAt(chx1, chy1).setVelocity(gemMoveSpeed, 0, gemMoveSteps)
            game.gemAt(chx2, chy2).setVelocity(-gemMoveSpeed, 0, gemMoveSteps)
        } else { // swapping vertically
            game.gemAt(chx1, chy1).setVelocity(0, gemMoveSpeed, gemMoveSteps)
            game.gemAt(chx2, chy2).setVelocity(0, -gemMoveSpeed, gemMoveSteps)
        }
        game.swap(chx1, chy1, chx2, chy2)
        gameState = .swapping
        startAnimation({ [weak self] in self?.testForThrees() })
    }

    func testForThrees() {
        let oldScore = game.score
        var anyThrees = game.testForThreeAt(chx1, chy1)
        if game.testForThreeAt(chx2, chy2) {
            anyThrees = true
        }
        scoreTextField?.stringValue = "\(game.score)"
        scoreTextField?.needsDisplay = true
        bonusTextField?.stringValue = "x\(game.bonusMultiplier)"
        bonusTextField?.needsDisplay = true
        if oldScore < game.score {
            timerView?.incrementMeter(game.collectGemsFaded()/GEMS_FOR_BONUS)
        }
        if anyThrees {
            startAnimation({ [weak self] in self?.removeThreesAndReplaceGems() })
        } else {
            unSwap()
        }
    }

    func removeThreesAndReplaceGems() {
        if let spriteArray = gameView?.spriteArray {
            game.removeFadedGemsAndReorganiseWithSprites(spriteArray)
        }
        startAnimation({ [weak self] in self?.testForThreesAgain() })
    }

    func testForThreesAgain() {
        let oldScore = game.score
        let anyThrees = game.checkBoardForThrees()
        scoreTextField?.stringValue = "\(game.score)"
        scoreTextField?.needsDisplay = true
        bonusTextField?.stringValue = "x\(game.bonusMultiplier)"
        bonusTextField?.needsDisplay = true
        if oldScore < game.score {
            timerView?.incrementMeter(game.collectGemsFaded()/GEMS_FOR_BONUS)
        }
        if anyThrees {
            startAnimation({ [weak self] in self?.removeThreesAndReplaceGems() })
        } else {
            waitForFirstClick()
        }
    }

    func unSwap() {
        if !muted {
            NSSound(named: "no")?.play()
        }
        // swap positions
        if chx1 < chx2 {	// swapping horizontally
            game.gemAt(chx1, chy1).setVelocity(4, 0, 12)
            game.gemAt(chx2, chy2).setVelocity(-4, 0, 12)
        } else {    // swapping vertically
            game.gemAt(chx1, chy1).setVelocity(0, 4, 12)
            game.gemAt(chx2, chy2).setVelocity(0, -4, 12)
        }
        game.swap(chx1, chy1, chx2, chy2)
        gameState = .swapping
        startAnimation({ [weak self] in self?.waitForFirstClick() })
    }

    func setHighScoreLegend() {
        if gameLevel == 0 {
            let s = Bundle.main.localizedString(forKey: "EasyHighScoresHTML", value: nil, table: nil) as NSString
            gameView?.setHTMLHiScoreLegend(s)
        } else if gameLevel == 1 {
            let s = Bundle.main.localizedString(forKey: "HardHighScoresHTML", value: nil, table: nil) as NSString
             gameView?.setHTMLHiScoreLegend(s)
       } else if gameLevel == 2 {
            let s = Bundle.main.localizedString(forKey: "ToughHighScoresHTML", value: nil, table: nil) as NSString
            gameView?.setHTMLHiScoreLegend(s)
        } else if gameLevel == 3 {
            let s = Bundle.main.localizedString(forKey: "FreePlayHighScoresHTML", value: nil, table: nil) as NSString
            gameView?.setHTMLHiScoreLegend(s)
        }
    }

    var crossHair1Position: CGPoint { CGPoint(x:chx1*DIM, y:chy1*DIM) }

    var crossHair2Position: CGPoint { CGPoint(x:chx2*DIM, y:chy2*DIM) }

}

