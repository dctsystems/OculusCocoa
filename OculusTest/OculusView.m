//
//  OculusView.m
//  OculusTest
//
//  Created by ian stephenson on 11/04/2017.
//  Copyright © 2017 ian stephenson. All rights reserved.
//

#import "OculusView.h"
#import "CoreGraphics/CoreGraphics.h"
#import <OpenGL/gl.h>

@implementation OculusView
unsigned int next_pow2(unsigned int x)
{
    x -= 1;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
}

-(void) updateRTarget:(int)width :(int) height
{
     unsigned int fb_depth=0;
    if(!fbo) {
        /* if fbo does not exist, then nothing does... create every opengl object */
        glGenFramebuffers(1, &fbo);
        glGenTextures(1, &fb_tex);
        glGenRenderbuffers(1, &fb_depth);
        
        glBindTexture(GL_TEXTURE_2D, fb_tex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    
    /* calculate the next power of two in both dimensions and use that as a texture size */
    fb_tex_width = next_pow2(width);
    fb_tex_height = next_pow2(height);
    
    /* create and attach the texture that will be used as a color buffer */
    glBindTexture(GL_TEXTURE_2D, fb_tex);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, fb_tex_width, fb_tex_height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, fb_tex, 0);
    
    /* create and attach the renderbuffer that will serve as our z-buffer */
    glBindRenderbuffer(GL_RENDERBUFFER, fb_depth);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, fb_tex_width, fb_tex_height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, fb_depth);
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        fprintf(stderr, "incomplete framebuffer!\n");
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    printf("created render target: %dx%d (texture size: %dx%d)\n", width, height, fb_tex_width, fb_tex_height);
}

-(void)awakeFromNib
{
    int i;
    ovr_Initialize(0);

   if(!(hmd = ovrHmd_Create(0))) {
        fprintf(stderr, "failed to open Oculus HMD, falling back to virtual debug HMD\n");
        if(!(hmd = ovrHmd_CreateDebug(ovrHmd_DK2))) {
            fprintf(stderr, "failed to create virtual debug HMD\n");
            return ;
        }
    }
    printf("initialized HMD: %s - %s\n", hmd->Manufacturer, hmd->ProductName);

   int win_width = hmd->Resolution.w;
   int win_height = hmd->Resolution.h;
    
    /* enable position and rotation tracking */
    ovrHmd_ConfigureTracking(hmd, ovrTrackingCap_Orientation | ovrTrackingCap_MagYawCorrection | ovrTrackingCap_Position, 0);
    /* retrieve the optimal render target resolution for each eye */
    eyeres[0] = ovrHmd_GetFovTextureSize(hmd, ovrEye_Left, hmd->DefaultEyeFov[0], 1.0);
    eyeres[1] = ovrHmd_GetFovTextureSize(hmd, ovrEye_Right, hmd->DefaultEyeFov[1], 1.0);
    
    /* and create a single render target texture to encompass both eyes */
    fb_width = eyeres[0].w + eyeres[1].w;
    fb_height = eyeres[0].h > eyeres[1].h ? eyeres[0].h : eyeres[1].h;
    
    
    
    [[self openGLContext] makeCurrentContext];
    [self updateRTarget:fb_width : fb_height];
    
    /* fill in the ovrGLTexture structures that describe our render target texture */
    for(i=0; i<2; i++) {
        fb_ovr_tex[i].OGL.Header.API = ovrRenderAPI_OpenGL;
        fb_ovr_tex[i].OGL.Header.TextureSize.w = fb_tex_width;
        fb_ovr_tex[i].OGL.Header.TextureSize.h = fb_tex_height;
        /* this next field is the only one that differs between the two eyes */
        fb_ovr_tex[i].OGL.Header.RenderViewport.Pos.x = i == 0 ? 0 : fb_width / 2.0;
        fb_ovr_tex[i].OGL.Header.RenderViewport.Pos.y = 0;
        fb_ovr_tex[i].OGL.Header.RenderViewport.Size.w = fb_width / 2.0;
        fb_ovr_tex[i].OGL.Header.RenderViewport.Size.h = fb_height;
        fb_ovr_tex[i].OGL.TexId = fb_tex;	/* both eyes will use the same texture id */
    }
    
    /* fill in the ovrGLConfig structure needed by the SDK to draw our stereo pair
     * to the actual HMD display (SDK-distortion mode)
     */
    memset(&glcfg, 0, sizeof glcfg);
    glcfg.OGL.Header.API = ovrRenderAPI_OpenGL;
    glcfg.OGL.Header.BackBufferSize.w = win_width;
    glcfg.OGL.Header.BackBufferSize.h = win_height;
    glcfg.OGL.Header.Multisample = 1;
    
#ifdef OVR_OS_WIN32
    glcfg.OGL.Window = GetActiveWindow();
    glcfg.OGL.DC = wglGetCurrentDC();
#elif defined(OVR_OS_LINUX)
    glcfg.OGL.Disp = glXGetCurrentDisplay();
#endif
    
    if(hmd->HmdCaps & ovrHmdCap_ExtendDesktop) {
        printf("running in \"extended desktop\" mode\n");
    } else {
        /* to sucessfully draw to the HMD display in "direct-hmd" mode, we have to
         * call ovrHmd_AttachToWindow
         * XXX: this doesn't work properly yet due to bugs in the oculus 0.4.1 sdk/driver
         */
#ifdef WIN32
        ovrHmd_AttachToWindow(hmd, glcfg.OGL.Window, 0, 0);
#elif defined(OVR_OS_LINUX)
        ovrHmd_AttachToWindow(hmd, (void*)glXGetCurrentDrawable(), 0, 0);
#endif
        printf("running in \"direct-hmd\" mode\n");
    }
    
    /* enable low-persistence display and dynamic prediction for lattency compensation */
    hmd_caps = ovrHmdCap_LowPersistence | ovrHmdCap_DynamicPrediction;
    ovrHmd_SetEnabledCaps(hmd, hmd_caps);
    
    /* configure SDK-rendering and enable OLED overdrive and timewrap, which
     * shifts the image before drawing to counter any lattency between the call
     * to ovrHmd_GetEyePose and ovrHmd_EndFrame.
     */
    distort_caps = ovrDistortionCap_TimeWarp | ovrDistortionCap_Overdrive;
    if(!ovrHmd_ConfigureRendering(hmd, &glcfg.Config, distort_caps, hmd->DefaultEyeFov, eye_rdesc)) {
        fprintf(stderr, "failed to configure distortion renderer\n");
    }
    
    
    [[self delegate] initScene:self];
 
    
    refreshTimer=[NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.01
                                                  target:self
                                                selector:@selector(display)
                                                userInfo:NULL
                                                 repeats:YES];
    
    //This doesn't work if we do it here...
    //Wait until the run loop is ready!
    tok=0;
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0
                                     target:self
                                   selector:@selector(goFullScreen)
                                   userInfo:nil
                                    repeats:NO];
}




-(void)goFullScreen
{
    [[self window] setFrameOrigin: NSMakePoint(hmd->WindowsPos.x, hmd->WindowsPos.y)];//Hide old window behind full screen!
    NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens, nil];
    //id   screen=[[self window] screen];

    if(hmd->DisplayId>=0)
        {
            CGDirectDisplayID RiftDisplayId = (CGDirectDisplayID) hmd->DisplayId;
            
            NSScreen* usescreen = [NSScreen mainScreen];
            NSArray* screens = [NSScreen screens];
            for (int i = 0; i < [screens count]; i++)
            {
                NSScreen* s = (NSScreen*)[screens objectAtIndex:i];
                CGDirectDisplayID disp=(CGDirectDisplayID)[[[s deviceDescription] objectForKey:@"NSScreenNumber"] integerValue];
                if (disp == RiftDisplayId)
                    usescreen = s;
            }
            
        [[self window] setReleasedWhenClosed:NO];
        [[self window] close];
        
            if(tok==0)
                CGAcquireDisplayFadeReservation(25, &tok);
            CGDisplayFade(tok, 0.5, kCGDisplayBlendNormal, kCGDisplayBlendSolidColor, 0, 0, 0, TRUE);
            [self enterFullScreenMode:usescreen withOptions:opts];
            CGDisplayFade(tok, 0.5, kCGDisplayBlendSolidColor, kCGDisplayBlendNormal, 0, 0, 0, FALSE);
        }
}

-(void)dismissWarning
{
    ovrHSWDisplayState hsw;
    ovrHmd_GetHSWDisplayState(hmd, &hsw);
    if(hsw.Displayed) {
        ovrHmd_DismissHSWDisplay(hmd);
    }
}

-(void)recenterPose
{
    ovrHmd_RecenterPose(hmd);
}

/* convert a quaternion to a rotation matrix */
static void quat_to_matrix(const float *quat, float *mat)
{
    mat[0] = 1.0 - 2.0 * quat[1] * quat[1] - 2.0 * quat[2] * quat[2];
    mat[4] = 2.0 * quat[0] * quat[1] + 2.0 * quat[3] * quat[2];
    mat[8] = 2.0 * quat[2] * quat[0] - 2.0 * quat[3] * quat[1];
    mat[12] = 0.0f;
    
    mat[1] = 2.0 * quat[0] * quat[1] - 2.0 * quat[3] * quat[2];
    mat[5] = 1.0 - 2.0 * quat[0]*quat[0] - 2.0 * quat[2]*quat[2];
    mat[9] = 2.0 * quat[1] * quat[2] + 2.0 * quat[3] * quat[0];
    mat[13] = 0.0f;
    
    mat[2] = 2.0 * quat[2] * quat[0] + 2.0 * quat[3] * quat[1];
    mat[6] = 2.0 * quat[1] * quat[2] - 2.0 * quat[3] * quat[0];
    mat[10] = 1.0 - 2.0 * quat[0]*quat[0] - 2.0 * quat[1]*quat[1];
    mat[14] = 0.0f;
    
    mat[3] = mat[7] = mat[11] = 0.0f;
    mat[15] = 1.0f;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
        int i;
        ovrMatrix4f proj;
        ovrPosef pose[2];
        float rot_mat[16];
        
        /* the drawing starts with a call to ovrHmd_BeginFrame */
        ovrHmd_BeginFrame(hmd, 0);

        [[self delegate] prepFrame:self];

        /* start drawing onto our texture render target */
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        /* for each eye ... */
        for(i=0; i<2; i++) {
            ovrEyeType eye = hmd->EyeRenderOrder[i];
            
            /* -- viewport transformation --
             * setup the viewport to draw in the left half of the framebuffer when we're
             * rendering the left eye's view (0, 0, width/2, height), and in the right half
             * of the framebuffer for the right eye's view (width/2, 0, width/2, height)
             */
            glViewport(eye == ovrEye_Left ? 0 : fb_width / 2, 0, fb_width / 2, fb_height);
            
            /* -- projection transformation --
             * we'll just have to use the projection matrix supplied by the oculus SDK for this eye
             * note that libovr matrices are the transpose of what OpenGL expects, so we have to
             * use glLoadTransposeMatrixf instead of glLoadMatrixf to load it.
             */
            proj = ovrMatrix4f_Projection(hmd->DefaultEyeFov[eye], 0.5, 500.0, 1);
            glMatrixMode(GL_PROJECTION);
            glLoadTransposeMatrixf(proj.M[0]);
            
            /* -- view/camera transformation --
             * we need to construct a view matrix by combining all the information provided by the oculus
             * SDK, about the position and orientation of the user's head in the world.
             */
            /* TODO: use ovrHmd_GetEyePoses out of the loop instead */
            pose[eye] = ovrHmd_GetHmdPosePerEye(hmd, eye);
            glMatrixMode(GL_MODELVIEW);
            glLoadIdentity();
            glTranslatef(eye_rdesc[eye].HmdToEyeViewOffset.x,
                         eye_rdesc[eye].HmdToEyeViewOffset.y,
                         eye_rdesc[eye].HmdToEyeViewOffset.z);
            /* retrieve the orientation quaternion and convert it to a rotation matrix */
            quat_to_matrix(&pose[eye].Orientation.x, rot_mat);
            glMultMatrixf(rot_mat);
            /* translate the view matrix with the positional tracking */
            glTranslatef(-pose[eye].Position.x, -pose[eye].Position.y, -pose[eye].Position.z);
            /* move the camera to the eye level of the user */
            glTranslatef(0, -ovrHmd_GetFloat(hmd, OVR_KEY_EYE_HEIGHT, 1.65), 0);
            
            /* finally draw the scene for this eye */
            [[self delegate] drawScene:self];
        }
        
        /* after drawing both eyes into the texture render target, revert to drawing directly to the
         * display, and we call ovrHmd_EndFrame, to let the Oculus SDK draw both images properly
         * compensated for lens distortion and chromatic abberation onto the HMD screen.
         */
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
        ovrHmd_EndFrame(hmd, pose, &fb_ovr_tex[0].Texture);
        
        /* workaround for the oculus sdk distortion renderer bug, which uses a shader
         * program, and doesn't restore the original binding when it's done.
         */
        glUseProgram(0);
        
        assert(glGetError() == GL_NO_ERROR);
}

@end
