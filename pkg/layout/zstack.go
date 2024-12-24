package layout

import (
	"image"
)

// ZStack represents a stack layout that overlays views
type ZStack struct {
	*Stack
}

// NewZStack creates a new z-axis stack layout
func NewZStack() *ZStack {
	return &ZStack{Stack: NewStack()}
}

// Layout performs the z-axis layout of the views
func (z *ZStack) Layout(bounds image.Rectangle) {
	if len(z.items) == 0 {
		return
	}

	for _, item := range z.items {
		if !item.View.IsVisible() {
			continue
		}

		prefSize := item.View.PreferredSize()
		
		// Calculate position based on alignment
		x := bounds.Min.X
		y := bounds.Min.Y
		width := bounds.Dx()
		height := bounds.Dy()

		switch item.Alignment {
		case AlignmentCenter:
			x += (width - prefSize.X) / 2
			y += (height - prefSize.Y) / 2
		case AlignmentTrailing:
			x += width - prefSize.X
			y += height - prefSize.Y
		}

		// Set frame
		item.View.SetFrame(image.Rect(
			x,
			y,
			x+prefSize.X,
			y+prefSize.Y,
		))
	}
}

// MinSize returns the minimum size required for the z-stack
func (z *ZStack) MinSize() image.Point {
	size := image.Point{}

	for _, item := range z.items {
		if !item.View.IsVisible() {
			continue
		}
		minSize := item.MinSize
		size.X = max(size.X, minSize.X)
		size.Y = max(size.Y, minSize.Y)
	}

	return size
}
