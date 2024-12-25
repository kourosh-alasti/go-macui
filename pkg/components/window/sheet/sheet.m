#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

typedef void (*sheet_callback_t)(void* sheet, int response);

void* createSheet(const char* title, int width, int height) {
    @autoreleasepool {
        NSWindow* sheet = [[NSWindow alloc]
            initWithContentRect:NSMakeRect(0, 0, width, height)
            styleMask:NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable
            backing:NSBackingStoreBuffered
            defer:NO];
            
        [sheet setTitle:[NSString stringWithUTF8String:title]];
        [sheet setReleasedWhenClosed:NO];
        
        // Configure for sheet presentation
        [sheet setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
        
        // Create buttons container view
        NSView* buttonsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, 60)];
        [buttonsView setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
        
        // Create Cancel button
        NSButton* cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(width - 180, 15, 80, 32)];
        [cancelButton setTitle:@"Cancel"];
        [cancelButton setBezelStyle:NSBezelStyleRounded];
        [cancelButton setAutoresizingMask:NSViewMinXMargin | NSViewMaxYMargin];
        [cancelButton setKeyEquivalent:@"\033"]; // Escape key
        [buttonsView addSubview:cancelButton];
        
        // Create OK button
        NSButton* okButton = [[NSButton alloc] initWithFrame:NSMakeRect(width - 90, 15, 80, 32)];
        [okButton setTitle:@"OK"];
        [okButton setBezelStyle:NSBezelStyleRounded];
        [okButton setKeyEquivalent:@"\r"]; // Return key
        [okButton setAutoresizingMask:NSViewMinXMargin | NSViewMaxYMargin];
        [buttonsView addSubview:okButton];
        
        // Create content view container
        NSView* contentContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 60, width, height - 60)];
        [contentContainer setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        
        // Setup main container
        NSView* container = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
        [container setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [container addSubview:contentContainer];
        [container addSubview:buttonsView];
        
        [sheet setContentView:container];
        
        // Store views as associated objects for later access
        objc_setAssociatedObject(sheet, "contentContainer", contentContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(sheet, "okButton", okButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(sheet, "cancelButton", cancelButton, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        return (void*)CFBridgingRetain(sheet);
    }
}

void beginSheet(void* sheet, void* parentWindow, void (*callback)(void* sheet, int response)) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* nsSheet = (__bridge NSWindow*)sheet;
            NSWindow* nsParent = (__bridge NSWindow*)parentWindow;
            
            // Get buttons
            NSButton* okButton = objc_getAssociatedObject(nsSheet, "okButton");
            NSButton* cancelButton = objc_getAssociatedObject(nsSheet, "cancelButton");
            
            // Setup button actions
            [okButton setTarget:NSApp];
            [okButton setAction:@selector(stopModalWithCode:)];
            [okButton setTag:1]; // OK response
            
            [cancelButton setTarget:NSApp];
            [cancelButton setAction:@selector(stopModalWithCode:)];
            [cancelButton setTag:0]; // Cancel response
            
            // Store callback for later use
            objc_setAssociatedObject(nsSheet, "callback", [^(NSModalResponse response) {
                if (callback != NULL) {
                    callback(sheet, (int)response);
                }
            } copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [nsParent beginSheet:nsSheet completionHandler:^(NSModalResponse response) {
                void (^storedCallback)(NSModalResponse) = objc_getAssociatedObject(nsSheet, "callback");
                if (storedCallback != nil) {
                    storedCallback(response);
                }
            }];
        });
    }
}

void endSheet(void* sheet, int response) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* nsSheet = (__bridge NSWindow*)sheet;
            [NSApp endSheet:nsSheet returnCode:response];
            [nsSheet orderOut:nil];
        });
    }
}

void setSheetContentView(void* sheet, void* contentView) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* nsSheet = (__bridge NSWindow*)sheet;
            NSView* container = objc_getAssociatedObject(nsSheet, "contentContainer");
            NSView* nsContentView = (__bridge NSView*)contentView;
            
            // Remove existing content views
            for (NSView* subview in [container subviews]) {
                [subview removeFromSuperview];
            }
            
            // Add new content view
            [nsContentView setFrame:[container bounds]];
            [nsContentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            [container addSubview:nsContentView];
        });
    }
}

void setSheetButtonTitles(void* sheet, const char* okTitle, const char* cancelTitle) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* nsSheet = (__bridge NSWindow*)sheet;
            NSButton* okButton = objc_getAssociatedObject(nsSheet, "okButton");
            NSButton* cancelButton = objc_getAssociatedObject(nsSheet, "cancelButton");
            
            if (okTitle != NULL) {
                [okButton setTitle:[NSString stringWithUTF8String:okTitle]];
            }
            if (cancelTitle != NULL) {
                [cancelButton setTitle:[NSString stringWithUTF8String:cancelTitle]];
            }
        });
    }
}