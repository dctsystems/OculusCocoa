# OculusCocoa
Make basic Oculus DK2 code trivial on OSX

A MacOS demo of Oculus DK2.

TOTALLY based (Full credit!) on the great C version by John Tsiombikas <nuclear@member.fsf.org>

To build you'll need the OSX Oculus SDK (v0.5?) installed in addition to the regular Oculus runtime. The framework you need is libOVR.framework, which you can build from oculus source. There appears to be a config error in the header files, so you may need to create a file called OVR_CPI.h which links to or #includes the similarly named file in the SDK. Once you've build libOVR.framework, drop it into ~/Library/Frameworks and you're good to go!

To use this in your own code, implent the <OculusViewDelegate> protocol:

-(void)initScene:(NSView *) sender;     //Called once
- (void)prepFrame:(NSView *) sender;    //Called at start of frame
- (void)drawScene:(NSView *) sender;    //Called once per eye per frame

Inside drawScene you just draw as you would for regular openGL. It gets called twice per frame, with the eye transform already worked out.
