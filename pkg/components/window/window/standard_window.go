package window

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

// Window callback function types
typedef void (*window_will_close_callback)(void* window);
typedef void (*window_did_resize_callback)(void* window, int x, int y, int width, int height);
typedef void (*window_did_move_callback)(void* window, int x, int y);
typedef void (*window_did_become_key_callback)(void* window);
typedef void (*window_did_resign_key_callback)(void* window);
typedef void (*window_did_miniaturize_callback)(void* window);
typedef void (*window_did_deminiaturize_callback)(void* window);
typedef void (*window_did_enter_fullscreen_callback)(void* window);
typedef void (*window_did_exit_fullscreen_callback)(void* window);

void* createStandardWindow(const char* title, int x, int y, int width, int height);
void setWindowToolbar(void* window, void* toolbar);
void setWindowBackgroundColor(void* window, float r, float g, float b, float a);
void setWindowTitlebarAppearsTransparent(void* window, bool transparent);
void setWindowTitleVisibility(void* window, int visibility);
void setWindowToolbarStyle(void* window, int style);
void setWindowDelegate(void* window, 
    window_will_close_callback willCloseCallback,
    window_did_resize_callback didResizeCallback,
    window_did_move_callback didMoveCallback,
    window_did_become_key_callback didBecomeKeyCallback,
    window_did_resign_key_callback didResignKeyCallback,
    window_did_miniaturize_callback didMiniaturizeCallback,
    window_did_deminiaturize_callback didDeminiaturizeCallback,
    window_did_enter_fullscreen_callback didEnterFullScreenCallback,
    window_did_exit_fullscreen_callback didExitFullScreenCallback);
void setWindowCollectionBehavior(void* window, unsigned long long behavior);
void setWindowStyleMask(void* window, unsigned long long mask);
void setWindowLevel(void* window, int level);
void setWindowAlphaValue(void* window, float alpha);
void setWindowOpaque(void* window, bool opaque);
void setWindowHasShadow(void* window, bool hasShadow);
void setWindowIgnoresMouseEvents(void* window, bool ignores);
void toggleWindowFullScreen(void* window);
void addSubview(void* window, void* view);

// Callback functions implemented in Go
extern void handleWindowWillClose(void* window);
extern void handleWindowDidResize(void* window, int x, int y, int width, int height);
extern void handleWindowDidMove(void* window, int x, int y);
extern void handleWindowDidBecomeKey(void* window);
extern void handleWindowDidResignKey(void* window);
extern void handleWindowDidMiniaturize(void* window);
extern void handleWindowDidDeminiaturize(void* window);
extern void handleWindowDidEnterFullScreen(void* window);
extern void handleWindowDidExitFullScreen(void* window);
*/
import "C"
import (
	"image"
	"image/color"
	"sync"
	"unsafe"

	"github.com/kourosh/gomacui/pkg/components"
)

// Global map to store window instances
var (
	windowMap = make(map[unsafe.Pointer]*StandardWindow)
	windowMutex sync.RWMutex
)

// getWindow retrieves the window instance from the pointer
func getWindow(ptr unsafe.Pointer) *StandardWindow {
	windowMutex.RLock()
	defer windowMutex.RUnlock()
	return windowMap[ptr]
}

// registerWindow registers a window instance with its pointer
func registerWindow(ptr unsafe.Pointer, window *StandardWindow) {
	windowMutex.Lock()
	defer windowMutex.Unlock()
	windowMap[ptr] = window
}

// unregisterWindow removes a window instance from the map
func unregisterWindow(ptr unsafe.Pointer) {
	windowMutex.Lock()
	defer windowMutex.Unlock()
	delete(windowMap, ptr)
}

// TitlebarStyle defines how the window's titlebar should appear
type TitlebarStyle int

const (
	TitlebarStyleDefault TitlebarStyle = iota
	TitlebarStyleHidden
	TitlebarStyleTransparent
	TitlebarStyleUnified // Big Sur+ unified style
)

// ToolbarStyle defines how the window's toolbar should appear
type ToolbarStyle int

const (
	ToolbarStyleAutomatic ToolbarStyle = iota
	ToolbarStyleExpanded
	ToolbarStylePreference
	ToolbarStyleUnified
	ToolbarStyleUnifiedCompact
)

// WindowLevel represents the window's level in the window hierarchy
type WindowLevel int

const (
	WindowLevelNormal WindowLevel = iota
	WindowLevelFloating
	WindowLevelTornOff
	WindowLevelModal
	WindowLevelMainMenu
	WindowLevelPopUp
	WindowLevelScreenSaver
)

// CollectionBehavior represents the window's collection behavior
type CollectionBehavior uint64

const (
	CollectionBehaviorDefault CollectionBehavior = 0
	CollectionBehaviorCanJoinAllSpaces CollectionBehavior = 1 << 0
	CollectionBehaviorMoveToActiveSpace CollectionBehavior = 1 << 1
	CollectionBehaviorManaged CollectionBehavior = 1 << 2
	CollectionBehaviorTransient CollectionBehavior = 1 << 3
	CollectionBehaviorStationary CollectionBehavior = 1 << 4
	CollectionBehaviorParticipatesInCycle CollectionBehavior = 1 << 5
	CollectionBehaviorIgnoresCycle CollectionBehavior = 1 << 6
	CollectionBehaviorFullScreenPrimary CollectionBehavior = 1 << 7
	CollectionBehaviorFullScreenAuxiliary CollectionBehavior = 1 << 8
	CollectionBehaviorFullScreenNone CollectionBehavior = 1 << 9
	CollectionBehaviorFullScreenAllowsTiling CollectionBehavior = 1 << 11
	CollectionBehaviorFullScreenDisallowsTiling CollectionBehavior = 1 << 12
)

// WindowEventHandler represents a handler for window events
type WindowEventHandler interface {
	OnWillClose()
	OnDidResize(frame image.Rectangle)
	OnDidMove(point image.Point)
	OnDidBecomeKey()
	OnDidResignKey()
	OnDidMiniaturize()
	OnDidDeminiaturize()
	OnDidEnterFullScreen()
	OnDidExitFullScreen()
}

// StandardWindow represents a standard macOS window with additional features
type StandardWindow struct {
	*NativeWindow
	titlebarStyle   TitlebarStyle
	toolbarStyle    ToolbarStyle
	backgroundColor color.Color
	eventHandler    WindowEventHandler
	eventMutex      sync.RWMutex
	toolbar         *Toolbar
}

// NewStandardWindow creates a new standard window
func NewStandardWindow(title string) *StandardWindow {
	// Create base window without native window
	base := &NativeWindow{
		BaseWindow: components.NewWindow(title),
	}

	w := &StandardWindow{
		NativeWindow:    base,
		titlebarStyle:   TitlebarStyleDefault,
		toolbarStyle:    ToolbarStyleAutomatic,
		backgroundColor: color.White,
	}

	// Create native window
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))

	frame := w.Frame()
	w.nsWindow = C.createStandardWindow(
		cTitle,
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
	)

	// Register window instance
	registerWindow(w.nsWindow, w)

	// Set default appearance
	w.SetTitlebarStyle(TitlebarStyleUnified)
	w.SetToolbarStyle(ToolbarStyleUnified)
	w.SetBackgroundColor(color.White)

	// Set up event handling
	w.setupEventHandling()

	return w
}

// Close closes the window and cleans up resources
func (w *StandardWindow) Close() {
	if w.nsWindow != nil {
		unregisterWindow(w.nsWindow)
		w.NativeWindow.Close()
	}
}

// SetEventHandler sets the window's event handler
func (w *StandardWindow) SetEventHandler(handler WindowEventHandler) {
	w.eventMutex.Lock()
	w.eventHandler = handler
	w.eventMutex.Unlock()
}

//export handleWindowWillClose
func handleWindowWillClose(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnWillClose()
		}
	}
}

//export handleWindowDidResize
func handleWindowDidResize(window unsafe.Pointer, x, y, width, height C.int) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidResize(image.Rect(int(x), int(y), int(x+width), int(y+height)))
		}
	}
}

//export handleWindowDidMove
func handleWindowDidMove(window unsafe.Pointer, x, y C.int) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidMove(image.Point{int(x), int(y)})
		}
	}
}

//export handleWindowDidBecomeKey
func handleWindowDidBecomeKey(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidBecomeKey()
		}
	}
}

//export handleWindowDidResignKey
func handleWindowDidResignKey(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidResignKey()
		}
	}
}

//export handleWindowDidMiniaturize
func handleWindowDidMiniaturize(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidMiniaturize()
		}
	}
}

//export handleWindowDidDeminiaturize
func handleWindowDidDeminiaturize(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidDeminiaturize()
		}
	}
}

//export handleWindowDidEnterFullScreen
func handleWindowDidEnterFullScreen(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidEnterFullScreen()
		}
	}
}

//export handleWindowDidExitFullScreen
func handleWindowDidExitFullScreen(window unsafe.Pointer) {
	if w := getWindow(window); w != nil {
		w.eventMutex.RLock()
		handler := w.eventHandler
		w.eventMutex.RUnlock()
		if handler != nil {
			handler.OnDidExitFullScreen()
		}
	}
}

func (w *StandardWindow) setupEventHandling() {
	C.setWindowDelegate(w.nsWindow,
		(C.window_will_close_callback)(C.handleWindowWillClose),
		(C.window_did_resize_callback)(C.handleWindowDidResize),
		(C.window_did_move_callback)(C.handleWindowDidMove),
		(C.window_did_become_key_callback)(C.handleWindowDidBecomeKey),
		(C.window_did_resign_key_callback)(C.handleWindowDidResignKey),
		(C.window_did_miniaturize_callback)(C.handleWindowDidMiniaturize),
		(C.window_did_deminiaturize_callback)(C.handleWindowDidDeminiaturize),
		(C.window_did_enter_fullscreen_callback)(C.handleWindowDidEnterFullScreen),
		(C.window_did_exit_fullscreen_callback)(C.handleWindowDidExitFullScreen),
	)
}

// SetCollectionBehavior sets the window's collection behavior
func (w *StandardWindow) SetCollectionBehavior(behavior CollectionBehavior) {
	C.setWindowCollectionBehavior(w.nsWindow, C.ulonglong(behavior))
}

// SetLevel sets the window's level in the window hierarchy
func (w *StandardWindow) SetLevel(level WindowLevel) {
	C.setWindowLevel(w.nsWindow, C.int(level))
}

// SetAlpha sets the window's alpha value (transparency)
func (w *StandardWindow) SetAlpha(alpha float32) {
	C.setWindowAlphaValue(w.nsWindow, C.float(alpha))
}

// SetOpaque sets whether the window is opaque
func (w *StandardWindow) SetOpaque(opaque bool) {
	C.setWindowOpaque(w.nsWindow, C.bool(opaque))
}

// SetHasShadow sets whether the window has a shadow
func (w *StandardWindow) SetHasShadow(hasShadow bool) {
	C.setWindowHasShadow(w.nsWindow, C.bool(hasShadow))
}

// SetIgnoresMouseEvents sets whether the window ignores mouse events
func (w *StandardWindow) SetIgnoresMouseEvents(ignores bool) {
	C.setWindowIgnoresMouseEvents(w.nsWindow, C.bool(ignores))
}

// ToggleFullScreen toggles the window's full screen state
func (w *StandardWindow) ToggleFullScreen() {
	C.toggleWindowFullScreen(w.nsWindow)
}

// SetTitlebarStyle sets the window's titlebar style
func (w *StandardWindow) SetTitlebarStyle(style TitlebarStyle) {
	w.titlebarStyle = style

	switch style {
	case TitlebarStyleHidden:
		C.setWindowTitleVisibility(w.nsWindow, C.int(0))
	case TitlebarStyleTransparent:
		C.setWindowTitlebarAppearsTransparent(w.nsWindow, C.bool(true))
	case TitlebarStyleUnified:
		C.setWindowTitlebarAppearsTransparent(w.nsWindow, C.bool(true))
		C.setWindowTitleVisibility(w.nsWindow, C.int(1))
	default:
		C.setWindowTitlebarAppearsTransparent(w.nsWindow, C.bool(false))
		C.setWindowTitleVisibility(w.nsWindow, C.int(1))
	}
}

// SetToolbarStyle sets the window's toolbar style
func (w *StandardWindow) SetToolbarStyle(style ToolbarStyle) {
	w.toolbarStyle = style
	C.setWindowToolbarStyle(w.nsWindow, C.int(style))
}

// SetBackgroundColor sets the window's background color
func (w *StandardWindow) SetBackgroundColor(c color.Color) {
	w.backgroundColor = c
	r, g, b, a := c.RGBA()
	C.setWindowBackgroundColor(w.nsWindow,
		C.float(float64(r)/65535.0),
		C.float(float64(g)/65535.0),
		C.float(float64(b)/65535.0),
		C.float(float64(a)/65535.0),
	)
}

// SetToolbar sets the window's toolbar
func (w *StandardWindow) SetToolbar(toolbar *Toolbar) {
	w.toolbar = toolbar
	if toolbar != nil {
		C.setWindowToolbar(w.nsWindow, toolbar.nsToolbar)
	} else {
		C.setWindowToolbar(w.nsWindow, nil)
	}
}

// Toolbar returns the window's toolbar
func (w *StandardWindow) Toolbar() *Toolbar {
	return w.toolbar
}

// AddSubview adds a subview to the window's content view
func (w *StandardWindow) AddSubview(view interface{}) {
	if nsView, ok := view.(interface{ NativeView() unsafe.Pointer }); ok {
		C.addSubview(w.nsWindow, nsView.NativeView())
	}
}
