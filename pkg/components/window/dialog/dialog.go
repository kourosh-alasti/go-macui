package dialog

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#include <stdlib.h>
#import <Cocoa/Cocoa.h>

typedef void (*dialog_callback_t)(void* dialog, int response);
extern void handleDialogResponse(void* dialog, int response);

void* createDialog(const char* title, const char* message, const char* informativeText);
void runDialog(void* dialog, void* parentWindow, dialog_callback_t callback);
void setDialogButtonTitles(void* dialog, const char* okTitle, const char* cancelTitle, const char* otherTitle);
void setDialogStyle(void* dialog, int style);
void setDialogIcon(void* dialog, int icon);
*/
import "C"
import (
	"runtime"
	"sync"
	"unsafe"
)

// DialogStyle represents the style of the dialog
type DialogStyle int

const (
	// DialogStyleWarning displays a warning dialog
	DialogStyleWarning DialogStyle = iota
	// DialogStyleInformational displays an informational dialog
	DialogStyleInformational
	// DialogStyleCritical displays a critical dialog
	DialogStyleCritical
)

// DialogIcon represents the icon shown in the dialog
type DialogIcon int

const (
	// DialogIconNone shows no icon
	DialogIconNone DialogIcon = iota
	// DialogIconWarning shows a warning icon
	DialogIconWarning
	// DialogIconInformation shows an information icon
	DialogIconInformation
	// DialogIconError shows an error icon
	DialogIconError
	// DialogIconQuestion shows a question mark icon
	DialogIconQuestion
)

// DialogResponse represents the user's response to a dialog
type DialogResponse int

const (
	// DialogResponseCancel indicates the dialog was cancelled
	DialogResponseCancel DialogResponse = iota
	// DialogResponseOK indicates the dialog was accepted
	DialogResponseOK
	// DialogResponseOther indicates the third button was clicked
	DialogResponseOther
)

// DialogCallback is called when the dialog is dismissed
type DialogCallback func(response DialogResponse)

// Dialog represents a modal dialog window
type Dialog struct {
	nsDialog     unsafe.Pointer
	parentWindow *NativeWindow
	callback     DialogCallback
	style        DialogStyle
	icon         DialogIcon
	isPresented  bool
}

var (
	// Global map to store callbacks
	dialogCallbacks   = make(map[unsafe.Pointer]DialogCallback)
	dialogCallbacksMu sync.Mutex
)

//export handleDialogResponse
func handleDialogResponse(dialog unsafe.Pointer, response C.int) {
	dialogCallbacksMu.Lock()
	callback, ok := dialogCallbacks[dialog]
	if ok {
		delete(dialogCallbacks, dialog)
	}
	dialogCallbacksMu.Unlock()

	if callback != nil {
		callback(DialogResponse(response))
	}
}

// NewDialog creates a new dialog window
func NewDialog(title, message, informativeText string, parent *NativeWindow) *Dialog {
	cTitle := C.CString(title)
	defer C.free(unsafe.Pointer(cTitle))
	cMessage := C.CString(message)
	defer C.free(unsafe.Pointer(cMessage))
	cInformativeText := C.CString(informativeText)
	defer C.free(unsafe.Pointer(cInformativeText))

	d := &Dialog{
		nsDialog:     C.createDialog(cTitle, cMessage, cInformativeText),
		parentWindow: parent,
		style:        DialogStyleInformational,
		icon:         DialogIconNone,
		isPresented:  false,
	}

	// Ensure the dialog is not deallocated while Go code is running
	runtime.SetFinalizer(d, (*Dialog).finalize)

	return d
}

// finalize ensures proper cleanup
func (d *Dialog) finalize() {
	dialogCallbacksMu.Lock()
	delete(dialogCallbacks, d.nsDialog)
	dialogCallbacksMu.Unlock()
}

// SetStyle sets the dialog's style
func (d *Dialog) SetStyle(style DialogStyle) {
	d.style = style
	C.setDialogStyle(d.nsDialog, C.int(style))
}

// SetIcon sets the dialog's icon
func (d *Dialog) SetIcon(icon DialogIcon) {
	d.icon = icon
	C.setDialogIcon(d.nsDialog, C.int(icon))
}

// SetButtonTitles sets custom titles for the dialog's buttons
func (d *Dialog) SetButtonTitles(okTitle, cancelTitle, otherTitle string) {
	var cOkTitle, cCancelTitle, cOtherTitle *C.char
	if okTitle != "" {
		cOkTitle = C.CString(okTitle)
		defer C.free(unsafe.Pointer(cOkTitle))
	}
	if cancelTitle != "" {
		cCancelTitle = C.CString(cancelTitle)
		defer C.free(unsafe.Pointer(cCancelTitle))
	}
	if otherTitle != "" {
		cOtherTitle = C.CString(otherTitle)
		defer C.free(unsafe.Pointer(cOtherTitle))
	}

	C.setDialogButtonTitles(d.nsDialog, cOkTitle, cCancelTitle, cOtherTitle)
}

// Run displays the dialog modally and waits for user response
func (d *Dialog) Run(callback DialogCallback) {
	if d.isPresented {
		return
	}

	d.callback = callback
	d.isPresented = true

	if callback != nil {
		dialogCallbacksMu.Lock()
		dialogCallbacks[d.nsDialog] = callback
		dialogCallbacksMu.Unlock()
	}

	C.runDialog(d.nsDialog, d.parentWindow.nsWindow, C.dialog_callback_t(C.handleDialogResponse))
}
