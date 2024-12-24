package layout

import (
	"image"
)

// VStack represents a vertical stack layout
type VStack struct {
	*Stack
}

// NewVStack creates a new vertical stack layout
func NewVStack() *VStack {
	return &VStack{Stack: NewStack()}
}

// Layout performs the vertical layout of the views
func (v *VStack) Layout(bounds image.Rectangle) {
	if len(v.items) == 0 {
		return
	}

	// Calculate total spacing and content height
	totalSpacing := float64(len(v.items)-1) * v.spacing
	totalContentHeight := 0
	visibleItems := make([]*LayoutItem, 0)

	for _, item := range v.items {
		if !item.View.IsVisible() {
			continue
		}
		visibleItems = append(visibleItems, item)
		totalContentHeight += item.View.PreferredSize().Y
	}

	// Calculate available space and flex space
	availableHeight := float64(bounds.Dy()) - totalSpacing
	flexSpace := availableHeight - float64(totalContentHeight)

	// Calculate total flex grow and shrink
	totalFlexGrow := 0.0
	totalFlexShrink := 0.0
	for _, item := range visibleItems {
		totalFlexGrow += item.FlexGrow
		totalFlexShrink += item.FlexShrink
	}

	// Position items
	y := bounds.Min.Y
	for i, item := range visibleItems {
		prefSize := item.View.PreferredSize()
		itemHeight := float64(prefSize.Y)

		// Apply flex grow/shrink
		if flexSpace > 0 && totalFlexGrow > 0 {
			itemHeight += (flexSpace * item.FlexGrow) / totalFlexGrow
		} else if flexSpace < 0 && totalFlexShrink > 0 {
			itemHeight += (flexSpace * item.FlexShrink) / totalFlexShrink
		}

		// Calculate x position based on alignment
		x := bounds.Min.X
		width := bounds.Dx()
		switch item.Alignment {
		case AlignmentCenter:
			x += (width - prefSize.X) / 2
		case AlignmentTrailing:
			x += width - prefSize.X
		}

		// Set frame
		frame := image.Rect(
			x,
			int(y),
			x+prefSize.X,
			int(float64(y)+itemHeight),
		)
		item.Frame = frame
		item.View.SetFrame(frame)

		// Move to next position
		y += int(itemHeight)
		if i < len(visibleItems)-1 {
			y += int(v.spacing)
		}
	}
}

// MinSize returns the minimum size required for the vertical stack
func (v *VStack) MinSize() image.Point {
	size := image.Point{}
	totalSpacing := float64(len(v.items)-1) * v.spacing

	for _, item := range v.items {
		if !item.View.IsVisible() {
			continue
		}
		minSize := item.MinSize
		size.X = max(size.X, minSize.X)
		size.Y += minSize.Y
	}

	size.Y += int(totalSpacing)
	return size
}
