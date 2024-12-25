package sheet

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

typedef void (*sheet_callback_t)(void* sheet, int response);
extern void handleSheetResponse(void* sheet, int response);

void* createSheet(const char* title, int width, int height);
void beginSheet(void* sheet, void* parentWindow, sheet_callback_t callback);
void endSheet(void* sheet, int response);
void setSheetContentView(void* sheet, void* contentView);
void setSheetButtonTitles(void* sheet, const char* okTitle, const char* cancelTitle);
*/
import "C"
import (
	"image"
	"runtime"
	"sync"
	"unsafe"

	"github.com/kourosh-alasti/gomacui/internal/base"
	native_window "github.com/kourosh-alasti/gomacui/pkg/components/window/window/native"
)

// SheetResponse represents the user's response to a sheet
type SheetResponse int

const (
	// SheetResponseCancel indicates the sheet was cancelled
	SheetResponseCancel SheetResponse = iota
	// SheetResponseOK indicates the sheet was accepted
	SheetResponseOK
)

// SheetCallback is called when the sheet is dismissed
type SheetCallback func(response SheetResponse)

// Sheet represents a window-attached sheet
type Sheet struct {
	*native_window.NativeWindow
	parentWindow *native_window.NativeWindow
	callback     SheetCallback
	isPresented  bool
}

var (
	// Global map to store callbacks
	sheetCallbacks   = make(map[unsafe.Pointer]SheetCallback)
	sheetCallbacksMu sync.Mutex
)

//export handleSheetResponse
func handleSheetResponse(sheet unsafe.Pointer, response C.int) {
	sheetCallbacksMu.Lock()
	callback, ok := sheetCallbacks[sheet]
	if ok {
		delete(sheetCallbacks, sheet)
	}
	sheetCallbacksMu.Unlock()

	if callback != nil {
		callback(SheetResponse(response))
	}
}

// NewSheet creates a new sheet window
func NewSheet(title string, parent *native_window.NativeWindow) *Sheet {
	// Create base window without native window
	base := &native_window.NativeWindow{
		BaseWindow: base.NewWindow(title),
	}

	s := &Sheet{
		NativeWindow: base,
		parentWindow: parent,
		isPresented:  false,
	}

	// Create native sheet
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))

	// Default size for sheets
	defaultSize := image.Point{500, 300}
	s.nsWindow = C.createSheet(
		cTitle,
		C.int(defaultSize.X),
		C.int(defaultSize.Y),
	)

	// Ensure the sheet is not deallocated while Go code is running
	runtime.SetFinalizer(s, (*Sheet).finalize)

	return s
}

// finalize ensures proper cleanup
func (s *Sheet) finalize() {
	if s.isPresented {
		s.Dismiss(SheetResponseCancel)
	}

	sheetCallbacksMu.Lock()
	delete(sheetCallbacks, s.nsWindow)
	sheetCallbacksMu.Unlock()
}

// Present shows the sheet attached to its parent window
func (s *Sheet) Present(callback SheetCallback) {
	if s.isPresented {
		return
	}

	s.callback = callback
	s.isPresented = true

	if callback != nil {
		sheetCallbacksMu.Lock()
		sheetCallbacks[s.nsWindow] = callback
		sheetCallbacksMu.Unlock()
	}

	C.beginSheet(s.nsWindow, s.parentWindow.nsWindow, C.sheet_callback_t(C.handleSheetResponse))
}

// Dismiss closes the sheet with the given response
func (s *Sheet) Dismiss(response SheetResponse) {
	if !s.isPresented {
		return
	}

	s.isPresented = false
	C.endSheet(s.nsWindow, C.int(response))
}

// IsPresented returns whether the sheet is currently being shown
func (s *Sheet) IsPresented() bool {
	return s.isPresented
}

// SetSize sets the sheet's size. This should be called before presenting the sheet.
func (s *Sheet) SetSize(size image.Point) {
	s.SetFrame(image.Rect(0, 0, size.X, size.Y))
}

// SetButtonTitles sets custom titles for the sheet's buttons
func (s *Sheet) SetButtonTitles(okTitle, cancelTitle string) {
	var cOkTitle, cCancelTitle *C.char
	if okTitle != "" {
		cOkTitle = C.CString(okTitle)
		defer C.free(unsafe.Pointer(cOkTitle))
	}
	if cancelTitle != "" {
		cCancelTitle = C.CString(cancelTitle)
		defer C.free(unsafe.Pointer(cCancelTitle))
	}

	C.setSheetButtonTitles(s.nsWindow, cOkTitle, cCancelTitle)
}

// SetContentView sets the main content view of the sheet
func (s *Sheet) SetContentView(view base.View) {
	if view == nil {
		return
	}

	C.setSheetContentView(s.nsWindow, unsafe.Pointer(view.Native()))
}
