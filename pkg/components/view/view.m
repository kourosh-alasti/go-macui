#import <Cocoa/Cocoa.h>

void* createView(void) {
    @autoreleasepool {
        NSView* view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 100, 100)];
        [view setWantsLayer:YES]; // Enable layer-backed view for better performance
        return (void*)CFBridgingRetain(view);
    }
}

void setViewFrame(void* view, int x, int y, int width, int height) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSView* nsView = (__bridge NSView*)view;
            [nsView setFrame:NSMakeRect(x, y, width, height)];
        });
    }
}

void setViewVisible(void* view, bool visible) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSView* nsView = (__bridge NSView*)view;
            [nsView setHidden:!visible];
        });
    }
}

void setViewBackgroundColor(void* view, float r, float g, float b, float a) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSView* nsView = (__bridge NSView*)view;
            [nsView setWantsLayer:YES];
            nsView.layer.backgroundColor = [[NSColor colorWithRed:r green:g blue:b alpha:a] CGColor];
        });
    }
}
