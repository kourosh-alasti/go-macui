#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

typedef void (*dialog_callback_t)(void* dialog, int response);
extern void handleDialogResponse(void* dialog, int response);

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