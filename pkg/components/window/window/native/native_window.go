package window

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

void initApplication(void);
void* createWindow(const char* title, int style, int x, int y, int width, int height);
void setWindowTitle(void* window, const char* title);
void showWindow(void* window);
void closeWindow(void* window);
void minimizeWindow(void* window);
void maximizeWindow(void* window);
void restoreWindow(void* window);
void centerWindow(void* window);
void setWindowFrame(void* window, int x, int y, int width, int height);
void setWindowMinSize(void* window, int width, int height);
void setWindowMaxSize(void* window, int width, int height);
void runApplication(void);
*/
import "C"
import (
	"image"
	"unsafe"

	"github.com/kourosh-alasti/gomacui/internal/base"
)

// NativeWindow wraps a native macOS NSWindow
type NativeWindow struct {
	*base.BaseWindow
	nsWindow unsafe.Pointer
}

func init() {
	C.initApplication()
}

// NewNativeWindow creates a new native macOS window
func NewNativeWindow(title string) *NativeWindow {
	w := &NativeWindow{
		BaseWindow: base.NewWindow(title),
	}

	// Create native window
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))

	frame := w.Frame()
	w.nsWindow = C.createWindow(
		cTitle,
		C.int(w.Style()),
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
	)

	return w
}

// SetTitle overrides BaseWindow.SetTitle to update native window
func (w *NativeWindow) SetTitle(title string) {
	w.BaseWindow.SetTitle(title)
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))
	C.setWindowTitle(w.nsWindow, cTitle)
}

// Show makes the window visible
func (w *NativeWindow) Show() {
	C.showWindow(w.nsWindow)
}

// Close overrides BaseWindow.Close to close native window
func (w *NativeWindow) Close() {
	w.BaseWindow.Close()
	C.closeWindow(w.nsWindow)
}

// Minimize overrides BaseWindow.Minimize
func (w *NativeWindow) Minimize() {
	w.BaseWindow.Minimize()
	C.minimizeWindow(w.nsWindow)
}

// Maximize overrides BaseWindow.Maximize
func (w *NativeWindow) Maximize() {
	w.BaseWindow.Maximize()
	C.maximizeWindow(w.nsWindow)
}

// Restore overrides BaseWindow.Restore
func (w *NativeWindow) Restore() {
	w.BaseWindow.Restore()
	C.restoreWindow(w.nsWindow)
}

// Center overrides BaseWindow.Center
func (w *NativeWindow) Center() {
	w.BaseWindow.Center()
	C.centerWindow(w.nsWindow)
}

// SetFrame overrides BaseWindow.SetFrame
func (w *NativeWindow) SetFrame(frame image.Rectangle) {
	w.BaseWindow.SetFrame(frame)
	C.setWindowFrame(
		w.nsWindow,
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
	)
}

// SetMinSize overrides BaseWindow.SetMinSize
func (w *NativeWindow) SetMinSize(size image.Point) {
	w.BaseWindow.SetMinSize(size)
	C.setWindowMinSize(w.nsWindow, C.int(size.X), C.int(size.Y))
}

// SetMaxSize overrides BaseWindow.SetMaxSize
func (w *NativeWindow) SetMaxSize(size image.Point) {
	w.BaseWindow.SetMaxSize(size)
	C.setWindowMaxSize(w.nsWindow, C.int(size.X), C.int(size.Y))
}

// Run starts the application main loop
func Run() {
	C.runApplication()
}
