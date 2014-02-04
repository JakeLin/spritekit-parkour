//
//  MainScene.m
//  Parkour
//
//  Created by Jake Lin on 7/01/2014.
//  Copyright (c) 2014 Jake Lin. All rights reserved.
//

#import "MainScene.h"

#import "SKTAudio.h"

#import "StartScene.h"


// the position X of the runner on the screen
static const float RUNNER_X = 120.0;
static const float RUNNER_HEIGHT = 56.0;
static const float JUMP_HEIGHT = 100.0;

// background scrolling speed
static const float BG_POINTS_PER_SEC = 200.0;
static const float INCREDIBLE_BG_POINTS_PER_SEC = 600.0;

static const int COINS_PER_MAP = 10;
static const int ROCKS_PER_MAP = 2;
static const float BG_WIDTH = 1440;

static const int COIN_RANDOM_FACTOR = (int) (BG_WIDTH / COINS_PER_MAP * 2);
static const int ROCK_RANDOM_FACTOR = (int) (BG_WIDTH / ROCKS_PER_MAP * 2);


#define BG_NAME @"bg"
#define GROUND_NAME @"ground"
#define COIN_NAME @"coin"
#define ROCK_NAME @"rock"
#define RUNNER_ANIMATION_KEY @"runnerAnimation"
#define RUNNER_EMITTER @"runnerEmitter"

enum RunnerState {
    running,
    jumping,
    crouching,
    incredible
};

static inline CGPoint CGPointAdd(const CGPoint a,
        const CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a,
        const CGFloat b) {
    return CGPointMake(a.x * b, a.y * b);
}

@interface MainScene () {
    SKSpriteNode *_runner;
    SKAction *_runningAnimation;
    SKAction *_jumpAnimation;
    SKAction *_crouchAnimation;
    SKAction *_coinAnimation;
    SKEmitterNode *_runnerEmitter;

    SKLabelNode *_scoreLabel;
    int _meter;
    SKLabelNode *_coinsLabel;
    int _coins;

    NSTimeInterval _lastUpdateTime;
    // time diff
    NSTimeInterval _dt;

    CGFloat _groundHalfHeight;

    enum RunnerState _runnerState;
    SKNode *_bgLayer;

    BOOL _isGameOver;
}
@end

@implementation MainScene

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */

        _bgLayer = [SKNode node];
        [self addChild:_bgLayer];
        [self initMap];

        [self initScoreLabel];
        [self initCoinsLabel];

        // adding background sound effect
        [[SKTAudio sharedInstance] playBackgroundMusic:@"background.mp3"];

        [self initRunnerAnimation];
        [_runner runAction:[SKAction repeatActionForever:_runningAnimation] withKey:RUNNER_ANIMATION_KEY];
        _runnerState = running;

        [self initRunnerParticle];

        [self initJumpAnimation];
        [self initCrouchAnimation];
        [self initCoinAnimation];

        // coins for fist map
        // [self generateRandomCoins:_ground.size.width/4];

        // coins for second map
        // int x = _ground.position.x;
        // [self generateRandomCoins:x];

        // rocks for second map
        // [self generateRandomRocks:x];
    }
    return self;
}

- (void)initRunnerParticle {
    _runnerEmitter = [NSKeyedUnarchiver unarchiveObjectWithFile:
            [[NSBundle mainBundle] pathForResource:@"RunnerParticle" ofType:@"sks"]];
    _runnerEmitter.position = CGPointMake(_runner.size.width / 2.0, _runner.size.height / 2.0);
    _runnerEmitter.name = RUNNER_EMITTER;
}

- (void)initCoinsLabel {
    _coins = 0;
    _coinsLabel = [SKLabelNode labelNodeWithFontNamed:@"Thonburi-Bold"];
    _coinsLabel.text = @"Coins: 0";
    _coinsLabel.fontSize = 20.0;
    // _coinsLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;// | SKLabelVerticalAlignmentModeBaseline;
    _coinsLabel.position = CGPointMake(50, self.frame.size.height - _coinsLabel.frame.size.height * 1.5);
    [self addChild:_coinsLabel];
}

- (void)initScoreLabel {
    _meter = 0;
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Thonburi-Bold"];
    _scoreLabel.text = @"0 Meter";
    _scoreLabel.fontSize = 20.0;
    // _scoreLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeRight;// | SKLabelVerticalAlignmentModeBaseline;
    _scoreLabel.position = CGPointMake(250, self.frame.size.height - _scoreLabel.frame.size.height * 1.5);
    [self addChild:_scoreLabel];

}

- (void)initMap {
// adding the background
    for (int i = 0; i < 2; ++i) {
        SKSpriteNode *map = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Map0%d", i]];
        map.anchorPoint = CGPointZero;
        map.position = CGPointMake(i * map.size.width, 0);;
        map.name = BG_NAME;
        [_bgLayer addChild:map];
    }

    // adding the ground
    SKSpriteNode *ground;
    for (int i = 0; i < 2; ++i) {
        ground = [SKSpriteNode spriteNodeWithImageNamed:[NSString stringWithFormat:@"Ground0%d", i]];
        ground.anchorPoint = CGPointZero;
        ground.position = CGPointMake(i * ground.size.width, 0);;
        ground.name = GROUND_NAME;
        _groundHalfHeight = ground.size.height / 2.0;
        [_bgLayer addChild:ground];
    }
}

- (void)initRunnerAnimation {
    // adding the runner
    _runner = [SKSpriteNode spriteNodeWithImageNamed:@"runner0"];
    _runner.anchorPoint = CGPointZero;
    _runner.position = CGPointMake(RUNNER_X, self.frame.origin.y + _groundHalfHeight + RUNNER_HEIGHT / 2.0);
    [self addChild:_runner];

    // adding running animation
    NSMutableArray *textures = [NSMutableArray arrayWithCapacity:8];
    for (int i = 0; i < 8; i++) {
        NSString *textureName = [NSString stringWithFormat:@"runner%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [textures addObject:texture];
    }

    _runningAnimation = [SKAction animateWithTextures:textures timePerFrame:0.1];
}

- (void)initCrouchAnimation {
    // adding crouch animation
    _crouchAnimation = [SKAction animateWithTextures:@[[SKTexture textureWithImageNamed:@"runnerCrouch0"]] timePerFrame:1.4 resize:YES restore:YES];
}

- (void)initJumpAnimation {
    // adding jump animation
    NSMutableArray *jumpUpTextures = [NSMutableArray arrayWithCapacity:4];
    for (int i = 0; i < 4; i++) {
        NSString *textureName = [NSString stringWithFormat:@"runnerJumpUp%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [jumpUpTextures addObject:texture];
    }

    SKAction *jumpUpAnimation = [SKAction animateWithTextures:jumpUpTextures timePerFrame:0.2 resize:YES restore:YES];
    SKAction *moveUpAction = [SKAction moveByX:0 y:JUMP_HEIGHT duration:0.8];
    SKAction *jumpUpAction = [SKAction group:@[jumpUpAnimation, moveUpAction]];

    NSMutableArray *jumpDownTextures = [NSMutableArray arrayWithCapacity:2];
    for (int i = 0; i < 2; i++) {
        NSString *textureName = [NSString stringWithFormat:@"runnerJumpDown%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [jumpDownTextures addObject:texture];
    }

    SKAction *jumpDownAnimation = [SKAction animateWithTextures:jumpDownTextures timePerFrame:0.3 resize:YES restore:YES];
    SKAction *moveDownAction = [SKAction moveByX:0 y:-JUMP_HEIGHT duration:0.6];
    SKAction *jumpDownAction = [SKAction group:@[jumpDownAnimation, moveDownAction]];

    _jumpAnimation = [SKAction sequence:@[jumpUpAction, jumpDownAction]];
}

- (void)initCoinAnimation {
    // adding coin animation
    NSMutableArray *coinTextures = [NSMutableArray arrayWithCapacity:8];
    for (int i = 0; i < 8; i++) {
        NSString *textureName = [NSString stringWithFormat:@"coin%d", i];
        SKTexture *texture = [SKTexture textureWithImageNamed:textureName];
        [coinTextures addObject:texture];
    }
    _coinAnimation = [SKAction animateWithTextures:coinTextures timePerFrame:0.1];
}

- (void)moveBackground {
    CGPoint bgVelocity;
    if (_runnerState == incredible) {
        bgVelocity = CGPointMake(-INCREDIBLE_BG_POINTS_PER_SEC, 0);
    }
    else {
        bgVelocity = CGPointMake(-BG_POINTS_PER_SEC, 0);
    }
    CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity, _dt);

    // move the map
    [_bgLayer enumerateChildNodesWithName:BG_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *bg = (SKSpriteNode *) node;
        bg.position = CGPointAdd(bg.position, amtToMove);
        if (bg.position.x <= -bg.size.width) {
            int x = (int) (bg.position.x + bg.size.width * 2);
            bg.position = CGPointMake(x, bg.position.y);

            // NSLog(@"%f %f", bg.position.x, bg.size.width);
            // coins for new map
            [self generateRandomCoins:x];
            [self generateRandomRocks:x];
        }
    }];

    // move the ground
    [_bgLayer enumerateChildNodesWithName:GROUND_NAME usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *ground = (SKSpriteNode *) node;
        ground.position = CGPointAdd(ground.position, amtToMove);
        if (ground.position.x <= -ground.size.width) {
            int x = (int) (ground.position.x + ground.size.width * 2);
            ground.position = CGPointMake(x, ground.position.y);
        }
    }];

    [self moveObject:COIN_NAME to:amtToMove];
    [self moveObject:ROCK_NAME to:amtToMove];
}

- (void)moveObject:(NSString *)name to:(CGPoint)amtToMove {
    // move coins
    [_bgLayer enumerateChildNodesWithName:name usingBlock:^(SKNode *node, BOOL *stop) {
        SKSpriteNode *coin = (SKSpriteNode *) node;
        coin.position = CGPointAdd(coin.position, amtToMove);
        if (coin.position.x <= -coin.size.width) {
            // off the screen, remove itself
            [coin removeFromParent];
        }
    }];
}

- (void)didMoveToView:(SKView *)view {
    UISwipeGestureRecognizer *swipeUpGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    swipeUpGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUpGestureRecognizer];

    UISwipeGestureRecognizer *swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDownGestureRecognizer];

    UISwipeGestureRecognizer *swipeRightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeRightGestureRecognizer];
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe Right!");
    [self startIncredibleMode];
}

- (void)startIncredibleMode {
    if (_runnerState != running) {
        return;
    }
    _runnerState = incredible;
    // stop it after 5 sec
    SKAction *wait = [SKAction waitForDuration:5.0];
    [_runner runAction:wait completion:^{
        _runnerState = running;
        [_runner removeChildrenInArray:@[_runnerEmitter]];
    }];
    [_runner addChild:_runnerEmitter];
}

- (void)handleSwipeUp:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe Up!");
    [self jump];
}

- (void)jump {
    if (_runnerState != running) {
        return;
    }
    _runnerState = jumping;
    [_runner removeActionForKey:RUNNER_ANIMATION_KEY];
    [_runner runAction:_jumpAnimation completion:^{
        [_runner removeAllActions];
        [_runner runAction:[SKAction repeatActionForever:_runningAnimation] withKey:RUNNER_ANIMATION_KEY];
        _runnerState = running;
    }];
    [self runAction:[SKAction playSoundFileNamed:@"jump.mp3" waitForCompletion:NO]];
}

- (void)handleSwipeDown:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"Swipe Down!");
    [self crouch];
}

- (void)crouch {
    if (_runnerState != running) {
        return;
    }
    _runnerState = crouching;
    [_runner removeActionForKey:RUNNER_ANIMATION_KEY];
    [_runner runAction:_crouchAnimation completion:^{
        [_runner removeAllActions];
        [_runner runAction:[SKAction repeatActionForever:_runningAnimation] withKey:RUNNER_ANIMATION_KEY];
        _runnerState = running;
    }];
    [self runAction:[SKAction playSoundFileNamed:@"crouch.mp3" waitForCompletion:NO]];
}


- (void)generateRandomCoins:(int)x {
    for (int i = 0; i < COINS_PER_MAP; ++i) {
        x += (arc4random() % COIN_RANDOM_FACTOR);
        SKSpriteNode *coin = [SKSpriteNode spriteNodeWithImageNamed:@"coin0"];
        coin.position = CGPointMake(x, _groundHalfHeight + RUNNER_HEIGHT / 2.0);
        coin.anchorPoint = CGPointZero;
        coin.name = COIN_NAME;
        [coin runAction:[SKAction repeatActionForever:_coinAnimation]];
        [_bgLayer addChild:coin];
    }
}

- (void)generateRandomRocks:(int)x {
    SKSpriteNode *rock = [SKSpriteNode spriteNodeWithImageNamed:@"rock"];
    int x1 = x + (arc4random() % ROCK_RANDOM_FACTOR);
    rock.position = CGPointMake(x1, _groundHalfHeight + RUNNER_HEIGHT / 2.0);
    rock.anchorPoint = CGPointZero;
    rock.name = ROCK_NAME;
    [_bgLayer addChild:rock];

    int x2 = x + (arc4random() % ROCK_RANDOM_FACTOR);
    SKSpriteNode *hathpace = [SKSpriteNode spriteNodeWithImageNamed:@"hathpace"];
    hathpace.position = CGPointMake(x2, _groundHalfHeight + RUNNER_HEIGHT * 1.5);
    hathpace.name = ROCK_NAME;
    [_bgLayer addChild:hathpace];
}

- (void)checkCollisions {
    // Check the coins
    [_bgLayer enumerateChildNodesWithName:COIN_NAME
                               usingBlock:^(SKNode *node, BOOL *stop) {
                                   SKSpriteNode *coin = (SKSpriteNode *) node;
                                   if (CGRectIntersectsRect(coin.frame, _runner.frame)) {
                                       [self runAction:[SKAction playSoundFileNamed:@"pickup_coin.mp3" waitForCompletion:NO]];
                                       _coinsLabel.text = [NSString stringWithFormat:@"Coins: %d", ++_coins];
                                       [coin removeFromParent];
                                   }
                               }];

    // Check the rocks
    [_bgLayer enumerateChildNodesWithName:ROCK_NAME
                               usingBlock:^(SKNode *node, BOOL *stop) {
                                   SKSpriteNode *rock = (SKSpriteNode *) node;
                                   CGRect smallerFrame = CGRectInset(rock.frame, 20, 20);
                                   if (CGRectIntersectsRect(_runner.frame, smallerFrame)) {
                                       if (_runnerState == incredible) {
                                           [rock removeFromParent];
                                       }
                                       else {
                                           [self gameOver];
                                       }
                                   }
                               }];
}

- (void)gameOver {
    NSLog(@"GameOver");
    _isGameOver = YES;
    [_runner removeActionForKey:RUNNER_ANIMATION_KEY];
    StartScene *startScene = [[StartScene alloc] initWithSize:self.size showRestartButton:YES];
    SKTransition *reveal = [SKTransition flipHorizontalWithDuration:2.0];
    [self.view presentScene:startScene transition:reveal];
}

- (void)update:(NSTimeInterval)currentTime {
    if (_isGameOver) {
        return;
    }

    if (_lastUpdateTime) {
        _dt = currentTime - _lastUpdateTime;
    } else {
        _dt = 0;
    }
    _lastUpdateTime = currentTime;

    // Runner faster than normal
    if (_runnerState == incredible) {
        _meter += INCREDIBLE_BG_POINTS_PER_SEC / BG_POINTS_PER_SEC;
    }
    else {
        ++_meter;
    }
    _scoreLabel.text = [NSString stringWithFormat:@"%d Meters", _meter];

    [self checkCollisions];
    [self moveBackground];
}
@end
