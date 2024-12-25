#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

void* createPanel(const char* title, int x, int y, int width, int height, bool isFloating) {
    @autoreleasepool {
        NSPanel* panel = [[NSPanel alloc]
            initWithContentRect:NSMakeRect(x, y, width, height)
            styleMask:NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable |
                     NSWindowStyleMaskResizable |
                     NSWindowStyleMaskUtilityWindow
            backing:NSBackingStoreBuffered
            defer:NO];
            
        [panel setTitle:[NSString stringWithUTF8String:title]];
        [panel setReleasedWhenClosed:NO];
        [panel setBecomesKeyOnlyIfNeeded:YES];
        
        if (isFloating) {
            [panel setLevel:NSFloatingWindowLevel];
            [panel setHidesOnDeactivate:NO];
        }
        
        return (void*)CFBridgingRetain(panel);
    }
}

void setPanelLevel(void* window, int level) {
    @autoreleasepool {
        NSPanel* panel = (__bridge NSPanel*)window;
        [panel setLevel:level];
    }
}

void setPanelBehavior(void* window, int behavior) {
    @autoreleasepool {
        NSPanel* panel = (__bridge NSPanel*)window;
        [panel setBecomesKeyOnlyIfNeeded:(behavior == 1)];
        [panel setHidesOnDeactivate:(behavior != 1)];
    }
}

void setPanelCollectionBehavior(void* window, unsigned long behavior) {
    @autoreleasepool {
        NSPanel* panel = (__bridge NSPanel*)window;
        [panel setCollectionBehavior:behavior];
    }
}

void setPanelStyleMask(void* window, unsigned long mask) {
    @autoreleasepool {
        NSPanel* panel = (__bridge NSPanel*)window;
        [panel setStyleMask:([panel styleMask] | mask)];
    }
}