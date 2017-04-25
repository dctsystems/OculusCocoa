//
//  ViewController.m
//  OculusTest
//
//  Created by ian stephenson on 11/04/2017.
//  Copyright © 2017 ian stephenson. All rights reserved.
//

#import "ViewController.h"
#import "OculusView.h"

@implementation ViewController


unsigned int gen_chess_tex(float r0, float g0, float b0, float r1, float g1, float b1);

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
    // Update the view, if already loaded.
}

- (void)keyDown:(NSEvent *)theEvent {
    [(OculusView *)[self view] recenterPose];
        [super keyDown:theEvent];
}

@end
