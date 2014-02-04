//
//  StartScene.m
//  Parkour
//
//  Created by Jake Lin on 4/01/2014.
//  Copyright (c) 2014 Jake Lin. All rights reserved.
//

#import "StartScene.h"
#import "MainScene.h"

@interface StartScene () {
    SKSpriteNode *_startButton;
    BOOL _startButtonPressed;
    BOOL _showRestartButton;
}

@end

@implementation StartScene

- (id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */

        //adding the background
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"MainBG"];
        CGPoint position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        background.position = position;
        [self addChild:background];

        if (_showRestartButton) {
            _startButton = [SKSpriteNode spriteNodeWithImageNamed:@"restart_n"];
        }
        else {
            _startButton = [SKSpriteNode spriteNodeWithImageNamed:@"start_n"];
        }
        _startButton.position = position;
        [self addChild:_startButton];
    }
    return self;
}

- (id)initWithSize:(CGSize)size showRestartButton:(BOOL)display {
    _showRestartButton = display;
    return [self initWithSize:size];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];

    //if fire button touched, bring the rain
    if (node == _startButton) {
        if (_showRestartButton) {
            [_startButton setTexture:[SKTexture textureWithImageNamed:@"restart_s"]];
        }
        else {
            [_startButton setTexture:[SKTexture textureWithImageNamed:@"start_s"]];
        }
        _startButtonPressed = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // Change to MainScene
    if (_startButtonPressed) {
        SKScene *mainScene = [[MainScene alloc] initWithSize:self.size];
        SKTransition *reveal = [SKTransition flipHorizontalWithDuration:0.5];
        [self.view presentScene:mainScene transition:reveal];
    }
}

- (void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
