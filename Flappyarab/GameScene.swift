//
//  GameScene.swift
//  Flappyarabia
//
//  Created by AdnanTech on 11/20/15.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

//

import SpriteKit


enum Layer: CGFloat {
    case Background
    case Obstacle
    case Foreground
    case Player
    case UI
    case Flash
}

enum GameState {
    case MainMenu
    case Tutorial
    case Play
    case Falling
    case ShowingScore
    case GameOver
}

struct PhysicsCategory {
    static let None: UInt32 = 0
    static let Player: UInt32 =     0b1 // 1
    static let Obstacle: UInt32 =  0b10 // 2
    static let Ground: UInt32 =   0b100 // 4
}

protocol GameSceneDelegate {
    
    func screenshot() -> UIImage
    func shareString(string: String, url: NSURL, image: UIImage)
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let kGravity: CGFloat = -1500.0
    let kImpulse: CGFloat = 400.0
    let kNumForegrounds = 2
    let kGroundSpeed: CGFloat = 150.0
    let kBottomObstacleMinFraction: CGFloat = 0.1
    let kBottomObstacleMaxFraction: CGFloat = 0.6
    let kGapMultiplier: CGFloat = 3.5
    let kFirstSpawnDelay: TimeInterval = 1.75
    let kEverySpawnDelay: TimeInterval = 1.5
    let kFontName = "AmericanTypewriter-Bold"
    let kMargin: CGFloat = 20.0
    let kAnimDelay = 0.3
    let kAppStoreID = 1061737650
    let kNumBirdFrames = 4
    let kMinDegrees: CGFloat = -90
    let kMaxDegrees: CGFloat = 25
    let kAngularVelocity: CGFloat = 1000.0
    
    let worldNode = SKNode()
    var playableStart: CGFloat = 0
    var playableHeight: CGFloat = 0
    let player = SKSpriteNode(imageNamed: "Bird0")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    var playerVelocity = CGPoint.zero
    var hitGround = false
    var hitObstacle = false
    var gameState: GameState = .Play
    var scoreLabel: SKLabelNode!
    var score = 0
    var gameSceneDelegate: GameSceneDelegate
    var playerAngularVelocity: CGFloat = 0.0
    var lastTouchTime: TimeInterval = 0
    var lastTouchY: CGFloat = 0.0
    
    let dingAction = SKAction.playSoundFileNamed("ding.wav", waitForCompletion: false)
    let flapAction = SKAction.playSoundFileNamed("flapping.wav", waitForCompletion: false)
    let whackAction = SKAction.playSoundFileNamed("whack.wav", waitForCompletion: false)
    let fallingAction = SKAction.playSoundFileNamed("falling.wav", waitForCompletion: false)
    let hitGroundAction = SKAction.playSoundFileNamed("hitGround.wav", waitForCompletion: false)
    let popAction = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
    let coinAction = SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false)
    
    init(size: CGSize, delegate:GameSceneDelegate, gameState: GameState) {
        self.gameSceneDelegate = delegate
        self.gameState = gameState
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        addChild(worldNode)
        
        if gameState == .MainMenu {
            switchToMainMenu()
        } else {
            switchToTutorial()
        }
        
    }
    
    // MARK: Setup methods
    
    func setupBackground() {
        
        let background = SKSpriteNode(imageNamed: "Background")
        background.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        background.position = CGPoint(x: size.width/2, y: size.height)
        background.zPosition = Layer.Background.rawValue
        worldNode.addChild(background)
        
        playableStart = size.height - background.size.height
        playableHeight = background.size.height
        
        let lowerLeft = CGPoint(x: 0, y: playableStart)
        let lowerRight = CGPoint(x: size.width, y: playableStart)
        
        self.physicsBody = SKPhysicsBody(edgeFrom: lowerLeft, to: lowerRight)
        self.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        self.physicsBody?.collisionBitMask = 0
        self.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
    }
    
    func setupForeground() {
        
        for i in 0..<kNumForegrounds {
            let foreground = SKSpriteNode(imageNamed: "Ground")
            foreground.anchorPoint = CGPoint(x: 0, y: 1)
            foreground.position = CGPoint(x: CGFloat(i) * size.width, y: playableStart)
            foreground.zPosition = Layer.Foreground.rawValue
            foreground.name = "foreground"
            worldNode.addChild(foreground)
        }
        
    }
    
    func setupPlayer() {
        
        player.position = CGPoint(x: size.width * 0.2, y: playableHeight * 0.4 + playableStart)
        player.zPosition = Layer.Player.rawValue
        
        let offsetX = player.size.width * player.anchorPoint.x
        let offsetY = player.size.height * player.anchorPoint.y
        
        let path = CGMutablePath()
        
        
        path.move(to: CGPoint(x:  22 - offsetX, y: 29 - offsetY))
        path.addLine(to: CGPoint(x:  28 - offsetX, y: 29 - offsetY))
        path.move(to: CGPoint(x:  29 - offsetX, y: 28 - offsetY))
        path.move(to: CGPoint(x:  32 - offsetX, y: 25 - offsetY))
        path.move(to: CGPoint(x:  37 - offsetX, y: 12 - offsetY))
        path.move(to: CGPoint(x:  37 - offsetX, y: 9 - offsetY))
        path.move(to: CGPoint(x:  35 - offsetX, y: 7 - offsetY))
        path.move(to: CGPoint(x:  25 - offsetX, y: 4 - offsetY))
        path.move(to: CGPoint(x:  22 - offsetX, y: 3 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX, y: 2 - offsetY))
        path.move(to: CGPoint(x:  2 - offsetX, y: 13 - offsetY))
        path.move(to: CGPoint(x:  2 - offsetX, y: 17 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX, y: 19 - offsetY))
        path.move(to: CGPoint(x:  12 - offsetX, y: 25 - offsetY))
        
        path.closeSubpath()
        
        player.physicsBody = SKPhysicsBody(polygonFrom: path)
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Obstacle | PhysicsCategory.Ground
        
        worldNode.addChild(player)
        
        let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 0.4)
        moveUp.timingMode = .easeInEaseOut
        let moveDown = moveUp.reversed()
        let sequence = SKAction.sequence([moveUp, moveDown])
        let `repeat` = SKAction.repeatForever(sequence)
        player.run(`repeat`, withKey: "Wobble")
        
    }
    
    
    
    func setupLabel() {
        
        scoreLabel = SKLabelNode(fontNamed: kFontName)
        scoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height - kMargin)
        scoreLabel.text = "0"
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.zPosition = Layer.UI.rawValue
        worldNode.addChild(scoreLabel)
        
    }
    
    func setupScorecard() {
        
        if score > bestScore() {
            setBestScore(bestScore: score)
        }
        
        let scorecard = SKSpriteNode(imageNamed: "ScoreCard")
        scorecard.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        scorecard.name = "Tutorial"
        scorecard.zPosition = Layer.UI.rawValue
        worldNode.addChild(scorecard)
        
        let lastScore = SKLabelNode(fontNamed: kFontName)
        lastScore.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        lastScore.position = CGPoint(x: -scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        lastScore.text = "\(score)"
        scorecard.addChild(lastScore)
        
        let bestScoreLabel = SKLabelNode(fontNamed: kFontName)
        bestScoreLabel.fontColor = SKColor(red: 101.0/255.0, green: 71.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        bestScoreLabel.position = CGPoint(x: scorecard.size.width * 0.25, y: -scorecard.size.height * 0.2)
        bestScoreLabel.text = "\(self.bestScore())"
        scorecard.addChild(bestScoreLabel)
        
        let gameOver = SKSpriteNode(imageNamed: "GameOver")
        gameOver.position = CGPoint(x: size.width/2, y: size.height/2 + scorecard.size.height/2 + kMargin + gameOver.size.height/2)
        gameOver.zPosition = Layer.UI.rawValue
        worldNode.addChild(gameOver)
        
        let okButton = SKSpriteNode(imageNamed: "Button")
        okButton.position = CGPoint(x: size.width * 0.25, y: size.height/2 - scorecard.size.height/2 - kMargin - okButton.size.height/2)
        okButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(okButton)
        
        let ok = SKSpriteNode(imageNamed: "OK")
        ok.position = CGPoint.zero
        ok.zPosition = Layer.UI.rawValue
        okButton.addChild(ok)
        
        let shareButton = SKSpriteNode(imageNamed: "Button")
        shareButton.position = CGPoint(x: size.width * 0.75, y: size.height/2 - scorecard.size.height/2 - kMargin - shareButton.size.height/2)
        shareButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(shareButton)
        
        let share = SKSpriteNode(imageNamed: "Share")
        share.position = CGPoint.zero
        share.zPosition = Layer.UI.rawValue
        shareButton.addChild(share)
        
        gameOver.setScale(0)
        gameOver.alpha = 0
        let group = SKAction.group([
            SKAction.fadeIn(withDuration: kAnimDelay),
            SKAction.scale(to: 1.0, duration: kAnimDelay)
            ])
        group.timingMode = .easeInEaseOut
        gameOver.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay),
            group
            ]))
        
        scorecard.position = CGPoint(x: size.width * 0.5, y: -scorecard.size.height/2)
        let moveTo = SKAction.move(to: CGPoint(x: size.width/2, y: size.height/2), duration: kAnimDelay)
        moveTo.timingMode = .easeInEaseOut
        scorecard.run(SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay * 2),
            moveTo
            ]))
        
        okButton.alpha = 0
        shareButton.alpha = 0
        let fadeIn = SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay * 3),
            SKAction.fadeIn(withDuration: kAnimDelay)
            ])
        okButton.run(fadeIn)
        shareButton.run(fadeIn)
        
        let pops = SKAction.sequence([
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.wait(forDuration: kAnimDelay),
            popAction,
            SKAction.run(switchToGameOver)
            ])
        run(pops)
        
    }
    
    func setupTutorial() {
        
        let tutorial = SKSpriteNode(imageNamed: "Tutorial")
        tutorial.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.4 + playableStart)
        tutorial.name = "Tutorial"
        tutorial.zPosition = Layer.UI.rawValue
        worldNode.addChild(tutorial)
        
        let ready = SKSpriteNode(imageNamed: "Ready")
        ready.position = CGPoint(x: size.width * 0.5, y: playableHeight * 0.7 + playableStart)
        ready.name = "Tutorial"
        ready.zPosition = Layer.UI.rawValue
        worldNode.addChild(ready)
        
    }
    
    func setupMainMenu() {
        
        let logo = SKSpriteNode(imageNamed: "Logo")
        logo.position = CGPoint(x: size.width/2, y: size.height * 0.8)
        logo.zPosition = Layer.UI.rawValue
        worldNode.addChild(logo)
        
        // Play button
        let playButton = SKSpriteNode(imageNamed: "Button")
        playButton.position = CGPoint(x: size.width * 0.25, y: size.height * 0.25)
        playButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(playButton)
        
        let play = SKSpriteNode(imageNamed: "Play")
        play.position = CGPoint.zero
        playButton.addChild(play)
        
        // Rate button
        let rateButton = SKSpriteNode(imageNamed: "Button")
        rateButton.position = CGPoint(x: size.width * 0.75, y: size.height * 0.25)
        rateButton.zPosition = Layer.UI.rawValue
        worldNode.addChild(rateButton)
        
        let rate = SKSpriteNode(imageNamed: "Rate")
        rate.position = CGPoint.zero
        rateButton.addChild(rate)
        
        // Learn button
        let learn = SKSpriteNode(imageNamed: "button_learn")
        learn.position = CGPoint(x: size.width * 0.5, y: learn.size.height/2 + kMargin)
        learn.zPosition = Layer.UI.rawValue
        worldNode.addChild(learn)
        
        // Bounce button
        let scaleUp = SKAction.scale(to: 1.02, duration: 0.75)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 0.98, duration: 0.75)
        scaleDown.timingMode = .easeInEaseOut
        
        learn.run(SKAction.repeatForever(SKAction.sequence([
            scaleUp, scaleDown
            ])))
        
        // learn.removeAllActions() // DONLY
        
    }
    
    func setupPlayerAnimation() {
        
        var textures: Array<SKTexture> = []
        for i in 0..<kNumBirdFrames {
            textures.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        
        for i in stride(from: kNumBirdFrames-1, to: 0, by: -1) {
            textures.append(SKTexture(imageNamed: "Bird\(i)"))
        }
        
        let playerAnimation = SKAction.animate(with: textures, timePerFrame: 0.07)
        player.run(SKAction.repeatForever(playerAnimation))
        
    }
    
    // MARK: Gameplay
    
    func createObstacle() -> SKSpriteNode {
        let sprite = SKSpriteNode(imageNamed: "Cactus")
        sprite.zPosition = Layer.Obstacle.rawValue
        
        sprite.userData = NSMutableDictionary()
        
        let offsetX = sprite.size.width * sprite.anchorPoint.x
        let offsetY = sprite.size.height * sprite.anchorPoint.y
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x:  37 - offsetX, y: 80 - offsetY))
        path.move(to: CGPoint(x: 25 - offsetX, y: 180 - offsetY))
        
        
        path.move(to: CGPoint(x: 25 - offsetX, y: 180 - offsetY))
        path.move(to: CGPoint(x:  25 - offsetX, y: 180 - offsetY))
        path.move(to: CGPoint(x:  8 - offsetX, y: 273 - offsetY))
        path.move(to: CGPoint(x: 28 - offsetX, y: 280 - offsetY))
        path.move(to: CGPoint(x: 52 - offsetX, y: 312 - offsetY))
        path.move(to: CGPoint(x: 52 - offsetX, y: 312 - offsetY))
        path.move(to: CGPoint(x: 52 - offsetX, y: 312 - offsetY))
        
        
        
        path.move(to: CGPoint(x: 53 - offsetX, y: 315 - offsetY))
        path.move(to: CGPoint(x: 53 - offsetX, y: 315 - offsetY))
        path.move(to: CGPoint(x: 53 - offsetX, y: 315 - offsetY))
        path.move(to: CGPoint(x: 30 - offsetX, y: 315 - offsetY))
        
        path.move(to: CGPoint(x: 8 - offsetX, y: 311 - offsetY))
        
        
        
        path.move(to: CGPoint(x: 3 - offsetX, y: 313 - offsetY))
        
        path.move(to: CGPoint(x: 3 - offsetX, y: 311 - offsetY))
        
        path.move(to: CGPoint(x: 1 - offsetX, y: 307 - offsetY))
        
        
        path.move(to: CGPoint(x: 1 - offsetX, y: 312 - offsetY))
        
        
        path.move(to: CGPoint(x: 21 - offsetX, y: 281 - offsetY))
        
        path.move(to: CGPoint(x: 36 - offsetX, y: 264 - offsetY))
        path.move(to: CGPoint(x: 50 - offsetX, y: 244 - offsetY))
        
        path.move(to: CGPoint(x: 5 - offsetX, y: 218 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX, y: 204 - offsetY))
        path.move(to: CGPoint(x: -1 - offsetX, y: 204 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX, y: 156 - offsetY))
        
        path.move(to: CGPoint(x: 9 - offsetX, y: 126 - offsetY))
        
        path.move(to: CGPoint(x:  9 - offsetX,  y:126 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:126 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:126 - offsetY))
        path.move(to: CGPoint(x:  46 - offsetX, y: 172 - offsetY))
        path.move(to: CGPoint(x:  46 - offsetX, y: 172 - offsetY))
        path.move(to: CGPoint(x:  40 - offsetX, y: 212 - offsetY))
        path.move(to: CGPoint(x:  29 - offsetX, y: 203 - offsetY))
        path.move(to: CGPoint(x:  28 - offsetX, y: 228 - offsetY))
        path.move(to: CGPoint(x:  29 - offsetX, y: 292 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:311 - offsetY))
        path.move(to: CGPoint(x:  35 - offsetX, y: 75 - offsetY))
        path.move(to: CGPoint(x:  15 - offsetX, y: 88 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX,  y:93 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX,  y:108 - offsetY))
        path.move(to: CGPoint(x:  12 - offsetX, y: 108 - offsetY))
        path.move(to: CGPoint(x:  20 - offsetX, y: 128 - offsetY))
        path.move(to: CGPoint(x:  22 - offsetX, y: 138 - offsetY))
        path.move(to: CGPoint(x:  26 - offsetX, y: 146 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 152 - offsetY))
        path.move(to: CGPoint(x:  51 - offsetX, y: 171 - offsetY))
        path.move(to: CGPoint(x:  8 - offsetX,  y:140 - offsetY))
        path.move(to: CGPoint(x:  34 - offsetX, y: 126 - offsetY))
        path.move(to: CGPoint(x:  44 - offsetX, y: 127 - offsetY))
        path.move(to: CGPoint(x:  52 - offsetX, y: 126 - offsetY))
        path.move(to: CGPoint(x:  52 - offsetX, y: 141 - offsetY))
        path.move(to: CGPoint(x:  43 - offsetX, y: 141 - offsetY))
        path.move(to: CGPoint(x:  39 - offsetX, y: 141 - offsetY))
        path.move(to: CGPoint(x:  25 - offsetX, y: 141 - offsetY))
        path.move(to: CGPoint(x:  42 - offsetX, y: 88 - offsetY))
        path.move(to: CGPoint(x:  49 - offsetX, y: 78 - offsetY))
        path.move(to: CGPoint(x:  14 - offsetX, y: 60 - offsetY))
        path.move(to: CGPoint(x:  6 - offsetX,  y:50 - offsetY))
        path.move(to: CGPoint(x:  11 - offsetX, y: 28 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 28 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 28 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 10 - offsetY))
        path.move(to: CGPoint(x:  34 - offsetX, y: 10 - offsetY))
        path.move(to: CGPoint(x:  8 - offsetX,  y:10 - offsetY))
        path.move(to: CGPoint(x:  8 - offsetX,  y:10 - offsetY))
        path.move(to: CGPoint(x:  5 - offsetX,  y:21 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:5 - offsetY))
        path.move(to: CGPoint(x:  33 - offsetX, y: 5 - offsetY))
        path.move(to: CGPoint(x:  45 - offsetX, y: 5 - offsetY))
        path.move(to: CGPoint(x:  45 - offsetX, y: 45 - offsetY))
        path.move(to: CGPoint(x:  48 - offsetX, y: 45 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 45 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 45 - offsetY))
        path.move(to: CGPoint(x:  51 - offsetX, y: 46 - offsetY))
        path.move(to: CGPoint(x:  51 - offsetX, y: 46 - offsetY))
        path.move(to: CGPoint(x:  52 - offsetX, y: 47 - offsetY))
        path.move(to: CGPoint(x:  15 - offsetX, y: 257 - offsetY))
        path.move(to: CGPoint(x:  40 - offsetX, y: 261 - offsetY))
        path.move(to: CGPoint(x:  44 - offsetX, y: 269 - offsetY))
        path.move(to: CGPoint(x:  47 - offsetX, y: 271 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 280 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 280 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 280 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 280 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 294 - offsetY))
        path.move(to: CGPoint(x:  0 - offsetX,  y:291 - offsetY))
        path.move(to: CGPoint(x:  0 - offsetX,  y:291 - offsetY))
        path.move(to: CGPoint(x:  1 - offsetX,  y:302 - offsetY))
        path.move(to: CGPoint(x:  2 - offsetX,  y:267 - offsetY))
        path.move(to: CGPoint(x:  27 - offsetX, y: 244 - offsetY))
        path.move(to: CGPoint(x:  4 - offsetX,  y:240 - offsetY))
        path.move(to: CGPoint(x:  51 - offsetX, y: 225 - offsetY))
        path.move(to: CGPoint(x:  20 - offsetX, y: 214 - offsetY))
        path.move(to: CGPoint(x:  5 - offsetX,  y:228 - offsetY))
        path.move(to: CGPoint(x:  11 - offsetX, y: 233 - offsetY))
        path.move(to: CGPoint(x:  8 - offsetX,  y:240 - offsetY))
        path.move(to: CGPoint(x:  35 - offsetX, y: 224 - offsetY))
        path.move(to: CGPoint(x:  1 - offsetX,  y:163 - offsetY))
        path.move(to: CGPoint(x:  7 - offsetX,  y:126 - offsetY))
        path.move(to: CGPoint(x:  2 - offsetX,  y:126 - offsetY))
        path.move(to: CGPoint(x:  6 - offsetX,  y:81 - offsetY))
        path.move(to: CGPoint(x:  24 - offsetX, y: 102 - offsetY))
        path.move(to: CGPoint(x:  26 - offsetX, y: 123 - offsetY))
        path.move(to: CGPoint(x:  26 - offsetX, y: 123 - offsetY))
        path.move(to: CGPoint(x:  19 - offsetX, y: 122 - offsetY))
        path.move(to: CGPoint(x:  19 - offsetX, y: 122 - offsetY))
        path.move(to: CGPoint(x:  21 - offsetX, y: 93 - offsetY))
        path.move(to: CGPoint(x:  16 - offsetX, y: 61 - offsetY))
        path.move(to: CGPoint(x:  14 - offsetX, y: 21 - offsetY))
        path.move(to: CGPoint(x:  11 - offsetX, y: 94 - offsetY))
        path.move(to: CGPoint(x:  18 - offsetX, y: 109 - offsetY))
        path.move(to: CGPoint(x:  31 - offsetX, y: 108 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 259 - offsetY))
        path.move(to: CGPoint(x:  7 - offsetX,  y:258 - offsetY))
        path.move(to: CGPoint(x:  5 - offsetX,  y:255 - offsetY))
        path.move(to: CGPoint(x:  34 - offsetX, y: 249 - offsetY))
        path.move(to: CGPoint(x:  1 - offsetX,  y:314 - offsetY))
        path.move(to: CGPoint(x:  1 - offsetX,  y:314 - offsetY))
        path.move(to: CGPoint(x:  52 - offsetX, y: 243 - offsetY))
        path.move(to: CGPoint(x:  6 - offsetX,  y:311 - offsetY))
        path.move(to: CGPoint(x:  1 - offsetX,  y:311 - offsetY))
        path.move(to: CGPoint(x:  50 - offsetX, y: 292 - offsetY))
        path.move(to: CGPoint(x:  11 - offsetX, y: 289 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:311 - offsetY))
        path.move(to: CGPoint(x:  4 - offsetX,  y:310 - offsetY))
        path.move(to: CGPoint(x:  41 - offsetX, y: 297 - offsetY))
        path.move(to: CGPoint(x:  26 - offsetX, y: 259 - offsetY))
        path.move(to: CGPoint(x:  15 - offsetX, y: 307 - offsetY))
        path.move(to: CGPoint(x:  11 - offsetX, y: 303 - offsetY))
        path.move(to: CGPoint(x:  21 - offsetX, y: 301 - offsetY))
        path.move(to: CGPoint(x:  12 - offsetX, y: 307 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX,  y:314 - offsetY))
        path.move(to: CGPoint(x:  4 - offsetX,  y:314 - offsetY))
        path.move(to: CGPoint(x:  3 - offsetX,  y:298 - offsetY))
        path.move(to: CGPoint(x:  51 - offsetX, y: 301 - offsetY))
        path.move(to: CGPoint(x:  9 - offsetX,  y:313 - offsetY))
        path.move(to: CGPoint(x:  33 - offsetX, y: 248 - offsetY))
        path.move(to: CGPoint(x:  19 - offsetX, y: 237 - offsetY))
        path.move(to: CGPoint(x:  12 - offsetX, y: 297 - offsetY))
        
        
        path.closeSubpath()
        
        sprite.physicsBody = SKPhysicsBody(polygonFrom: path)
        sprite.physicsBody?.categoryBitMask = PhysicsCategory.Obstacle
        sprite.physicsBody?.collisionBitMask = 0
        sprite.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        
        return sprite
    }
    
    func spawnObstacle() {
        
        let bottomObstacle = createObstacle()
        let startX = size.width + bottomObstacle.size.width/2
        
        let bottomObstacleMin = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMinFraction
        let bottomObstacleMax = (playableStart - bottomObstacle.size.height/2) + playableHeight * kBottomObstacleMaxFraction
        bottomObstacle.position = CGPointMake(startX, CGFloat.random(min: bottomObstacleMin, max: bottomObstacleMax))
        bottomObstacle.name = "BottomObstacle"
        worldNode.addChild(bottomObstacle)
        
        let topObstacle = createObstacle()
        topObstacle.zRotation = CGFloat(180).degreesToRadians()
        topObstacle.position = CGPoint(x: startX, y: bottomObstacle.position.y + bottomObstacle.size.height/2 + topObstacle.size.height/2 + player.size.height * kGapMultiplier)
        topObstacle.name = "TopObstacle"
        worldNode.addChild(topObstacle)
        
        let moveX = size.width + topObstacle.size.width
        let moveDuration = moveX / kGroundSpeed
        let sequence = SKAction.sequence([
            SKAction.moveBy(x: -moveX, y: 0, duration: TimeInterval(moveDuration)),
            SKAction.removeFromParent()
            ])
        topObstacle.run(sequence)
        bottomObstacle.run(sequence)
        
    }
    
    func startSpawning() {
        
        let firstDelay = SKAction.wait(forDuration: kFirstSpawnDelay)
        let spawn = SKAction.run(spawnObstacle)
        let everyDelay = SKAction.wait(forDuration: kEverySpawnDelay)
        let spawnSequence = SKAction.sequence([
            spawn, everyDelay
            ])
        let foreverSpawn = SKAction.repeatForever(spawnSequence)
        let overallSequence = SKAction.sequence([firstDelay, foreverSpawn])
        run(overallSequence, withKey: "spawn")
        
    }
    
    func stopSpawning() {
        
        //removeAction(forKey: removeActionforKey, removeActionforKey: "spawn")
        
        worldNode.enumerateChildNodes(withName: "TopObstacle", using: { node, stop in
            node.removeAllActions()
        })
        worldNode.enumerateChildNodes(withName: "BottomObstacle", using: { node, stop in
            node.removeAllActions()
        })
        
    }
    
    func flapPlayer() {
        
        // Play sound
        run(flapAction)
        
        // Apply impulse
        playerVelocity = CGPoint(x: 0, y: kImpulse)
        playerAngularVelocity = kAngularVelocity.degreesToRadians()
        lastTouchTime = lastUpdateTime
        lastTouchY = player.position.y
        
        
        
    }
                  
        
    
       override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)  {
        
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        
        switch gameState {
        case .MainMenu:
            if touchLocation.y < size.height * 0.15 {
                learn()
            } else if touchLocation.x < size.width * 0.6 {
                switchToNewGame(gameState: .Tutorial)
            } else {
                rateApp()
            }
            break
        case .Tutorial:
            switchToPlay()
            break
        case .Play:
            flapPlayer()
            break
        case .Falling:
            break
        case .ShowingScore:
            break
        case .GameOver:
            if touchLocation.x < size.width * 0.6 {
                switchToNewGame(gameState: .MainMenu)
            } else {
                shareScore()
            }
            break
        }
    }
    
    // MARK: Updates
    
    override func update(_ currentTime: CFTimeInterval) {
        
        // return // DONLY
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        switch gameState {
        case .MainMenu:
            break
        case .Tutorial:
            break
        case .Play:
            updateForeground()
            updatePlayer()
            checkHitObstacle()
            checkHitGround()
            updateScore()
            break
        case .Falling:
            updatePlayer()
            checkHitGround()
            break
        case .ShowingScore:
            break
        case .GameOver:
            break
        }
        
    }
    
    func updatePlayer() {
        
        // Apply gravity
        let gravity = CGPoint(x: 0, y: kGravity)
        let gravityStep = gravity * CGFloat(dt)
        playerVelocity += gravityStep
        
        // Apply velocity
        let velocityStep = playerVelocity * CGFloat(dt)
        player.position += velocityStep
        player.position = CGPoint(x: player.position.x, y: min(player.position.y, size.height))
        
        if player.position.y < lastTouchY {
            playerAngularVelocity = -kAngularVelocity.degreesToRadians()
        }
        
        // Rotate player
        let angularStep = playerAngularVelocity * CGFloat(dt)
        player.zRotation += angularStep
        player.zRotation = min(max(player.zRotation, kMinDegrees.degreesToRadians()), kMaxDegrees.degreesToRadians())
        
        
    }
    
    func updateForeground() {
        
        worldNode.enumerateChildNodes(withName: "foreground", using: { node, stop in
            if let foreground = node as? SKSpriteNode {
                let moveAmt = CGPoint(x: -self.kGroundSpeed * CGFloat(self.dt), y: 0)
                foreground.position += moveAmt
                
                if foreground.position.x < -foreground.size.width {
                    foreground.position += CGPoint(x: foreground.size.width * CGFloat(self.kNumForegrounds), y: 0)
                }
                
            }
        })
        
    }
    
    func checkHitObstacle() {
        if hitObstacle {
            hitObstacle = false
            switchToFalling()
        }
    }
    
    func checkHitGround() {
        
        if hitGround {
            hitGround = false
            playerVelocity = CGPoint.zero
            player.zRotation = CGFloat(-90).degreesToRadians()
            player.position = CGPoint(x: player.position.x, y: playableStart + player.size.width/2)
            run(hitGroundAction)
            switchToShowScore()
        }
        
    }
    
    func updateScore() {
        
        worldNode.enumerateChildNodes(withName: "BottomObstacle", using: { node, stop in
            if let obstacle = node as? SKSpriteNode {
                if let passed = obstacle.userData?["Passed"] as? NSNumber {
                    if passed.boolValue {
                        return
                    }
                }
                if self.player.position.x > obstacle.position.x + obstacle.size.width/2 {
                    self.score += 1
                    self.scoreLabel.text = "\(self.score)"
                    self.run(self.coinAction)
                    obstacle.userData?["Passed"] = NSNumber(value: true)
                }
            }
        })
        
    }
    
    // MARK: Game States
    
    func switchToMainMenu() {
        
        gameState = .MainMenu
        setupBackground()
        setupForeground()
        setupPlayer()
        setupMainMenu()
        setupPlayerAnimation()
        
        // player.removeAllActions() // DONLY
        
    }
    
    func switchToTutorial() {
        gameState = .Tutorial
        setupBackground()
        setupForeground()
        setupPlayer()
        setupLabel()
        setupTutorial()
        setupPlayerAnimation()
    }
    
    func switchToPlay() {
        // Set state
        gameState = .Play
        
        // Remove tutorial
        worldNode.enumerateChildNodes(withName: "Tutorial", using: { node, stop in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
                ]))
        })
        
        // Stop wobble
        player.removeAction(forKey: "Wobble")
        
        // Start spawning
        startSpawning()
        
        // Move player
        flapPlayer()
    }
    
    func switchToFalling() {
        
        gameState = .Falling
        
        // Screen shake
        let shake = SKAction.screenShakeWithNode(node: worldNode, amount: CGPoint(x: 0, y: 7.0), oscillations: 10, duration: 1.0)
        worldNode.run(shake)
        
        // Flash
        let whiteNode = SKSpriteNode(color: SKColor.white, size: size)
        whiteNode.position = CGPoint(x: size.width/2, y: size.height/2)
        whiteNode.zPosition = Layer.Flash.rawValue
        worldNode.addChild(whiteNode)
        
        whiteNode.run(SKAction.removeFromParentAfterDelay(delay: 0.01))
        
        run(SKAction.sequence([
            whackAction,
            SKAction.wait(forDuration: 0.1),
            fallingAction
            ]))
        
        player.removeAllActions()
        stopSpawning()
        
    }
    
    func switchToShowScore() {
        gameState = .ShowingScore
        player.removeAllActions()
        stopSpawning()
        setupScorecard()
    }
    
    func switchToNewGame(gameState: GameState) {
        
        run(popAction)
        
        let newScene = GameScene(size: size, delegate: gameSceneDelegate, gameState: gameState)
        let transition = SKTransition.fade(with: SKColor.black, duration: 0.5)
        view?.presentScene(newScene, transition: transition)
        
    }
    
    func switchToGameOver() {
        gameState = .GameOver
    }
    
    // MARK: Score
    
    func bestScore() -> Int {
        return UserDefaults.standard.integer(forKey: "BestScore")
    }
    
    func setBestScore(bestScore: Int) {
        UserDefaults.standard.set(bestScore, forKey: "BestScore")
        UserDefaults.standard.synchronize()
    }
    
    func shareScore() {
        
        let urlString = "http://itunes.apple.com/app/id\(kAppStoreID)?mt=8"
        let url = NSURL(string: urlString)
        
        let screenshot = gameSceneDelegate.screenshot()
        let initialTextString = "OMG! I scored \(score) points in Flappy Felipe!"
        gameSceneDelegate.shareString(string: initialTextString, url: url!, image: screenshot)
        
    }
    
    func rateApp() {
        let urlString = "http://itunes.apple.com/app/id\(kAppStoreID)?mt=8"
        let url = NSURL(string: urlString)
        UIApplication.shared.openURL(url! as URL)
    }
    
    func learn() {
        let urlString = "http://toursindubai.wix.com/dubai"
        let url = NSURL(string: urlString)
        UIApplication.shared.openURL(url! as URL)
    }
    
    // MARK: Physics
    
    func didBeginContact(contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        if other.categoryBitMask == PhysicsCategory.Ground {
            hitGround = true
        }
        if other.categoryBitMask == PhysicsCategory.Obstacle {
            hitObstacle = true
        }
    }
    
}
