package base

import (
	"image"
)

// WindowStyle defines the visual style and behavior of a window
type WindowStyle uint

const (
	// WindowStyleDefault is a standard window with title bar and standard chrome
	WindowStyleDefault WindowStyle = iota

	// WindowStyleBorderless is a window without any chrome
	WindowStyleBorderless

	// WindowStylePanel is a utility window style
	WindowStylePanel

	// WindowStyleFloating is a window that stays on top
	WindowStyleFloating
)

// Window represents a native macOS window
type Window interface {
	View

	// Window specific methods
	Title() string
	SetTitle(title string)

	Style() WindowStyle
	SetStyle(style WindowStyle)

	// Window state
	IsMinimized() bool
	Minimize()
	Restore()

	IsMaximized() bool
	Maximize()

	IsClosed() bool
	Close()

	// Window size and position
	SetMinSize(size image.Point)
	SetMaxSize(size image.Point)

	Center()
	MoveToScreen(screen int)

	// Window content
	ContentView() View
	SetContentView(view View)
}

// BaseWindow provides a default implementation of the Window interface
type BaseWindow struct {
	*BaseView
	title       string
	style       WindowStyle
	minSize     image.Point
	maxSize     image.Point
	contentView View

	isMinimized bool
	isMaximized bool
	isClosed    bool
}

// NewWindow creates a new window with default style
func NewWindow(title string) *BaseWindow {
	w := &BaseWindow{
		BaseView: NewBaseView(),
		title:    title,
		style:    WindowStyleDefault,
		minSize:  image.Point{200, 100},   // Sensible defaults
		maxSize:  image.Point{4096, 4096}, // Large but not unlimited
	}
	return w
}

// Title returns the window title
func (w *BaseWindow) Title() string {
	return w.title
}

// SetTitle sets the window title
func (w *BaseWindow) SetTitle(title string) {
	w.title = title
	// TODO: Update native window title
}

// Style returns the window style
func (w *BaseWindow) Style() WindowStyle {
	return w.style
}

// SetStyle sets the window style
func (w *BaseWindow) SetStyle(style WindowStyle) {
	w.style = style
	// TODO: Update native window style
}

// IsMinimized returns whether the window is minimized
func (w *BaseWindow) IsMinimized() bool {
	return w.isMinimized
}

// Minimize minimizes the window
func (w *BaseWindow) Minimize() {
	w.isMinimized = true
	// TODO: Minimize native window
}

// Restore restores the window from minimized/maximized state
func (w *BaseWindow) Restore() {
	w.isMinimized = false
	w.isMaximized = false
	// TODO: Restore native window
}

// IsMaximized returns whether the window is maximized
func (w *BaseWindow) IsMaximized() bool {
	return w.isMaximized
}

// Maximize maximizes the window
func (w *BaseWindow) Maximize() {
	w.isMaximized = true
	// TODO: Maximize native window
}

// IsClosed returns whether the window is closed
func (w *BaseWindow) IsClosed() bool {
	return w.isClosed
}

// Close closes the window
func (w *BaseWindow) Close() {
	w.isClosed = true
	// TODO: Close native window
}

// SetMinSize sets the minimum window size
func (w *BaseWindow) SetMinSize(size image.Point) {
	w.minSize = size
	// TODO: Update native window constraints
}

// SetMaxSize sets the maximum window size
func (w *BaseWindow) SetMaxSize(size image.Point) {
	w.maxSize = size
	// TODO: Update native window constraints
}

// Center centers the window on the current screen
func (w *BaseWindow) Center() {
	// TODO: Center native window
}

// MoveToScreen moves the window to the specified screen
func (w *BaseWindow) MoveToScreen(screen int) {
	// TODO: Move native window to screen
}

// ContentView returns the window's content view
func (w *BaseWindow) ContentView() View {
	return w.contentView
}

// SetContentView sets the window's content view
func (w *BaseWindow) SetContentView(view View) {
	if w.contentView != nil {
		w.RemoveChild(w.contentView)
	}
	w.contentView = view
	if view != nil {
		w.AddChild(view)
	}
	// TODO: Update native window content
}
