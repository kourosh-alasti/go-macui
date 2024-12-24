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

// Forward declare the callback
void handleToolbarItemClicked(void* toolbar, const char* identifier);

// Toolbar delegate to handle item clicks
@interface ToolbarDelegate : NSObject <NSToolbarDelegate>
@property (nonatomic, assign) void (*itemClickCallback)(void* toolbar, const char* identifier);
@property (nonatomic, strong) NSMutableArray* items;
@end

@implementation ToolbarDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        self.items = [NSMutableArray array];
    }
    return self;
}

- (void)toolbarItemClicked:(NSToolbarItem *)item {
    if (self.itemClickCallback) {
        const char* identifier = [item.itemIdentifier UTF8String];
        self.itemClickCallback((__bridge void*)item.toolbar, identifier);
    }
}

// Required NSToolbarDelegate methods
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    NSMutableArray* identifiers = [NSMutableArray array];
    for (NSToolbarItem* item in self.items) {
        [identifiers addObject:item.itemIdentifier];
    }
    return identifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    for (NSToolbarItem* item in self.items) {
        if ([item.itemIdentifier isEqualToString:itemIdentifier]) {
            // Set target and action on the item when it's being inserted
            [item setTarget:self];
            [item setAction:@selector(toolbarItemClicked:)];
            return item;
        }
    }
    return nil;
}

@end

void initApplication(void) {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];
}

void runApplication(void) {
    [NSApp run];
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

void endSheet(void* sheet, int response) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* nsSheet = (__bridge NSWindow*)sheet;
            [NSApp endSheet:nsSheet returnCode:response];
            [nsSheet orderOut:nil];
        });
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

typedef void (*dialog_callback_t)(void* dialog, int response);

void* createDialog(const char* title, const char* message, const char* informativeText) {
    __block NSAlert* alert = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        alert = [[NSAlert alloc] init];
        
        // Set titles and text
        if (title != NULL) {
            alert.messageText = [NSString stringWithUTF8String:title];
        }
        if (message != NULL) {
            alert.informativeText = [NSString stringWithUTF8String:message];
        }
        if (informativeText != NULL) {
            // Add additional text as a text view
            NSScrollView* scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 300, 100)];
            NSTextView* textView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
            [textView setString:[NSString stringWithUTF8String:informativeText]];
            [textView setEditable:NO];
            [textView setDrawsBackground:NO];
            [scrollView setDocumentView:textView];
            alert.accessoryView = scrollView;
        }
        
        // Add default buttons
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
    });
    
    return (void*)CFBridgingRetain(alert);
}

void runDialog(void* dialog, void* parentWindow, dialog_callback_t callback) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert* alert = (__bridge NSAlert*)dialog;
            NSWindow* parent = (__bridge NSWindow*)parentWindow;
            
            // Store callback for later use
            objc_setAssociatedObject(alert, "callback", [^(NSModalResponse response) {
                if (callback != NULL) {
                    callback(dialog, (int)response - NSAlertFirstButtonReturn);
                }
            } copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [alert beginSheetModalForWindow:parent completionHandler:^(NSModalResponse response) {
                void (^storedCallback)(NSModalResponse) = objc_getAssociatedObject(alert, "callback");
                if (storedCallback != nil) {
                    storedCallback(response);
                }
            }];
        });
    }
}

void setDialogButtonTitles(void* dialog, const char* okTitle, const char* cancelTitle, const char* otherTitle) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert* alert = (__bridge NSAlert*)dialog;
            NSArray* buttons = alert.buttons;
            
            // Set OK button title
            if (okTitle != NULL && buttons.count > 0) {
                [[buttons objectAtIndex:0] setTitle:[NSString stringWithUTF8String:okTitle]];
            }
            
            // Set Cancel button title
            if (cancelTitle != NULL && buttons.count > 1) {
                [[buttons objectAtIndex:1] setTitle:[NSString stringWithUTF8String:cancelTitle]];
            }
            
            // Add or update Other button
            if (otherTitle != NULL) {
                if (buttons.count > 2) {
                    [[buttons objectAtIndex:2] setTitle:[NSString stringWithUTF8String:otherTitle]];
                } else {
                    [alert addButtonWithTitle:[NSString stringWithUTF8String:otherTitle]];
                }
            }
        });
    }
}

void setDialogStyle(void* dialog, int style) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert* alert = (__bridge NSAlert*)dialog;
            switch (style) {
                case 0: // Warning
                    alert.alertStyle = NSAlertStyleWarning;
                    break;
                case 1: // Informational
                    alert.alertStyle = NSAlertStyleInformational;
                    break;
                case 2: // Critical
                    alert.alertStyle = NSAlertStyleCritical;
                    break;
            }
        });
    }
}

void setDialogIcon(void* dialog, int icon) {
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert* alert = (__bridge NSAlert*)dialog;
            NSImage* iconImage = nil;
            
            switch (icon) {
                case 0: // None
                    break;
                case 1: // Warning
                    iconImage = [NSImage imageWithSystemSymbolName:@"exclamationmark.triangle" accessibilityDescription:nil];
                    break;
                case 2: // Information
                    iconImage = [NSImage imageWithSystemSymbolName:@"info.circle" accessibilityDescription:nil];
                    break;
                case 3: // Error
                    iconImage = [NSImage imageWithSystemSymbolName:@"xmark.octagon" accessibilityDescription:nil];
                    break;
                case 4: // Question
                    iconImage = [NSImage imageWithSystemSymbolName:@"questionmark.circle" accessibilityDescription:nil];
                    break;
            }
            
            if (iconImage != nil) {
                alert.icon = iconImage;
            }
        });
    }
}

void* createToolbar(const char* identifier) {
    @autoreleasepool {
        NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:[NSString stringWithUTF8String:identifier]];
        
        // Create and set delegate
        ToolbarDelegate* delegate = [[ToolbarDelegate alloc] init];
        delegate.itemClickCallback = handleToolbarItemClicked;
        [toolbar setDelegate:delegate];
        
        // Store delegate with toolbar
        objc_setAssociatedObject(toolbar, "delegate", delegate, OBJC_ASSOCIATION_RETAIN);
        
        // Manually retain the toolbar since we're not using ARC
        CFRetain((__bridge CFTypeRef)toolbar);
        return (__bridge void*)toolbar;
    }
}

void* createToolbarItem(const char* identifier, const char* label, const char* image, const char* tooltip) {
    @autoreleasepool {
        NSString* nsIdentifier = [NSString stringWithUTF8String:identifier];
        NSToolbarItem* item = [[NSToolbarItem alloc] initWithItemIdentifier:nsIdentifier];
        
        // Set label and tooltip
        [item setLabel:[NSString stringWithUTF8String:label]];
        [item setPaletteLabel:[NSString stringWithUTF8String:label]];
        [item setToolTip:[NSString stringWithUTF8String:tooltip]];
        
        // Set image if provided
        if (image != NULL && strlen(image) > 0) {
            if (@available(macOS 11.0, *)) {
                NSString* imageName = [NSString stringWithUTF8String:image];
                NSImage* nsImage = [NSImage imageWithSystemSymbolName:imageName accessibilityDescription:nil];
                if (nsImage != nil) {
                    NSImageSymbolConfiguration* config = [NSImageSymbolConfiguration configurationWithHierarchicalColor:[NSColor labelColor]];
                    NSImage* configuredImage = [nsImage imageWithSymbolConfiguration:config];
                    [item setImage:configuredImage];
                }
            }
        }
        
        // Note: We'll set target and action when the item is actually inserted into the toolbar
        
        // Manually retain the item since we're not using ARC
        CFRetain((__bridge CFTypeRef)item);
        return (__bridge void*)item;
    }
}

void addToolbarItem(void* toolbar, void* item) {
    @autoreleasepool {
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        NSToolbarItem* nsItem = (__bridge NSToolbarItem*)item;
        
        // Get delegate and add item to its items array
        ToolbarDelegate* delegate = objc_getAssociatedObject(nsToolbar, "delegate");
        if (delegate) {
            [delegate.items addObject:nsItem];
            
            // Update toolbar items using modern API
            NSMutableArray* identifiers = [NSMutableArray array];
            for (NSToolbarItem* item in delegate.items) {
                [identifiers addObject:item.itemIdentifier];
            }
            [nsToolbar setItemIdentifiers:identifiers];
        }
    }
}

void removeToolbarItem(void* toolbar, const char* identifier) {
    @autoreleasepool {
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        NSString* nsIdentifier = [NSString stringWithUTF8String:identifier];
        
        // Get delegate and remove item from its items array
        ToolbarDelegate* delegate = objc_getAssociatedObject(nsToolbar, "delegate");
        if (delegate) {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"itemIdentifier == %@", nsIdentifier];
            NSArray* matchingItems = [delegate.items filteredArrayUsingPredicate:predicate];
            [delegate.items removeObjectsInArray:matchingItems];
            
            // Update toolbar items using modern API
            NSMutableArray* identifiers = [NSMutableArray array];
            for (NSToolbarItem* item in delegate.items) {
                [identifiers addObject:item.itemIdentifier];
            }
            [nsToolbar setItemIdentifiers:identifiers];
        }
    }
}

void setToolbarDisplayMode(void* toolbar, int mode) {
    @autoreleasepool {
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        [nsToolbar setDisplayMode:(NSToolbarDisplayMode)mode];
    }
}

void setToolbarSizeMode(void* toolbar, int mode) {
    @autoreleasepool {
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        [nsToolbar setSizeMode:(NSToolbarSizeMode)mode];
    }
}

void setToolbarAllowsUserCustomization(void* toolbar, bool allows) {
    @autoreleasepool {
        NSToolbar* nsToolbar = (__bridge NSToolbar*)toolbar;
        [nsToolbar setAllowsUserCustomization:allows];
    }
}

void setToolbarShowsBaselineSeparator(void* toolbar, bool shows) {
    // This method is deprecated in macOS 15.0, so we'll do nothing
}

void setToolbarItemColor(void* item, float r, float g, float b, float a) {
    @autoreleasepool {
        NSToolbarItem* nsItem = (__bridge NSToolbarItem*)item;
        if (@available(macOS 11.0, *)) {
            NSColor* color = [NSColor colorWithRed:r green:g blue:b alpha:a];
            NSImageSymbolConfiguration* config = [NSImageSymbolConfiguration configurationWithHierarchicalColor:color];
            NSImage* image = [nsItem.image imageWithSymbolConfiguration:config];
            [nsItem setImage:image];
            
            // Set label color using attributed string
            NSMutableAttributedString* attrLabel = [[NSMutableAttributedString alloc] initWithString:nsItem.label];
            [attrLabel addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attrLabel.length)];
            [nsItem setAttributedLabel:attrLabel];
        }
    }
}

void addSubview(void* window, void* view) {
    @autoreleasepool {
        NSWindow* nsWindow = (__bridge NSWindow*)window;
        NSView* nsView = (__bridge NSView*)view;
        [[nsWindow contentView] addSubview:nsView];
    }
}
