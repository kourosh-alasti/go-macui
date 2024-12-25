#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

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