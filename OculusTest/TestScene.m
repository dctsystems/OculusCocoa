//
//  TestScene.m
//  OculusTest
//
//  Created by ian stephenson on 11/04/2017.
//  Copyright © 2017 ian stephenson. All rights reserved.
//

#import "TestScene.h"

#import <OpenGL/OpenGL.h>

@implementation TestScene
/* generate a chessboard texture with tiles colored (r0, g0, b0) and (r1, g1, b1) */
unsigned int gen_chess_tex(float r0, float g0, float b0, float r1, float g1, float b1)
{
    int i, j;
    unsigned int tex;
    unsigned char img[8 * 8 * 3];
    unsigned char *pix = img;
    
    for(i=0; i<8; i++) {
        for(j=0; j<8; j++) {
            int black = (i & 1) == (j & 1);
            pix[0] = (black ? r0 : r1) * 255;
            pix[1] = (black ? g0 : g1) * 255;
            pix[2] = (black ? b0 : b1) * 255;
            pix += 3;
        }
    }
    
    glGenTextures(1, &tex);
    glBindTexture(GL_TEXTURE_2D, tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 8, 8, 0, GL_RGB, GL_UNSIGNED_BYTE, img);
    
    return tex;
}


void draw_box(float xsz, float ysz, float zsz, float norm_sign)
{
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glScalef(xsz * 0.5, ysz * 0.5, zsz * 0.5);
    
    if(norm_sign < 0.0) {
        glFrontFace(GL_CW);
    }
    
    glBegin(GL_QUADS);
    glNormal3f(0, 0, 1 * norm_sign);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, 1);
    glTexCoord2f(1, 0); glVertex3f(1, -1, 1);
    glTexCoord2f(1, 1); glVertex3f(1, 1, 1);
    glTexCoord2f(0, 1); glVertex3f(-1, 1, 1);
    glNormal3f(1 * norm_sign, 0, 0);
    glTexCoord2f(0, 0); glVertex3f(1, -1, 1);
    glTexCoord2f(1, 0); glVertex3f(1, -1, -1);
    glTexCoord2f(1, 1); glVertex3f(1, 1, -1);
    glTexCoord2f(0, 1); glVertex3f(1, 1, 1);
    glNormal3f(0, 0, -1 * norm_sign);
    glTexCoord2f(0, 0); glVertex3f(1, -1, -1);
    glTexCoord2f(1, 0); glVertex3f(-1, -1, -1);
    glTexCoord2f(1, 1); glVertex3f(-1, 1, -1);
    glTexCoord2f(0, 1); glVertex3f(1, 1, -1);
    glNormal3f(-1 * norm_sign, 0, 0);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, -1);
    glTexCoord2f(1, 0); glVertex3f(-1, -1, 1);
    glTexCoord2f(1, 1); glVertex3f(-1, 1, 1);
    glTexCoord2f(0, 1); glVertex3f(-1, 1, -1);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glNormal3f(0, 1 * norm_sign, 0);
    glTexCoord2f(0.5, 0.5); glVertex3f(0, 1, 0);
    glTexCoord2f(0, 0); glVertex3f(-1, 1, 1);
    glTexCoord2f(1, 0); glVertex3f(1, 1, 1);
    glTexCoord2f(1, 1); glVertex3f(1, 1, -1);
    glTexCoord2f(0, 1); glVertex3f(-1, 1, -1);
    glTexCoord2f(0, 0); glVertex3f(-1, 1, 1);
    glEnd();
    glBegin(GL_TRIANGLE_FAN);
    glNormal3f(0, -1 * norm_sign, 0);
    glTexCoord2f(0.5, 0.5); glVertex3f(0, -1, 0);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, -1);
    glTexCoord2f(1, 0); glVertex3f(1, -1, -1);
    glTexCoord2f(1, 1); glVertex3f(1, -1, 1);
    glTexCoord2f(0, 1); glVertex3f(-1, -1, 1);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, -1);
    glEnd();
    
    glFrontFace(GL_CCW);
    glPopMatrix();
}
-(void)initScene:(NSView *) sender;
{
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_LIGHT1);
    glEnable(GL_NORMALIZE);
    
    glClearColor(0.1, 0.1, 0.1, 1);
    
    chess_tex = gen_chess_tex(1.0, 0.7, 0.4, 0.4, 0.7, 1.0);
    
    [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)5
                                     target:sender
                                   selector:@selector(dismissWarning)
                                   userInfo:NULL
                                    repeats:NO];
    
}

- (void)prepFrame:(NSView *) sender
{
    
}


- (void)drawScene:(NSView *) sender;
{
    int i;
    float grey[] = {0.8, 0.8, 0.8, 1};
    float col[] = {0, 0, 0, 1};
    float lpos[][4] = {
        {-8, 2, 10, 1},
        {0, 15, 0, 1}
    };
    float lcol[][4] = {
        {0.8, 0.8, 0.8, 1},
        {0.4, 0.3, 0.3, 1}
    };
    
    for(i=0; i<2; i++) {
        glLightfv(GL_LIGHT0 + i, GL_POSITION, lpos[i]);
        glLightfv(GL_LIGHT0 + i, GL_DIFFUSE, lcol[i]);
    }
    
    glMatrixMode(GL_MODELVIEW);
    
    glPushMatrix();
    glTranslatef(0, 10, 0);
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, grey);
    glBindTexture(GL_TEXTURE_2D, chess_tex);
    glEnable(GL_TEXTURE_2D);
    draw_box(30, 20, 30, -1.0);
    glDisable(GL_TEXTURE_2D);
    glPopMatrix();
    
    for(i=0; i<4; i++) {
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, grey);
        glPushMatrix();
        glTranslatef(i & 1 ? 5 : -5, 1, i & 2 ? -5 : 5);
        draw_box(0.5, 2, 0.5, 1.0);
        glPopMatrix();
        
        col[0] = i & 1 ? 1.0 : 0.3;
        col[1] = i == 0 ? 1.0 : 0.3;
        col[2] = i & 2 ? 1.0 : 0.3;
        glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, col);
        
        glPushMatrix();
        if(i & 1) {
            glTranslatef(0, 0.25, i & 2 ? 2 : -2);
        } else {
            glTranslatef(i & 2 ? 2 : -2, 0.25, 0);
        }
        draw_box(0.5, 0.5, 0.5, 1.0);
        glPopMatrix();
    }
    
    col[0] = 1;
    col[1] = 1;
    col[2] = 0.4;
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, col);
    draw_box(0.05, 1.2, 6, 1.0);
    draw_box(6, 1.2, 0.05, 1.0);
}
@end
