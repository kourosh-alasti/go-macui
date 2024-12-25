package view

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#import <Cocoa/Cocoa.h>

void* createView(void);
void setViewFrame(void* view, int x, int y, int width, int height);
void setViewBackgroundColor(void* view, float r, float g, float b, float a);
void setViewVisible(void* view, bool visible);
*/
import "C"
import (
	"image"
	"image/color"
	"runtime"
	"unsafe"

	"github.com/kourosh/gomacui/internal/base"
)

// View represents a basic view component
type View struct {
	*base.BaseView
	nsView unsafe.Pointer
}

// NewView creates a new view
func NewView() *View {
	v := &View{
		BaseView: base.NewBaseView(),
		nsView:   C.createView(),
	}

	// Ensure the view is not deallocated while Go code is running
	runtime.SetFinalizer(v, (*View).finalize)

	return v
}

// finalize ensures proper cleanup
func (v *View) finalize() {
	v.Cleanup()
	// The view will be released by the parent view or window
}

// Native returns the native view handle
func (v *View) Native() uintptr {
	return uintptr(v.nsView)
}

// SetFrame sets the view's frame rectangle
func (v *View) SetFrame(frame image.Rectangle) {
	v.BaseView.SetFrame(frame) // Update base frame
	C.setViewFrame(v.nsView,
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
	)
}

// SetVisible sets the view's visibility
func (v *View) SetVisible(visible bool) {
	v.BaseView.SetVisible(visible) // Update base visibility
	C.setViewVisible(v.nsView, C.bool(visible))
}

// SetBackgroundColor sets the view's background color
func (v *View) SetBackgroundColor(c color.Color) {
	r, g, b, a := c.RGBA()
	C.setViewBackgroundColor(v.nsView,
		C.float(float64(r)/65535.0),
		C.float(float64(g)/65535.0),
		C.float(float64(b)/65535.0),
		C.float(float64(a)/65535.0),
	)
}
