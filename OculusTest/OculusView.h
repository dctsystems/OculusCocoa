//
//  OculusView.h
//  OculusTest
//
//  Created by ian stephenson on 11/04/2017.
//  Copyright © 2017 ian stephenson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <LibOVR/OVR_CAPI.h>
#include <LibOVR/OVR_CAPI_GL.h>

@protocol OculusViewDelegate < NSObject >

-(void)initScene:(NSView *) sender;     //Called once
- (void)prepFrame:(NSView *) sender;    //Called at start of frame
- (void)drawScene:(NSView *) sender;    //Called once per eye per frame

@end

@interface OculusView : NSOpenGLView
{
    NSTimer *refreshTimer;
    
    ovrHmd hmd;
    unsigned int fbo;
    int fb_width, fb_height;
    ovrSizei eyeres[2];
    ovrEyeRenderDesc eye_rdesc[2];
    ovrGLTexture fb_ovr_tex[2];
    unsigned int fb_tex;
    int fb_tex_width, fb_tex_height;
 
    union ovrGLConfig glcfg;
     unsigned int distort_caps;
     unsigned int hmd_caps;
    
    
    CGDisplayFadeReservationToken tok;
}
@property (nonatomic, assign) IBOutlet id <OculusViewDelegate> delegate;

-(void)dismissWarning;
-(void)goFullScreen;
-(void)recenterPose;

@end
