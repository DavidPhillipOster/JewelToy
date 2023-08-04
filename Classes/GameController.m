/* ----====----====----====----====----====----====----====----====----====----
GameController.m (jeweltoy)

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

#import "GameController.h"
#import "Game.h"
#import "GameView.h"
#import "JewelToy-Swift.h"

typedef void (^Block)(void);

@interface GameController(Private)
- (void)setHighScores:(NSArray *)inarray;
@end

@implementation GameController {
    IBOutlet NSPanel		*aboutPanel, *prefsPanel;
    IBOutlet GameView		*gameView;
    IBOutlet NSButton		*prefsStandardGraphicsButton, *prefsAlternateGraphicsButton;
    IBOutlet NSImageView	*prefsAlternateGraphicsImageView;
    IBOutlet NSButton		*prefsCustomBackgroundCheckbox, *prefsSelectFolderButton;
    IBOutlet NSTextField	*prefsCustomBackgroundFolderTextField;
    IBOutlet NSImageView	*iv1, *iv2, *iv3, *iv4, *iv5, *iv6, *iv7;
    IBOutlet NSButton		*easyGameButton, *hardGameButton, *toughGameButton;
    IBOutlet NSMenuItem		*easyGameMenuItem, *hardGameMenuItem, *toughGameMenuItem;
    IBOutlet NSButton		*abortGameButton, *pauseGameButton, *muteButton;
    IBOutlet NSMenuItem		*abortGameMenuItem, *pauseGameMenuItem, *muteMenuItem;
    IBOutlet NSMenuItem		*freePlayMenuItem, *showHighScoresMenuItem, *resetHighScoresMenuItem;
    IBOutlet NSTextField	*scoreTextField, *bonusTextField;
    IBOutlet TimerView	*timerView;
    IBOutlet NSWindow		*gameWindow;
    IBOutlet NSPanel		*hiScorePanel;
    IBOutlet NSTextField	*hiScorePanelScoreTextField, *hiScorePanelNameTextField;

    NSLock		*animationTimerLock;

    NSArray		*highScores;

    int			*hintTimeSeconds;

    NSString		*noMoreMovesString, *jeweltoyStartString, *gameOverString;
    NSImage		*titleImage;

    BOOL		abortGame;
    NSTimer		*timer;
    Game		*game;
    int			gameLevel;
    float		gameSpeed;
    float		gameTime;
    int			gemMoveSpeed, gemMoveSteps, gemMoveSize;

    BOOL		useAlternateGraphics, useImportedGraphics, useCustomBackgrounds;
    BOOL		paused, freePlay, muted, animationStatus;

    NSString		*customBackgroundFolderPath;

    int			gameState, gemsSoFar, chx1, chy1, chx2, chy2;
    Block	    whatNext;
}


- (instancetype) init
{
    self = [super init];
    

    //NSLog(@"highScores : %@",highScores);

    [self setHighScores:[[NSUserDefaults standardUserDefaults] arrayForKey:@"highScores"]];
    if ((!highScores)||(highScores.count < 8))
    {
        //NSLog(@"Creating High Score Tables");
        [self setHighScores: [self makeBlankHiScoresWith:highScores]];
    }
    
    noMoreMovesString = [[NSBundle mainBundle]
                            localizedStringForKey:@"NoMoreMovesHTML"
                            value:nil table:nil];
    jeweltoyStartString = [[NSBundle mainBundle]
                            localizedStringForKey:@"JewelToyStartHTML"
                            value:nil table:nil];
    gameOverString = [[NSBundle mainBundle]
                            localizedStringForKey:@"GameOverHTML"
                            value:nil table:nil];
    titleImage = [NSImage imageNamed:@"title"];
    gameLevel = 0;
        
    game = [[Game alloc] init];
    animationTimerLock = [[NSLock alloc] init];
    
    gemMoveSize = GEM_GRAPHIC_SIZE;
    gemMoveSpeed = GEM_MOVE_SPEED;
    gemMoveSteps = gemMoveSize / gemMoveSpeed;
        
    useAlternateGraphics = [[NSUserDefaults standardUserDefaults] boolForKey:@"useAlternateGraphics"];
    useImportedGraphics = [[NSUserDefaults standardUserDefaults] boolForKey:@"useImportedGraphics"];
    
    useCustomBackgrounds = [[NSUserDefaults standardUserDefaults] boolForKey:@"useCustomBackgrounds"];
    customBackgroundFolderPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"customBackgroundFolderPath"];
    if (!customBackgroundFolderPath)
        customBackgroundFolderPath = [[NSBundle mainBundle] localizedStringForKey:@"PicturesFolderPath"
                                                                            value:nil table:nil];
    return self;
}


- (void)awakeFromNib
{
    [gameWindow setFrameAutosaveName:@"gameWindow"];
    //useAlternateGraphics = [[NSUserDefaults standardUserDefaults] boolForKey:@"useAlternateGraphics"];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    id obj = aNotification.object;
    if (obj == aboutPanel) {
        //NSLog(@"Someone closed the 'About' window");
        aboutPanel = nil;
    }else if (obj == prefsPanel) {
        //NSLog(@"Someone closed the 'Preferences' window");
        useAlternateGraphics = prefsAlternateGraphicsButton.state;
        [[NSUserDefaults standardUserDefaults]	setBool:useAlternateGraphics
                                                forKey:@"useAlternateGraphics"];
        [[NSUserDefaults standardUserDefaults]	setBool:useImportedGraphics
                                                forKey:@"useImportedGraphics"];

        useCustomBackgrounds = prefsCustomBackgroundCheckbox.state;
        [[NSUserDefaults standardUserDefaults]	setBool:useCustomBackgrounds
                                                forKey:@"useCustomBackgrounds"];
        [[NSUserDefaults standardUserDefaults]	removeObjectForKey:@"customBackgroundFolderPath"];
        [[NSUserDefaults standardUserDefaults]	setObject:prefsCustomBackgroundFolderTextField.stringValue
                                                  forKey:@"customBackgroundFolderPath"];
        if (gameView)
        {
            //[gameView loadImageArray];
            [gameView graphicSetUp];
            [gameView newBackground];
            if (game)	[game setSpritesFrom:[gameView spriteArray]];
            [gameView setNeedsDisplay:YES];
        }
        prefsPanel = nil;
    }else if (obj == gameWindow){
        //NSLog(@"Someone closed the window - shutting down JewelToy");
        [NSApp terminate:self];
    }
}


- (IBAction)prefsGraphicDropAction:(id)sender
{
    //
    //	slice and dice importedImage, saving images to defaults
    //
    NSImage *importedImage = prefsAlternateGraphicsImageView.image;
    if (importedImage)
    {
        int i = 0;
        NSRect	cropRect = NSMakeRect(0.0,0.0,importedImage.size.width/7.0,importedImage.size.height);
        NSRect	gemRect = NSMakeRect(0.0,0.0,48.0,48.0);
        NSSize imageSize = NSMakeSize(48.0,48.0);
        for (i = 0; i < 7; i++)
        {
            NSImage	*gemImage = [[NSImage alloc] initWithSize:imageSize];
            NSString *key = [NSString stringWithFormat:@"tiffGemImage%d", i];
            cropRect.origin.x = i * importedImage.size.width/7.0;
            [gemImage lockFocus];
            [[NSColor clearColor] set];
            NSRectFill(gemRect);
          [importedImage drawInRect:gemRect fromRect:cropRect operation:NSCompositingOperationSourceOver fraction:1.0];
            [gemImage unlockFocus];
            [[NSUserDefaults standardUserDefaults]	setObject:gemImage.TIFFRepresentation	forKey:key];
            if (i == 0)	iv1.image = gemImage;
            if (i == 1)	iv2.image = gemImage;
            if (i == 2)	iv3.image = gemImage;
            if (i == 3)	iv4.image = gemImage;
            if (i == 4)	iv5.image = gemImage;
            if (i == 5)	iv6.image = gemImage;
            if (i == 6)	iv7.image = gemImage;
        }
        useImportedGraphics = YES;
    }
        
}

- (IBAction)prefsCustomBackgroundCheckboxAction:(id)sender
{
    //NSLog(@"prefsCustomBackgroundCheckboxAction");

    if (sender!=prefsCustomBackgroundCheckbox)
        return;
    prefsSelectFolderButton.enabled = prefsCustomBackgroundCheckbox.state;
    prefsCustomBackgroundFolderTextField.enabled = prefsCustomBackgroundCheckbox.state;
    
}

- (IBAction)prefsSelectFolderButtonAction:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];

    //NSLog(@"prefsSelectFolderButtonAction");
    [op setCanChooseDirectories:YES];
    [op setCanChooseFiles:NO];
    NSURL *url = nil;
    NSString *urlS = prefsCustomBackgroundFolderTextField.stringValue;
    if (urlS) {
      url = [NSURL fileURLWithPath:urlS];
      if (url) {
        op.directoryURL = url;
      }
    }
    [op beginSheetModalForWindow:prefsPanel completionHandler:^(NSInteger result){
      if (result) {
        NSString *urlS = nil;
        NSURL *url = op.URLs.firstObject;
        urlS = url.path;
        NSString *homeUrlS = NSHomeDirectory();
        if ([urlS hasPrefix:homeUrlS]) {
          urlS = [@"~" stringByAppendingString:[urlS substringFromIndex:homeUrlS.length]];
        }
        self->prefsCustomBackgroundFolderTextField.stringValue = urlS;
      }
    }];
    // get a sheet going to let the user pick a folder to scan for pictures
//    [op beginSheetForDirectory:[prefsCustomBackgroundFolderTextField stringValue] file:NULL types:NULL modalForWindow:prefsPanel modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
//    [prefsCustomBackgroundFolderTextField setStringValue:[[sheet filenames] objectAtIndex:0]];
}

- (BOOL) validateMenuItem: (NSMenuItem*) aMenuItem
{
    if (aMenuItem == easyGameMenuItem)
        return easyGameButton.enabled;
    if (aMenuItem == hardGameMenuItem)
        return hardGameButton.enabled;
    if (aMenuItem == toughGameMenuItem)
        return toughGameButton.enabled;
    if (aMenuItem == freePlayMenuItem)
        return easyGameButton.enabled;
    if (aMenuItem == abortGameMenuItem)
        return abortGameButton.enabled;
    if (aMenuItem == pauseGameMenuItem)
        return pauseGameButton.enabled;
    //
    // only allow viewing and reset of scores between games
    //
    if (aMenuItem == showHighScoresMenuItem)
        return easyGameButton.enabled;
    if (aMenuItem == resetHighScoresMenuItem)
        return easyGameButton.enabled;
    return YES;
}

- (IBAction)startNewGame:(id)sender
{
    //NSLog(@"gameController.startNewGame messaged gameView:%@",gameView);
    
    [easyGameButton setEnabled:NO];
    [hardGameButton setEnabled:NO];
    [toughGameButton setEnabled:NO];
    [abortGameButton setEnabled:YES];
    [pauseGameButton setEnabled:YES];

    abortGame = NO;
    gameSpeed = 1.0;
    gameLevel = 0;
    
    if ((sender==easyGameButton)||(sender==easyGameMenuItem))
    {
        //NSLog(@"debug - highScores = %@\n...highScores.count = %d",highScores,[highScores count]);
        gameLevel = 0;
        gameTime = 600.0; // ten minutes
        [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"EasyHighScoresHTML"
                                            value:nil table:nil]];
    }
    if ((sender==hardGameButton)||(sender==hardGameMenuItem))
    {
        gameLevel = 1;
        gameTime = 180.0; // three minutes
        [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"HardHighScoresHTML"
                                            value:nil table:nil]];

    }
    if ((sender==toughGameButton)||(sender==toughGameMenuItem))
    {
        gameLevel = 2;
        gameTime = 90.0; // one and a half minutes
        [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"ToughHighScoresHTML"
                                            value:nil table:nil]];
    }
    if (sender==freePlayMenuItem)
    {
        gameLevel = 3;
        gameTime = 3600.0; // one hour FWIW
        freePlay = YES;//	FREEPLAY
        [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"FreePlayHighScoresHTML"
                                            value:nil table:nil]];
    }
    else
        freePlay = NO;//	FREEPLAY
    [game wholeNewGameWithSpritesFrom:[gameView spriteArray]];

//
    scoreTextField.stringValue = [NSString stringWithFormat:@"%d",[game score]];
    [scoreTextField setNeedsDisplay:YES];
    bonusTextField.stringValue = [NSString stringWithFormat:@"x%d",[game bonusMultiplier]];
    [bonusTextField setNeedsDisplay:YES];
//
    
    [game setMuted:muted];
    [gameView setGame:game];
    [gameView setLegend:nil];
    [gameView setPaused:NO];
    [gameView setMuted:muted];
    [gameView setShowHint:!freePlay];//		FREEPLAY

    __weak typeof(self) weakSelf = self;
    [timerView setTimerRunningEvery:0.5/gameSpeed
                decrement:(0.5/gameTime)
                whenRunOut:^{ [weakSelf runOutOfTime]; }
                whenRunOver:^{ [weakSelf bonusAwarded]; }];
    
    if (freePlay)
    {
        [timerView setDecrement:0.0];//	FREEPLAY MW
        [timerView setTimer:0.0];
    }
    
    [timerView setPaused:YES];
        
    [gameView setLastMoveDate];
    [self startAnimation:^{ [weakSelf waitForFirstClick]; }];
}

- (IBAction)abortGame:(id)sender
{
    [abortGameButton setEnabled:NO];
    if (paused) [self togglePauseMode:self];
    [pauseGameButton setEnabled:NO];
    abortGame = YES;
    [self waitForFirstClick];
}
- (IBAction)receiveHiScoreName:(id)sender
{
    int		i;
    int		score = hiScorePanelScoreTextField.intValue;
    NSString 	*name = hiScorePanelNameTextField.stringValue;

    [NSApp endSheet:hiScorePanel];
    [hiScorePanel close];
    
    //NSLog(@"receiving HiScoreName:%@ %d",name,score);
    
    // reset arrays to gameLevel    
    NSMutableArray *gameNames = [highScores[gameLevel*2] mutableCopy];
    NSMutableArray *gameScores = [highScores[gameLevel*2+1] mutableCopy];
    
    for (i = 0; i < 10; i++)
    {
        if (score > [gameScores[i] intValue])
        {
            [gameScores	insertObject:@(score) atIndex:i];
            [gameScores	removeObjectAtIndex:10];
            [gameNames	insertObject:name atIndex:i];
            [gameNames	removeObjectAtIndex:10];
            break;
        }
    }

    NSMutableArray *newHighScores = [highScores mutableCopy];
    newHighScores[gameLevel*2] = gameNames;
    newHighScores[gameLevel*2+1] = gameScores;
    [self setHighScores:newHighScores];

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"highScores"];	// or it won't work!?!
    [[NSUserDefaults standardUserDefaults] setObject:highScores forKey:@"highScores"];

    //NSLog(@"written high-scores to preferences");
    
    gameState = GAMESTATE_GAMEOVER;
    [gameView showHighScores:gameScores andNames:gameNames];
    [gameView setLastMoveDate];	//reset timer so scores show for 20s    
}

- (IBAction)togglePauseMode:(id)sender
{
    //NSLog(@"Pause game toggled, sender state is %d",[sender state]);
    if (sender == pauseGameButton)
        paused = ((NSButton *)sender).state;
    else
        paused = !paused;
    
    pauseGameButton.state = paused;
    [timerView setPaused:paused];
    if (paused)
    {
        [gameView setPaused:YES];
        [gameView setHTMLLegend:[[NSBundle mainBundle]
                            localizedStringForKey:@"PausedHTML"
                            value:nil table:nil]];
        pauseGameMenuItem.title = [[NSBundle mainBundle]
                            localizedStringForKey:@"ContinueGameMenuItemTitle"
                            value:nil table:nil];
    }
    else
    {
        [gameView setPaused:NO];
        [gameView setLegend:nil];
        pauseGameMenuItem.title = [[NSBundle mainBundle]
                            localizedStringForKey:@"PauseGameMenuItemTitle"
                            value:nil table:nil];
    }
}

- (IBAction)toggleMute:(id)sender
{
    if (sender == muteButton)
        muted = ((NSButton *)sender).state;
    else
        muted = !muted;
    
    muteButton.state = muted;
    [gameView setMuted:muted];
    [game setMuted:muted];
    
    if (muted)
        muteMenuItem.title = [[NSBundle mainBundle]
                            localizedStringForKey:@"UnMuteGameMenuItemTitle"
                            value:nil table:nil];
    else
        muteMenuItem.title = [[NSBundle mainBundle]
                            localizedStringForKey:@"MuteGameMenuItemTitle"
                            value:nil table:nil];
    
}

- (IBAction)orderFrontAboutPanel:(id)sender
{
    //NSLog(@"GameController showAboutPanel called");
    NSArray *top = nil;
    if (!aboutPanel)
        [NSBundle.mainBundle loadNibNamed:@"About" owner:self topLevelObjects:&top];
    [aboutPanel setFrameAutosaveName:@"aboutPanel"];
    [aboutPanel makeKeyAndOrderFront:self];
}

- (IBAction)orderFrontPreferencesPanel:(id)sender
{
    NSArray *top = nil;
    if (!prefsPanel)
        [NSBundle.mainBundle loadNibNamed:@"Preferences" owner:self topLevelObjects:&top];
    prefsStandardGraphicsButton.state = !useAlternateGraphics;
    prefsAlternateGraphicsButton.state = useAlternateGraphics;

    prefsCustomBackgroundCheckbox.state = useCustomBackgrounds;
    prefsCustomBackgroundFolderTextField.stringValue = customBackgroundFolderPath;
    prefsSelectFolderButton.enabled = prefsCustomBackgroundCheckbox.state;
    prefsCustomBackgroundFolderTextField.enabled = prefsCustomBackgroundCheckbox.state;
    
    if ([[NSUserDefaults standardUserDefaults]	dataForKey:@"tiffGemImage0"])
    {    // set up images!
        int i = 0;
        for (i = 0; i < 7; i++)
        {
            NSString	*key = [NSString stringWithFormat:@"tiffGemImage%d", i];
            NSData	*tiffData = [[NSUserDefaults standardUserDefaults]	dataForKey:key];
            NSImage 	*gemImage = [[NSImage alloc] initWithData:tiffData];
            if (i == 0)	iv1.image = gemImage;
            if (i == 1)	iv2.image = gemImage;
            if (i == 2)	iv3.image = gemImage;
            if (i == 3)	iv4.image = gemImage;
            if (i == 4)	iv5.image = gemImage;
            if (i == 5)	iv6.image = gemImage;
            if (i == 6)	iv7.image = gemImage;
        }
    }
    
    [prefsPanel setFrameAutosaveName:@"prefsPanel"];
    [prefsPanel makeKeyAndOrderFront:self];
}

- (IBAction)showHighScores:(id)sender
{
    // rotate which scores to show
    //
    NSArray *gameNames = highScores[gameLevel*2];
    NSArray *gameScores = highScores[gameLevel*2+1];
    if (gameLevel==0)
    [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"EasyHighScoresHTML"
                                            value:nil table:nil]];
    else if (gameLevel==1)
    [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"HardHighScoresHTML"
                                            value:nil table:nil]];
    else if (gameLevel==2)
    [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"ToughHighScoresHTML"
                                            value:nil table:nil]];
    else if (gameLevel==3)
    [gameView setHTMLHiScoreLegend:[[NSBundle mainBundle]
                                            localizedStringForKey:@"FreePlayHighScoresHTML"
                                            value:nil table:nil]];
    gameLevel = (gameLevel +1)%4;
    
    [gameView showHighScores:gameScores andNames:gameNames];
    [gameView setLastMoveDate];	//reset timer so scores show for 20s    
}

- (IBAction)resetHighScores:(id)sender
{
    // don't rotate which scores to show
    //
    // blank the hi scores
    //
    [self setHighScores:[self makeBlankHiScoresWith:nil]];
    [[NSUserDefaults standardUserDefaults] setObject:highScores forKey:@"highScores"];
    
    [self showHighScores:sender];	//call the show scores routine    
}

- (NSArray *)makeBlankHiScoresWith:(NSArray *)oldScores
{
    //int i,j;
    int j;
    NSMutableArray	*result = [NSMutableArray arrayWithCapacity:0];
    
    if (oldScores)	result = [NSMutableArray arrayWithArray:oldScores];
    
    //for (i = 0; i < 3; i++)
    while (result.count < 8)
    {
        NSMutableArray	*scores = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray	*names = [NSMutableArray arrayWithCapacity:0];
        for (j = 0; j < 10; j++)
        {
            [scores addObject:@100];
            [names addObject:[[NSBundle mainBundle]
                                localizedStringForKey:@"AnonymousName"
                                value:nil table:nil]];
        }
        [result addObject:names];
        [result addObject:scores];
    }
    return result;
}

- (void)setHighScores:(NSArray *)oldScores {
  highScores = [oldScores mutableCopy];
}


- (void)runOutOfTime
{
    gameState = GAMESTATE_GAMEOVER;
    [abortGameButton setEnabled:NO];
    [pauseGameButton setEnabled:NO];
    abortGame = YES;
    [gameView setHTMLLegend:gameOverString];
    [game shake];
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf waitForFirstClick]; }];
}

- (void)checkHiScores
{
    int i;
    // reset arrays with gameLevel
    NSArray *gameNames = highScores[gameLevel*2];
    NSArray *gameScores = highScores[gameLevel*2+1];
    for (i = 0; i < 10; i++)
    {
        if ([game score] > [gameScores[i] intValue])
        {
            hiScorePanelScoreTextField.stringValue = [NSString stringWithFormat:@"%d",[game score]];
            [gameWindow beginSheet:hiScorePanel completionHandler:nil];
            return;
        }
    }
    [gameView showHighScores:gameScores andNames:gameNames];
}

- (void)bonusAwarded
{

    [gameView newBackground];

    if (!muted)		[[NSSound soundNamed:@"yes"] play];

    if (!freePlay) {		// FREEPLAY MW
        [game increaseBonusMultiplier];
        [timerView decrementMeter:0.5];
    } else {
        [game increaseBonusMultiplier];
        [timerView decrementMeter:1];
    }

    if (gameSpeed < SPEED_LIMIT)		// capping speed limit
        gameSpeed = gameSpeed * 1.5;
    //NSLog(@"...gamesSpeed %f",gameSpeed);
    __weak typeof(self) weakSelf = self;
    [timerView setTimerRunningEvery:0.5/gameSpeed
                decrement:(0.5/gameTime)
                whenRunOut:^{ [weakSelf runOutOfTime];}
                whenRunOver:^{ [weakSelf bonusAwarded];}];
                
    if (freePlay)	[timerView setDecrement:0];//	FREEPLAY
}

- (void)startAnimation:(Block)andThenSelector;
{
    [animationTimerLock lock];
    //
    if (!timer)
        timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                  target:gameView
                                                selector:@selector(animate)
                                                userInfo:self
                                                 repeats:YES];
    //
    whatNext = andThenSelector;
    //
    [gameView setAnimating:YES];
    //
    [animationTimerLock unlock];
}

- (void)animationEnded
{
    //NSLog(@"gameController.animationEnded messaged");
    
    [animationTimerLock lock];
    //
    [gameView setAnimating:NO];
    //
    [animationTimerLock unlock];
    
    if (whatNext)whatNext();
        
    [gameView setNeedsDisplay:YES];
}

- (void)waitForNewGame
{
    [self checkHiScores];
    
    [game wholeNewGameWithSpritesFrom:[gameView spriteArray]];
    [gameView setLegend:titleImage];
    [easyGameButton setEnabled:YES];
    [hardGameButton setEnabled:YES];
    [toughGameButton setEnabled:YES];
    [abortGameButton setEnabled:NO];
    [pauseGameButton setEnabled:NO];
}

- (void)newBoard1
{
    //NSLog(@"newBoard1");
    [game erupt];
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf newBoard2]; }];
}

- (void)newBoard2
{
    Gem *gem;
    int i,j,r;
    //NSLog(@"newBoard2");
    for (i = 0; i < 8; i++)
    {
        for (j = 0; j < 8; j++)
        {
            gem = [game gemAt:i:j];
            //NSLog(@"..gem..%@",gem);
            r = arc4random_uniform(7);
            [gem setGemType:r];
            //[gem setImage:[[gameView imageArray] objectAtIndex:r]];
            [gem setSprite:[gameView spriteArray][r]];
            [gem setPositionOnBoard:i:j];
            [gem setPositionOnScreen:i*48:(i+j+8)*48];
            [gem fall];
        }
    }
    [gameView newBackground];
    [gameView setLegend:nil];
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf testForThreesAgain]; }];
}

- (void)waitForFirstClick
{
    //NSLog(@"waitForFirstClick");
    /*- if (!freePlay)  MW CHANGE -*/	[timerView setPaused:NO];
    __weak typeof(self) weakSelf = self;
    if (abortGame)
    {
        [timerView setTimer:0.5];
        gameState = GAMESTATE_GAMEOVER;
        [game explodeGameOver];
        [self startAnimation:^{ [weakSelf waitForNewGame]; }];
        return;
    }
    if (![game boardHasMoves])
    {
        [timerView setPaused:YES];
        [gameView setHTMLLegend:noMoreMovesString];
        [game shake];
        
        if (freePlay)	[self startAnimation:^{ [weakSelf runOutOfTime]; }];//	FREEPLAY
        else		[self startAnimation:^{ [weakSelf newBoard1]; }];//	FREEPLAY
        
        return;
    }
    gameState = GAMESTATE_AWAITINGFIRSTCLICK;
}

- (void)receiveClickAt:(int)x :(int)y
{
    if (paused)	return;
    if ((x < 0)||(x > 383)||(y < 0)||(y > 383))	return;
    if (gameState == GAMESTATE_AWAITINGFIRSTCLICK)
    {
        chx1 = floor(x / 48);
        chy1 = floor(y / 48);
        gameState = GAMESTATE_AWAITINGSECONDCLICK;
        [gameView setNeedsDisplay:YES];
        return;
    }
    if (gameState == GAMESTATE_AWAITINGSECONDCLICK)
    {
        chx2 = floor(x / 48);
        chy2 = floor(y / 48);
        if ((chx2 != chx1)^(chy2 != chy1))	// xor!
        {
            int d = (chx1-chx2)*(chx1-chx2)+(chy1-chy2)*(chy1-chy2);
            //NSLog(@"square distance ==%d",d);
            if (d==1)
            {
                gameState = GAMESTATE_FRACULATING;
                [gameView setNeedsDisplay:YES];
                [gameView setLastMoveDate];
                /*- MW CHANGE if (!freePlay) -*/ [timerView setPaused:YES];
                [self tryMoveSwapping:chx1:chy1 and:chx2:chy2];
                return;
            }
        }
        // fall out of routine setting first click location
        chx1 = floor(x / 48);
        chy1 = floor(y / 48);
        gameState = GAMESTATE_AWAITINGSECONDCLICK;
        [gameView setNeedsDisplay:YES];
    }
}


- (void)tryMoveSwapping:(int)x1 :(int)y1 and:(int)x2 :(int)y2
{
    // do stuff here!!!
    int xx1, yy1, xx2, yy2;
    //NSLog(@"tryMoveSwapping");
    if (x1 != x2)
    {
        if (x1 < x2)	{ xx1 = x1; xx2 = x2; }
        else		{ xx1 = x2; xx2 = x1; }
        yy1 = y1;
        yy2 = y2;
    }
    else
    {
        if (y1 < y2)	{ yy1 = y1; yy2 = y2; }
        else		{ yy1 = y2; yy2 = y1; }
        xx1 = x1;
        xx2 = x2;
    }
    // store swap positions
    chx1 = xx1; chy1 = yy1; chx2 = xx2; chy2 = yy2;
    // swap positions
    if (chx1 < chx2)	// swapping horizontally
    {
        [[game gemAt:chx1:chy1] setVelocity:gemMoveSpeed:0:gemMoveSteps];
        [[game gemAt:chx2:chy2] setVelocity:-gemMoveSpeed:0:gemMoveSteps];
    }
    else		// swapping vertically
    {
        [[game gemAt:chx1:chy1] setVelocity:0:gemMoveSpeed:gemMoveSteps];
        [[game gemAt:chx2:chy2] setVelocity:0:-gemMoveSpeed:gemMoveSteps];
    }
    [game swap:chx1:chy1 and:chx2:chy2];
    gameState = GAMESTATE_SWAPPING;
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf testForThrees]; }];
}

    // test for threes
- (void)testForThrees
{
    BOOL anyThrees;
    int oldScore = [game score];
    //NSLog(@"testForThrees");
    anyThrees = ([game testForThreeAt:chx1:chy1])|([game testForThreeAt:chx2:chy2]);
    scoreTextField.stringValue = [NSString stringWithFormat:@"%d",[game score]];
    [scoreTextField setNeedsDisplay:YES];
    bonusTextField.stringValue = [NSString stringWithFormat:@"x%d",[game bonusMultiplier]];
    [bonusTextField setNeedsDisplay:YES];
    if ([game score] > oldScore) [timerView incrementMeter:[game collectGemsFaded]/GEMS_FOR_BONUS];
    if (anyThrees) {
        __weak typeof(self) weakSelf = self;
        [self startAnimation:^{ [weakSelf removeThreesAndReplaceGems];}];	// fade gems
    } else {
        [self unSwap];
    }
}    

    //// repeat:	remove threes
- (void)removeThreesAndReplaceGems
{
    
    //NSLog(@"removeThreesAndReplaceGems");
    // deal with fading
    [game removeFadedGemsAndReorganiseWithSpritesFrom:[gameView spriteArray]];
    
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf testForThreesAgain];}];	// gems fall down
}    

- (void)testForThreesAgain
{
    BOOL anyThrees;
    int oldScore = [game score];
    //NSLog(@"testForThreesAgain");
    anyThrees = [game checkBoardForThrees];
    scoreTextField.stringValue = [NSString stringWithFormat:@"%d",[game score]];
    [scoreTextField setNeedsDisplay:YES];
    bonusTextField.stringValue = [NSString stringWithFormat:@"x%d",[game bonusMultiplier]];
    [bonusTextField setNeedsDisplay:YES];
    if ([game score] > oldScore) [timerView incrementMeter:[game collectGemsFaded]/GEMS_FOR_BONUS];
    if (anyThrees) {
        __weak typeof(self) weakSelf = self;
        [self startAnimation:^{ [weakSelf removeThreesAndReplaceGems]; }];	// fade gems
    } else {
        [self waitForFirstClick];
    }
}   
    //// 		allow gems to fall
    //// 		test for threes
    //// until there are no threes

- (void)unSwap
{
    //NSLog(@"unSwap");
    
    if (!muted)	[[NSSound soundNamed:@"no"] play];
    
    // swap positions
    if (chx1 < chx2)	// swapping horizontally
    {
        [[game gemAt:chx1:chy1] setVelocity:4:0:12];
        [[game gemAt:chx2:chy2] setVelocity:-4:0:12];
    }
    else		// swapping vertically
    {
        [[game gemAt:chx1:chy1] setVelocity:0:4:12];
        [[game gemAt:chx2:chy2] setVelocity:0:-4:12];
    }
    [game swap:chx1:chy1 and:chx2:chy2];
    gameState = GAMESTATE_SWAPPING;
    __weak typeof(self) weakSelf = self;
    [self startAnimation:^{ [weakSelf waitForFirstClick];}];
}    


- (int) gameState
{
    return gameState;
}

- (BOOL) gameIsPaused
{
    return paused;
}

- (BOOL) useCustomBackgrounds
{
    return useCustomBackgrounds;
}

- (NSPoint) crossHair1Position
{
    return NSMakePoint(chx1*48,chy1*48);
}

- (NSPoint) crossHair2Position
{
    return NSMakePoint(chx2*48,chy2*48);
}

@end
