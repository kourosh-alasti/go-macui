package panel

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

void* createPanel(const char* title, int x, int y, int width, int height, bool isFloating);
void setPanelLevel(void* window, int level);
void setPanelBehavior(void* window, int behavior);
void setPanelCollectionBehavior(void* window, unsigned long behavior);
void setPanelStyleMask(void* window, unsigned long mask);
*/
import "C"
import (
	"image"
	"unsafe"

	"github.com/kourosh-alasti/gomacui/internal/base"
	native_window "github.com/kourosh-alasti/gomacui/pkg/components/window/window/native"
)

// PanelStyle defines the visual style and behavior of a panel window
type PanelStyle uint

const (
	// PanelStyleDefault is a standard utility panel
	PanelStyleDefault PanelStyle = iota

	// PanelStyleFloating is a panel that stays above regular windows
	PanelStyleFloating

	// PanelStyleHUD is a panel with HUD appearance (dark, translucent)
	PanelStyleHUD
)

// PanelBehavior defines how the panel interacts with other windows
type PanelBehavior uint

const (
	// PanelBehaviorNormal allows the panel to be hidden when the app is inactive
	PanelBehaviorNormal PanelBehavior = iota

	// PanelBehaviorCanJoinAllSpaces allows the panel to appear in all spaces
	PanelBehaviorCanJoinAllSpaces

	// PanelBehaviorStaysOnActiveSpace keeps the panel in the active space
	PanelBehaviorStaysOnActiveSpace

	// PanelBehaviorTransient makes the panel hide when clicking outside
	PanelBehaviorTransient
)

// Panel represents a utility window in macOS
type Panel struct {
	*native_window.NativeWindow
	style    PanelStyle
	behavior PanelBehavior
}

// NewPanel creates a new panel window
func NewPanel(title string, style PanelStyle) *Panel {
	// Create base window without native window
	base := &native_window.NativeWindow{
		BaseWindow: base.NewWindow(title),
	}

	p := &Panel{
		NativeWindow: base,
		style:        style,
		behavior:     PanelBehaviorNormal,
	}

	// Create native panel
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))

	frame := p.Frame()
	p.nsWindow = C.createPanel(
		cTitle,
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
		C.bool(style == PanelStyleFloating),
	)

	// Configure panel based on style
	p.applyStyle(style)

	return p
}

// SetStyle sets the panel's style
func (p *Panel) SetStyle(style PanelStyle) {
	p.style = style
	p.applyStyle(style)
}

// SetBehavior sets the panel's behavior
func (p *Panel) SetBehavior(behavior PanelBehavior) {
	p.behavior = behavior

	var collectionBehavior C.ulong
	switch behavior {
	case PanelBehaviorCanJoinAllSpaces:
		collectionBehavior = 1 << 1 // NSWindowCollectionBehaviorCanJoinAllSpaces
	case PanelBehaviorStaysOnActiveSpace:
		collectionBehavior = 1 << 4 // NSWindowCollectionBehaviorStaysOnActiveSpace
	case PanelBehaviorTransient:
		collectionBehavior = 1 << 5 // NSWindowCollectionBehaviorTransient
	}

	if collectionBehavior != 0 {
		C.setPanelCollectionBehavior(p.nsWindow, collectionBehavior)
	}
}

func (p *Panel) applyStyle(style PanelStyle) {
	switch style {
	case PanelStyleFloating:
		C.setPanelLevel(p.nsWindow, 3)    // NSFloatingWindowLevel
		C.setPanelBehavior(p.nsWindow, 1) // NSWindowBehaviorTransient
	case PanelStyleHUD:
		var mask C.ulong = 1 << 12 // NSWindowStyleMaskHUDWindow
		C.setPanelStyleMask(p.nsWindow, mask)
	}
}

// SetFrame overrides NativeWindow.SetFrame to maintain panel positioning
func (p *Panel) SetFrame(frame image.Rectangle) {
	p.NativeWindow.SetFrame(frame)

	// Reapply panel level if floating
	if p.style == PanelStyleFloating {
		C.setPanelLevel(p.nsWindow, 3) // NSFloatingWindowLevel
	}
}
