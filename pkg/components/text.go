package components

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Cocoa
#import <Cocoa/Cocoa.h>

void* createTextField(const char* text, int fontSize) {
    @autoreleasepool {
        NSTextField* field = [[NSTextField alloc] init];
        [field setBezeled:NO];
        [field setDrawsBackground:NO];
        [field setEditable:NO];
        [field setSelectable:NO];
        [field setStringValue:[NSString stringWithUTF8String:text]];
        [field setFont:[NSFont systemFontOfSize:fontSize]];
        [field setTextColor:[NSColor textColor]];
        [field sizeToFit];
        return (__bridge_retained void*)field;
    }
}

void setTextFieldString(void* ptr, const char* text) {
    @autoreleasepool {
        NSTextField* field = (__bridge NSTextField*)ptr;
        [field setStringValue:[NSString stringWithUTF8String:text]];
        [field sizeToFit];
    }
}

void setTextFieldFont(void* ptr, int fontSize) {
    @autoreleasepool {
        NSTextField* field = (__bridge NSTextField*)ptr;
        [field setFont:[NSFont systemFontOfSize:fontSize]];
        [field sizeToFit];
    }
}

void setTextFieldColor(void* ptr, float r, float g, float b, float a) {
    @autoreleasepool {
        NSTextField* field = (__bridge NSTextField*)ptr;
        [field setTextColor:[NSColor colorWithRed:r green:g blue:b alpha:a]];
    }
}

void getTextFieldSize(void* ptr, int* width, int* height) {
    @autoreleasepool {
        NSTextField* field = (__bridge NSTextField*)ptr;
        NSSize size = [field intrinsicContentSize];
        *width = (int)size.width;
        *height = (int)size.height;
    }
}

void setTextFieldFrame(void* ptr, int x, int y, int width, int height) {
    @autoreleasepool {
        NSTextField* field = (__bridge NSTextField*)ptr;
        NSRect frame = NSMakeRect(x, y, width, height);
        [field setFrame:frame];
        [field setNeedsDisplay:YES];
    }
}
*/
import "C"
import (
	"image"
	"image/color"
	"unsafe"
)

// Text represents a text label component
type Text struct {
	nsView unsafe.Pointer
	text   string
	size   int
	frame  image.Rectangle
	color  color.Color
}

// NewText creates a new text label
func NewText(text string) *Text {
	ctext := C.CString(text)
	defer C.free(unsafe.Pointer(ctext))

	t := &Text{
		text:   text,
		size:   12, // Default font size
		color:  color.White,
		nsView: C.createTextField(ctext, C.int(12)),
	}

	var width, height C.int
	C.getTextFieldSize(t.nsView, &width, &height)
	t.frame = image.Rect(0, 0, int(width), int(height))

	return t
}

// SetText sets the text content
func (t *Text) SetText(text string) {
	t.text = text
	ctext := C.CString(text)
	defer C.free(unsafe.Pointer(ctext))
	C.setTextFieldString(t.nsView, ctext)

	var width, height C.int
	C.getTextFieldSize(t.nsView, &width, &height)
	t.frame = image.Rect(t.frame.Min.X, t.frame.Min.Y, t.frame.Min.X+int(width), t.frame.Min.Y+int(height))
}

// SetFontSize sets the font size
func (t *Text) SetFontSize(size int) {
	t.size = size
	C.setTextFieldFont(t.nsView, C.int(size))

	var width, height C.int
	C.getTextFieldSize(t.nsView, &width, &height)
	t.frame = image.Rect(t.frame.Min.X, t.frame.Min.Y, t.frame.Min.X+int(width), t.frame.Min.Y+int(height))
}

// SetColor sets the text color
func (t *Text) SetColor(c color.Color) {
	t.color = c
	r, g, b, a := c.RGBA()
	C.setTextFieldColor(t.nsView,
		C.float(float64(r)/65535.0),
		C.float(float64(g)/65535.0),
		C.float(float64(b)/65535.0),
		C.float(float64(a)/65535.0),
	)
}

// Frame returns the current frame
func (t *Text) Frame() image.Rectangle {
	return t.frame
}

// SetFrame sets the frame and updates the native view
func (t *Text) SetFrame(frame image.Rectangle) {
	t.frame = frame
	C.setTextFieldFrame(t.nsView,
		C.int(frame.Min.X),
		C.int(frame.Min.Y),
		C.int(frame.Dx()),
		C.int(frame.Dy()),
	)
}

// MinSize returns the minimum size
func (t *Text) MinSize() image.Point {
	var width, height C.int
	C.getTextFieldSize(t.nsView, &width, &height)
	return image.Point{int(width), int(height)}
}

// PreferredSize returns the preferred size
func (t *Text) PreferredSize() image.Point {
	return t.MinSize()
}

// IsVisible returns whether the text is visible
func (t *Text) IsVisible() bool {
	return true
}

// NativeView returns the native NSView pointer
func (t *Text) NativeView() unsafe.Pointer {
	return t.nsView
}
