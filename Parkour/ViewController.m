//
//  ViewController.m
//  Parkour
//
//  Created by Jake Lin on 4/01/2014.
//  Copyright (c) 2014 Jake Lin. All rights reserved.
//

#import "ViewController.h"
#import "StartScene.h"

@implementation ViewController

// JL: Ensure to get the correct View Controller’s main view’s size
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Configure the view.
    SKView *skView = (SKView *) self.view;
    if (!skView.scene) {
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;

        // Create and configure the scene.
        SKScene *scene = [StartScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;

        // Present the scene.
        [skView presentScene:scene];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
