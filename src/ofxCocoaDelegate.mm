/////////////////////////////////////////////////////
//
//  ofxCocoaDelegate.mm
//  ofxCocoaWindow
//
//  Created by lukasz karluk on 16/11/11.
//  http://julapy.com/blog
//
/////////////////////////////////////////////////////

#import "ofxCocoaDelegate.h"

@implementation ofxCocoaDelegate

@synthesize openGLWindow;
@synthesize openGLView;
@synthesize fullScreenWindow;
@synthesize fullScreenView;
@synthesize windowMode;

- (id) init 
{
	return [ self initWithWidth : 1024 
                         height : 768
                     windowMode : OF_WINDOW ];
}

- (id) initWithWidth : (int)width 
              height : (int)height 
          windowMode : (ofWindowMode)mode;
{
	if( self = [super init] )
    {
        self.windowMode = mode;
        
		NSRect contentSize = NSMakeRect( 0.0f, 0.0f, width, height );

		// This is where the nibless window happens
		self.openGLWindow = [ [ NSWindow alloc ] initWithContentRect : contentSize 
                                                           styleMask : NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                             backing : NSBackingStoreBuffered 
                                                               defer : NO ];
		
		[ self.openGLWindow setLevel : NSNormalWindowLevel ];
		
		self.openGLView = [ [ GLView alloc ] initWithFrame : contentSize 
                                              shareContext : nil ];

		[ self.openGLWindow setContentView : self.openGLView ];
	}
    
	return self;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	// This is where the nibless menu happens
	// Obviously, just the basics
	id menubar = [[NSMenu new] autorelease];
	id appMenuItem = [[NSMenuItem new] autorelease];
	[menubar addItem:appMenuItem];
	[NSApp setMainMenu:menubar];
	id appMenu = [[NSMenu new] autorelease];
	id appName = [[NSProcessInfo processInfo] processName];
	id quitTitle = [@"Quit " stringByAppendingString:appName];
	id quitMenuItem = [[[NSMenuItem alloc] initWithTitle:quitTitle 
												  action:@selector(terminate:)
										   keyEquivalent:@"q"] autorelease];
	[appMenu addItem:quitMenuItem];
	[appMenuItem setSubmenu:appMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification 
{
	glClearColor(ofBgColorPtr()[0], ofBgColorPtr()[1], ofBgColorPtr()[2], ofBgColorPtr()[3]);
	glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	[ self.openGLWindow cascadeTopLeftFromPoint : NSMakePoint( 20, 20 ) ];
	[ self.openGLWindow setTitle: [ [ NSProcessInfo processInfo ] processName ] ];
	[ self.openGLWindow makeKeyAndOrderFront : nil ];
	[ self.openGLWindow setAcceptsMouseMovedEvents : YES ];
	[ self.openGLWindow display ];
    
    ofNotifySetup();
    
    if( self.windowMode == OF_WINDOW )
    {
        [ self.openGLView startAnimation ];
    }
    else if( self.windowMode == OF_FULLSCREEN )
    {
        [ self.fullScreenView startAnimation ];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication 
{
	return YES;
}

- (BOOL)applicationShouldTerminate:(NSNotification*)n 
{
    if( self.windowMode == OF_FULLSCREEN )
        [ self.fullScreenView stopAnimation ];
    [ self.openGLView stopAnimation ];
}

- (void)dealloc 
{
    if( self.windowMode == OF_FULLSCREEN )
    {
        [ self.fullScreenView release ];
        [ self.fullScreenWindow release ];
        
        self.fullScreenView = nil;
        self.fullScreenWindow = nil;
    }
    
    [ self.openGLView release ];
    [ self.openGLWindow release ];
    
    self.openGLView = nil;
    self.openGLWindow = nil;
    
	[ super dealloc ];
}

- (void) goFullScreenOnAllDisplays
{
    NSRect displayRect = [ [ NSScreen mainScreen ] frame ];
    
    NSPoint tl, tr, br, bl;     // corners - top left, top right, bottom right, bottom left.
    
    if( [ [ NSScreen screens ] count ] > 1 )
    {
        tl.x = displayRect.origin.x;
        tl.y = displayRect.origin.y + displayRect.size.height;
        tr.x = displayRect.origin.x + displayRect.size.width;
        tr.y = displayRect.origin.y + displayRect.size.height;
        br.x = displayRect.origin.x + displayRect.size.width;
        br.y = displayRect.origin.y;
        bl.x = displayRect.origin.x;
        bl.y = displayRect.origin.y;
        
        for( int i=0; i<[ [ NSScreen screens ] count ]; i++ )
        {
            NSScreen *screen    = [ [ NSScreen screens ] objectAtIndex: i ];
            NSRect screenRect   = [ screen frame ];
            
            if( screenRect.origin.x    == displayRect.origin.x   &&
                screenRect.origin.y    == displayRect.origin.y   &&
                screenRect.size.width  == displayRect.size.width &&
                screenRect.size.height == displayRect.size.height )
                continue;
            
            if( tl.x > screenRect.origin.x )
                tl.x = screenRect.origin.x;
            
            if( tl.y < screenRect.origin.y + screenRect.size.height )
                tl.y = screenRect.origin.y + screenRect.size.height;
            
            if( tr.x < screenRect.origin.x + screenRect.size.width )
                tr.x = screenRect.origin.x + screenRect.size.width;
            
            if( tr.y < screenRect.origin.y + screenRect.size.height )
                tr.y = screenRect.origin.y + screenRect.size.height;
            
            if( br.x < screenRect.origin.x + screenRect.size.width )
                br.x = screenRect.origin.x + screenRect.size.width;
            
            if( br.y > screenRect.origin.y )
                br.y = screenRect.origin.y;
            
            if( bl.x > screenRect.origin.x )
                bl.x = screenRect.origin.x;
            
            if( bl.y > screenRect.origin.y )
                bl.y = screenRect.origin.y;
            
            displayRect.origin.x     = bl.x;
            displayRect.origin.y     = bl.y;
            displayRect.size.width   = tr.x - bl.x;
            displayRect.size.height  = tr.y - bl.y;
        }
    }

    [ self goFullScreen : displayRect ];
}

- (void) goFullScreenOnDisplay : (int)displayIndex
{
    if( displayIndex < 0 )
        displayIndex = 0;
    
    if( displayIndex > [ [ NSScreen screens ] count ] - 1 )
        displayIndex = [ [ NSScreen screens ] count ] - 1;
    
    NSScreen *screen    = [ [ NSScreen screens ] objectAtIndex: displayIndex ];
    NSRect displayRect  = [ screen frame ];
    
    [ self goFullScreen : displayRect ];
}

- (void) goFullScreen : (NSRect)displayRect;
{
    if( self.windowMode == OF_FULLSCREEN )
        return;
    
    self.windowMode = OF_FULLSCREEN;
    
	[ self.openGLView stopAnimation ];
	
	self.fullScreenWindow = [ [ NSWindow alloc ] initWithContentRect : displayRect 
                                                           styleMask : NSBorderlessWindowMask 
                                                             backing : NSBackingStoreBuffered 
                                                               defer : YES ];
	
	[ self.fullScreenWindow setLevel : NSMainMenuWindowLevel + 1 ];        // Set the window level to be above the menu bar
	[ self.fullScreenWindow setOpaque : YES ];
	[ self.fullScreenWindow setHidesOnDeactivate : YES ];
	
	// Create a view with a double-buffered OpenGL context and attach it to the window
	// By specifying the non-fullscreen context as the shareContext, we automatically inherit the OpenGL objects (textures, etc) it has defined
	NSRect viewRect = NSMakeRect( 0.0, 0.0, displayRect.size.width, displayRect.size.height );
	self.fullScreenView = [ [ GLView alloc ] initWithFrame : viewRect 
                                              shareContext : [ self.openGLView openGLContext ] ];
    
	[ self.fullScreenWindow setContentView : self.fullScreenView ];
	[ self.fullScreenWindow makeKeyAndOrderFront : self ];   // Show the window
	
    ofSetupScreen();
	
    [ self.fullScreenView startAnimation ];
}

- (void) goWindow
{
    if( self.windowMode == OF_WINDOW )
        return;
    
    self.windowMode = OF_WINDOW;
    
    [ self.fullScreenView stopAnimation ];
    
	[ self.fullScreenWindow release ];
	[ self.fullScreenView release ];
    
    self.fullScreenView     = nil;
    self.fullScreenWindow   = nil;
	
	[ [ self.openGLView openGLContext ] makeCurrentContext ];
	
    [ self.openGLView startAnimation ];
}

////////////////////////////////////////////////
//  ABSTRACTING WINDOW / VIEW MEMBERS.
////////////////////////////////////////////////

- (float) getFrameRate
{
    if( windowMode == OF_WINDOW )
        return [ self.openGLView frameRate ];
    else if( windowMode == OF_FULLSCREEN )
        return [ self.fullScreenView frameRate ];
}

- (double) getLastFrameTime
{
    if( windowMode == OF_WINDOW )
        return [ self.openGLView lastFrameTime ];
    else if( windowMode == OF_FULLSCREEN )
        return [ self.fullScreenView lastFrameTime ];
}

- (int) getFrameNum
{
    if( windowMode == OF_WINDOW )
        return [ self.openGLView nFrameCount ];
    else if( windowMode == OF_FULLSCREEN )
        return [ self.fullScreenView nFrameCount ];
}

- (NSRect) getViewFrame
{
    if( windowMode == OF_WINDOW )
        return [ self.openGLView frame ];
    else if( windowMode == OF_FULLSCREEN )
        return [ self.fullScreenView frame ];
}

- (NSRect) getWindowFrame
{
    if( windowMode == OF_WINDOW )
        return [ self.openGLWindow frame ];
    else if( windowMode == OF_FULLSCREEN )
        return [ self.fullScreenWindow frame ];
}

- (NSRect) getScreenFrame
{
    if( windowMode == OF_WINDOW )
        return [ [ self.openGLWindow screen ] frame ];
    else if( windowMode == OF_FULLSCREEN )
        return [ [ self.fullScreenWindow screen ] frame ];
}

- (void) setWindowPosition : (NSPoint)position
{
    if( windowMode == OF_FULLSCREEN )
        return;
    
    [ self.openGLWindow cascadeTopLeftFromPoint: position ];
}

- (void) setWindowShape : (NSRect)shape
{
    if( windowMode == OF_FULLSCREEN )
        return;

    [ self.openGLWindow setFrame : shape display : YES ];
}

- (void) enableSetupScreen
{
    if( windowMode == OF_WINDOW )
        self.openGLView.bEnableSetupScreen = true;
    else if( windowMode == OF_FULLSCREEN )
        self.fullScreenView.bEnableSetupScreen = true;
}

- (void) disableSetupScreen
{
    if( windowMode == OF_WINDOW )
        self.openGLView.bEnableSetupScreen = false;
    else if( windowMode == OF_FULLSCREEN )
        self.fullScreenView.bEnableSetupScreen = false;
}

@end