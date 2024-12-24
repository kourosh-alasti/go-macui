package layout

import (
	"image"
)

// HStack represents a horizontal stack layout
type HStack struct {
	*Stack
}

// NewHStack creates a new horizontal stack layout
func NewHStack() *HStack {
	return &HStack{Stack: NewStack()}
}

// Layout performs the horizontal layout of the views
func (h *HStack) Layout(bounds image.Rectangle) {
	if len(h.items) == 0 {
		return
	}

	// Calculate total spacing and content width
	totalSpacing := float64(len(h.items)-1) * h.spacing
	totalContentWidth := 0
	visibleItems := make([]*LayoutItem, 0)

	for _, item := range h.items {
		if !item.View.IsVisible() {
			continue
		}
		visibleItems = append(visibleItems, item)
		totalContentWidth += item.View.PreferredSize().X
	}

	// Calculate available space and flex space
	availableWidth := float64(bounds.Dx()) - totalSpacing
	flexSpace := availableWidth - float64(totalContentWidth)

	// Calculate total flex grow and shrink
	totalFlexGrow := 0.0
	totalFlexShrink := 0.0
	for _, item := range visibleItems {
		totalFlexGrow += item.FlexGrow
		totalFlexShrink += item.FlexShrink
	}

	// Position items
	x := bounds.Min.X
	for i, item := range visibleItems {
		prefSize := item.View.PreferredSize()
		itemWidth := float64(prefSize.X)

		// Apply flex grow/shrink
		if flexSpace > 0 && totalFlexGrow > 0 {
			itemWidth += (flexSpace * item.FlexGrow) / totalFlexGrow
		} else if flexSpace < 0 && totalFlexShrink > 0 {
			itemWidth += (flexSpace * item.FlexShrink) / totalFlexShrink
		}

		// Calculate y position based on alignment
		y := bounds.Min.Y
		height := bounds.Dy()
		switch item.Alignment {
		case AlignmentCenter:
			y += (height - prefSize.Y) / 2
		case AlignmentTrailing:
			y += height - prefSize.Y
		}

		// Set frame
		frame := image.Rect(
			int(x),
			y,
			int(float64(x)+itemWidth),
			y+prefSize.Y,
		)
		item.Frame = frame
		item.View.SetFrame(frame)

		// Move to next position
		x += int(itemWidth)
		if i < len(visibleItems)-1 {
			x += int(h.spacing)
		}
	}
}

// MinSize returns the minimum size required for the horizontal stack
func (h *HStack) MinSize() image.Point {
	size := image.Point{}
	totalSpacing := float64(len(h.items)-1) * h.spacing

	for _, item := range h.items {
		if !item.View.IsVisible() {
			continue
		}
		minSize := item.MinSize
		size.X += minSize.X
		size.Y = max(size.Y, minSize.Y)
	}

	size.X += int(totalSpacing)
	return size
}
