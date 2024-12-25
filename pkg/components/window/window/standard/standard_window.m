#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

// Window delegate to handle events
@interface WindowDelegate : NSObject <NSWindowDelegate>
@property (nonatomic, assign) void (*windowWillCloseCallback)(void* window);
@property (nonatomic, assign) void (*windowDidResizeCallback)(void* window, int x, int y, int width, int height);
@property (nonatomic, assign) void (*windowDidMoveCallback)(void* window, int x, int y);
@property (nonatomic, assign) void (*windowDidBecomeKeyCallback)(void* window);
@property (nonatomic, assign) void (*windowDidResignKeyCallback)(void* window);
@property (nonatomic, assign) void (*windowDidMiniaturizeCallback)(void* window);
@property (nonatomic, assign) void (*windowDidDeminiaturizeCallback)(void* window);
@property (nonatomic, assign) void (*windowDidEnterFullScreenCallback)(void* window);
@property (nonatomic, assign) void (*windowDidExitFullScreenCallback)(void* window);
@end

@implementation WindowDelegate {
    void* _window;
}

- (id)initWithWindow:(void*)window {
    self = [super init];
    if (self) {
        _window = window;
    }
    return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    if (self.windowWillCloseCallback) {
        self.windowWillCloseCallback(_window);
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    NSWindow* window = notification.object;
    NSRect frame = window.frame;
    if (self.windowDidResizeCallback) {
        self.windowDidResizeCallback(_window, (int)frame.origin.x, (int)frame.origin.y, (int)frame.size.width, (int)frame.size.height);
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    NSWindow* window = notification.object;
    NSRect frame = window.frame;
    if (self.windowDidMoveCallback) {
        self.windowDidMoveCallback(_window, (int)frame.origin.x, (int)frame.origin.y);
    }
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    if (self.windowDidBecomeKeyCallback) {
        self.windowDidBecomeKeyCallback(_window);
    }
}

- (void)windowDidResignKey:(NSNotification *)notification {
    if (self.windowDidResignKeyCallback) {
        self.windowDidResignKeyCallback(_window);
    }
}

- (void)windowDidMiniaturize:(NSNotification *)notification {
    if (self.windowDidMiniaturizeCallback) {
        self.windowDidMiniaturizeCallback(_window);
    }
}

- (void)windowDidDeminiaturize:(NSNotification *)notification {
    if (self.windowDidDeminiaturizeCallback) {
        self.windowDidDeminiaturizeCallback(_window);
    }
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    if (self.windowDidEnterFullScreenCallback) {
        self.windowDidEnterFullScreenCallback(_window);
    }
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    if (self.windowDidExitFullScreenCallback) {
        self.windowDidExitFullScreenCallback(_window);
    }
}

@end

void* createStandardWindow(const char* title, int x, int y, int width, int height) {
    @autoreleasepool {
        NSWindow* window = [[NSWindow alloc]
            initWithContentRect:NSMakeRect(x, y, width, height)
            styleMask:NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable |
                     NSWindowStyleMaskResizable |
                     NSWindowStyleMaskUnifiedTitleAndToolbar
            backing:NSBackingStoreBuffered
            defer:NO];
            
        [window setTitle:[NSString stringWithUTF8String:title]];
        [window setReleasedWhenClosed:NO];
        
        // Set modern appearance
        if (@available(macOS 11.0, *)) {
            window.toolbarStyle = NSWindowToolbarStyleUnified;
        }
        
        // Create default toolbar
        NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconOnly];
        [window setToolbar:toolbar];
        
        // Create and set delegate
        WindowDelegate* delegate = [[WindowDelegate alloc] initWithWindow:(void*)window];
        [window setDelegate:delegate];
        objc_setAssociatedObject(window, "delegate", delegate, OBJC_ASSOCIATION_RETAIN);
        
        return (void*)CFBridgingRetain(window);
    }
}

void setWindowToolbar(void* window, void* toolbar) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        [nsWindow setToolbar:nsToolbar];
    }
}

void setWindowBackgroundColor(void* window, float r, float g, float b, float a) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        NSColor* color = [NSColor colorWithRed:r green:g blue:b alpha:a];
        [nsWindow setBackgroundColor:color];
    }
}

void setWindowTitlebarAppearsTransparent(void* window, bool transparent) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setTitlebarAppearsTransparent:transparent];
    }
}

void setWindowTitleVisibility(void* window, int visibility) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setTitleVisibility:(visibility == 0 ? NSWindowTitleHidden : NSWindowTitleVisible)];
    }
}

void setWindowToolbarStyle(void* window, int style) {
    @autoreleasepool {
        if (@available(macOS 11.0, *)) {
            NSWindow* nsWindow = (__bridge NSWindow*)window;
            switch (style) {
                case 0: // Automatic
                    nsWindow.toolbarStyle = NSWindowToolbarStyleAutomatic;
                    break;
                case 1: // Expanded
                    nsWindow.toolbarStyle = NSWindowToolbarStyleExpanded;
                    break;
                case 2: // Preference
                    nsWindow.toolbarStyle = NSWindowToolbarStylePreference;
                    break;
                case 3: // Unified
                    nsWindow.toolbarStyle = NSWindowToolbarStyleUnified;
                    break;
                case 4: // UnifiedCompact
                    nsWindow.toolbarStyle = NSWindowToolbarStyleUnifiedCompact;
                    break;
            }
        }
    }
}

void setWindowDelegate(void* window, 
    void (*willCloseCallback)(void*),
    void (*didResizeCallback)(void*, int, int, int, int),
    void (*didMoveCallback)(void*, int, int),
    void (*didBecomeKeyCallback)(void*),
    void (*didResignKeyCallback)(void*),
    void (*didMiniaturizeCallback)(void*),
    void (*didDeminiaturizeCallback)(void*),
    void (*didEnterFullScreenCallback)(void*),
    void (*didExitFullScreenCallback)(void*)) {
    
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        WindowDelegate* delegate = objc_getAssociatedObject(nsWindow, "delegate");
        if (delegate) {
            delegate.windowWillCloseCallback = willCloseCallback;
            delegate.windowDidResizeCallback = didResizeCallback;
            delegate.windowDidMoveCallback = didMoveCallback;
            delegate.windowDidBecomeKeyCallback = didBecomeKeyCallback;
            delegate.windowDidResignKeyCallback = didResignKeyCallback;
            delegate.windowDidMiniaturizeCallback = didMiniaturizeCallback;
            delegate.windowDidDeminiaturizeCallback = didDeminiaturizeCallback;
            delegate.windowDidEnterFullScreenCallback = didEnterFullScreenCallback;
            delegate.windowDidExitFullScreenCallback = didExitFullScreenCallback;
        }
    }
}

void setWindowCollectionBehavior(void* window, unsigned long long behavior) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setCollectionBehavior:behavior];
    }
}

void setWindowStyleMask(void* window, unsigned long long mask) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setStyleMask:mask];
    }
}

void setWindowLevel(void* window, int level) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setLevel:level];
    }
}

void setWindowAlphaValue(void* window, float alpha) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setAlphaValue:alpha];
    }
}

void setWindowOpaque(void* window, bool opaque) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setOpaque:opaque];
    }
}

void setWindowHasShadow(void* window, bool hasShadow) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setHasShadow:hasShadow];
    }
}

void setWindowIgnoresMouseEvents(void* window, bool ignores) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setIgnoresMouseEvents:ignores];
    }
}

void toggleWindowFullScreen(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow toggleFullScreen:nil];
    }
}

void addSubview(void* window, void* view) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        NSView* nsView = (__bridge NSView*)view;
        [[nsWindow contentView] addSubview:nsView];
    }
}