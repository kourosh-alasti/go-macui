package layout

import (
	"image"
)

// Stack is the base type for all stack layouts
type Stack struct {
	items       []*LayoutItem
	spacing     float64
	alignment   Alignment
	distribution Distribution
}

// NewStack creates a new stack layout
func NewStack() *Stack {
	return &Stack{
		items:       make([]*LayoutItem, 0),
		spacing:     8, // Default spacing
		alignment:   AlignmentCenter,
		distribution: DistributionStart,
	}
}

// AddView adds a view to the stack
func (s *Stack) AddView(view View) {
	item := &LayoutItem{
		View:       view,
		MinSize:    view.MinSize(),
		MaxSize:    image.Point{X: 1<<31 - 1, Y: 1<<31 - 1},
		Alignment:  s.alignment,
		FlexGrow:   1.0,
		FlexShrink: 1.0,
	}
	s.items = append(s.items, item)
}

// SetSpacing sets the spacing between items
func (s *Stack) SetSpacing(spacing float64) {
	s.spacing = spacing
	for _, item := range s.items {
		item.Spacing = spacing
	}
}

// SetAlignment sets the alignment of items
func (s *Stack) SetAlignment(alignment Alignment) {
	s.alignment = alignment
	for _, item := range s.items {
		item.Alignment = alignment
	}
}

// SetDistribution sets how items are distributed
func (s *Stack) SetDistribution(distribution Distribution) {
	s.distribution = distribution
}

// MinSize returns the minimum size required for the stack
func (s *Stack) MinSize() image.Point {
	var size image.Point
	for _, item := range s.items {
		if !item.View.IsVisible() {
			continue
		}
		minSize := item.MinSize
		size.X = max(size.X, minSize.X)
		size.Y = max(size.Y, minSize.Y)
	}
	return size
}

// PreferredSize returns the preferred size for the stack
func (s *Stack) PreferredSize() image.Point {
	var size image.Point
	for _, item := range s.items {
		if !item.View.IsVisible() {
			continue
		}
		prefSize := item.View.PreferredSize()
		size.X = max(size.X, prefSize.X)
		size.Y = max(size.Y, prefSize.Y)
	}
	return size
}

// ViewFrame returns the frame for a specific view
func (s *Stack) ViewFrame(view View) image.Rectangle {
	for _, item := range s.items {
		if item.View == view {
			return item.Frame
		}
	}
	return image.Rectangle{}
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
