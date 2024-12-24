package layout

import (
	"image"
)

// StackView is a view that contains a layout
type StackView struct {
	layout Layout
	frame  image.Rectangle
	views  []View
}

// NewStackView creates a new stack view
func NewStackView(layout Layout) *StackView {
	return &StackView{
		layout: layout,
		views:  make([]View, 0),
	}
}

// AddView adds a view to the stack
func (s *StackView) AddView(view View) {
	s.views = append(s.views, view)
}

// Frame returns the current frame
func (s *StackView) Frame() image.Rectangle {
	return s.frame
}

// SetFrame sets the frame and triggers layout
func (s *StackView) SetFrame(frame image.Rectangle) {
	s.frame = frame
	s.Layout(frame)
}

// MinSize returns the minimum size
func (s *StackView) MinSize() image.Point {
	return s.layout.MinSize()
}

// PreferredSize returns the preferred size
func (s *StackView) PreferredSize() image.Point {
	return s.layout.PreferredSize()
}

// IsVisible returns whether the view is visible
func (s *StackView) IsVisible() bool {
	return true
}

// Layout performs layout of child views
func (s *StackView) Layout(bounds image.Rectangle) {
	s.frame = bounds
	s.layout.Layout(bounds)
	
	// Update frames of all views
	for _, view := range s.views {
		if frame := s.layout.ViewFrame(view); !frame.Empty() {
			view.SetFrame(frame)
		}
	}
}
