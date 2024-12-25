#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

void initApplication(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
}

void* createWindow(const char* title, int style, int x, int y, int width, int height) {
    @autoreleasepool {
        NSWindow* window = [[NSWindow alloc]
            initWithContentRect:NSMakeRect(x, y, width, height)
            styleMask:NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable |
                     NSWindowStyleMaskResizable
            backing:NSBackingStoreBuffered
            defer:NO];
            
        [window setTitle:[NSString stringWithUTF8String:title]];
        [window setReleasedWhenClosed:NO];
        
        return (void*)CFBridgingRetain(window);
    }
}

void setWindowTitle(void* window, const char* title) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setTitle:[NSString stringWithUTF8String:title]];
    }
}

void showWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow makeKeyAndOrderFront:nil];
    }
}

void closeWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow close];
        CFBridgingRelease(window);
    }
}

void minimizeWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow miniaturize:nil];
    }
}

void maximizeWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow zoom:nil];
    }
}

void restoreWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        if ([nsWindow isMiniaturized]) {
            [nsWindow deminiaturize:nil];
        }
        if ([nsWindow isZoomed]) {
            [nsWindow zoom:nil];
        }
    }
}

void centerWindow(void* window) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow center];
    }
}

void setWindowFrame(void* window, int x, int y, int width, int height) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setFrame:NSMakeRect(x, y, width, height) display:YES animate:NO];
    }
}

void setWindowMinSize(void* window, int width, int height) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setMinSize:NSMakeSize(width, height)];
    }
}

void setWindowMaxSize(void* window, int width, int height) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        [nsWindow setMaxSize:NSMakeSize(width, height)];
    }
}

void runApplication(void) {
    [NSApp run];
}