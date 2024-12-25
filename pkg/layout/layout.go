package layout

import (
	"image"
)

// Alignment represents the alignment of items in a layout
type Alignment int

const (
	AlignmentLeading Alignment = iota
	AlignmentCenter
	AlignmentTrailing
)

// Distribution represents how items are distributed in a layout
type Distribution int

const (
	DistributionStart Distribution = iota
	DistributionCenter
	DistributionEnd
	DistributionFill
	DistributionFillEqually
	DistributionFillProportionally
)

// Layout is the interface that all layouts must implement
type Layout interface {
	// Layout performs the layout of the views within the given bounds
	Layout(bounds image.Rectangle)
	// MinSize returns the minimum size required for this layout
	MinSize() image.Point
	// PreferredSize returns the preferred size for this layout
	PreferredSize() image.Point
	// ViewFrame returns the frame for a specific view
	ViewFrame(view View) image.Rectangle
}

// LayoutItem represents an item in a layout with its constraints
type LayoutItem struct {
	View       View
	Frame      image.Rectangle
	MinSize    image.Point
	MaxSize    image.Point
	Alignment  Alignment
	Spacing    float64
	Priority   float64
	FlexGrow   float64
	FlexShrink float64
}

// View is the interface that all views must implement for layout
type View interface {
	// Frame returns the current frame of the view
	Frame() image.Rectangle
	// SetFrame sets the frame of the view
	SetFrame(frame image.Rectangle)
	// MinSize returns the minimum size of the view
	MinSize() image.Point
	// PreferredSize returns the preferred size of the view
	PreferredSize() image.Point
	// IsVisible returns whether the view is visible
	IsVisible() bool
}
