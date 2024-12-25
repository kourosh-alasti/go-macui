package toolbar

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

void* createToolbar(const char* identifier);
void* createToolbarItem(const char* identifier, const char* label, const char* image, const char* tooltip);
void addToolbarItem(void* toolbar, void* item);
void removeToolbarItem(void* toolbar, const char* identifier);
void setToolbarDisplayMode(void* toolbar, int mode);
void setToolbarSizeMode(void* toolbar, int mode);
void setToolbarAllowsUserCustomization(void* toolbar, bool allows);
void setToolbarShowsBaselineSeparator(void* toolbar, bool shows);
void setToolbarItemColor(void* item, float r, float g, float b, float a);
*/
import "C"
import (
	"image/color"
	"sync"
	"unsafe"
)

// ToolbarDisplayMode defines how toolbar items are displayed
type ToolbarDisplayMode int

const (
	ToolbarDisplayModeDefault ToolbarDisplayMode = iota
	ToolbarDisplayModeIconAndLabel
	ToolbarDisplayModeIconOnly
	ToolbarDisplayModeLabelOnly
)

// ToolbarSizeMode defines the size of toolbar items
type ToolbarSizeMode int

const (
	ToolbarSizeModeDefault ToolbarSizeMode = iota
	ToolbarSizeModeRegular
	ToolbarSizeModeSmall
)

// ToolbarItemCallback is called when a toolbar item is clicked
type ToolbarItemCallback func()

// ToolbarItem represents a toolbar item
type ToolbarItem struct {
	nsItem   unsafe.Pointer
	callback ToolbarItemCallback
	label    string
	image    string
	tooltip  string
	tag      int
}

// Toolbar represents a window toolbar
type Toolbar struct {
	nsToolbar unsafe.Pointer
	items     map[string]*ToolbarItem
	mutex     sync.RWMutex
}

// NewToolbar creates a new toolbar
func NewToolbar(identifier string) *Toolbar {
	cIdentifier := C.CString(identifier)
	defer C.free(unsafe.Pointer(cIdentifier))

	toolbar := &Toolbar{
		nsToolbar: C.createToolbar(cIdentifier),
		items:     make(map[string]*ToolbarItem),
	}

	registerToolbar(toolbar.nsToolbar, toolbar)

	return toolbar
}

// AddItem adds a new item to the toolbar
func (t *Toolbar) AddItem(identifier, label, image, tooltip string, callback ToolbarItemCallback) *ToolbarItem {
	t.mutex.Lock()
	defer t.mutex.Unlock()

	cIdentifier := C.CString(identifier)
	defer C.free(unsafe.Pointer(cIdentifier))
	cLabel := C.CString(label)
	defer C.free(unsafe.Pointer(cLabel))
	cImage := C.CString(image)
	defer C.free(unsafe.Pointer(cImage))
	cTooltip := C.CString(tooltip)
	defer C.free(unsafe.Pointer(cTooltip))

	nsItem := C.createToolbarItem(cIdentifier, cLabel, cImage, cTooltip)

	item := &ToolbarItem{
		nsItem:   nsItem,
		callback: callback,
		label:    label,
		image:    image,
		tooltip:  tooltip,
	}

	t.items[identifier] = item
	C.addToolbarItem(t.nsToolbar, nsItem)

	return item
}

// RemoveItem removes an item from the toolbar
func (t *Toolbar) RemoveItem(identifier string) {
	t.mutex.Lock()
	defer t.mutex.Unlock()

	if _, exists := t.items[identifier]; exists {
		cIdentifier := C.CString(identifier)
		defer C.free(unsafe.Pointer(cIdentifier))

		C.removeToolbarItem(t.nsToolbar, cIdentifier)
		delete(t.items, identifier)
		// Note: NSToolbarItem is autoreleased by ARC
	}
}

// SetDisplayMode sets how toolbar items are displayed
func (t *Toolbar) SetDisplayMode(mode ToolbarDisplayMode) {
	C.setToolbarDisplayMode(t.nsToolbar, C.int(mode))
}

// SetSizeMode sets the size of toolbar items
func (t *Toolbar) SetSizeMode(mode ToolbarSizeMode) {
	C.setToolbarSizeMode(t.nsToolbar, C.int(mode))
}

// SetAllowsUserCustomization sets whether the user can customize the toolbar
func (t *Toolbar) SetAllowsUserCustomization(allows bool) {
	C.setToolbarAllowsUserCustomization(t.nsToolbar, C.bool(allows))
}

// SetShowsBaselineSeparator sets whether the toolbar shows a baseline separator
func (t *Toolbar) SetShowsBaselineSeparator(shows bool) {
	C.setToolbarShowsBaselineSeparator(t.nsToolbar, C.bool(shows))
}

// SetColor sets the color of the toolbar item's icon and label
func (item *ToolbarItem) SetColor(color color.Color) {
	r, g, b, a := color.RGBA()
	C.setToolbarItemColor(item.nsItem,
		C.float(float64(r)/65535.0),
		C.float(float64(g)/65535.0),
		C.float(float64(b)/65535.0),
		C.float(float64(a)/65535.0),
	)
}

//export handleToolbarItemClicked
func handleToolbarItemClicked(toolbarPtr unsafe.Pointer, itemIdentifier *C.char) {
	// Get toolbar instance
	toolbar := getToolbar(toolbarPtr)
	if toolbar == nil {
		return
	}

	// Get item identifier
	identifier := C.GoString(itemIdentifier)

	// Find and execute callback
	toolbar.mutex.RLock()
	if item, exists := toolbar.items[identifier]; exists && item.callback != nil {
		toolbar.mutex.RUnlock()
		item.callback()
	} else {
		toolbar.mutex.RUnlock()
	}
}

// Global map to store toolbar instances
var (
	toolbarMap   = make(map[unsafe.Pointer]*Toolbar)
	toolbarMutex sync.RWMutex
)

// getToolbar retrieves the toolbar instance from the pointer
func getToolbar(ptr unsafe.Pointer) *Toolbar {
	toolbarMutex.RLock()
	defer toolbarMutex.RUnlock()
	return toolbarMap[ptr]
}

// registerToolbar registers a toolbar instance with its pointer
func registerToolbar(ptr unsafe.Pointer, toolbar *Toolbar) {
	toolbarMutex.Lock()
	defer toolbarMutex.Unlock()
	toolbarMap[ptr] = toolbar
}

// unregisterToolbar removes a toolbar instance from the map
func unregisterToolbar(ptr unsafe.Pointer) {
	toolbarMutex.Lock()
	defer toolbarMutex.Unlock()
	delete(toolbarMap, ptr)
}
