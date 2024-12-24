package base

// View represents a visual component that can be rendered
type View interface {
	Component

	// Visual properties
	IsVisible() bool
	SetVisible(visible bool)

	// Rendering
	Draw()
	NeedsRedraw() bool
	SetNeedsRedraw(needsRedraw bool)
}

// BaseView provides a default implementation of the View interface
type BaseView struct {
	BaseComponent
	visible     bool
	needsRedraw bool
}

func NewBaseView() *BaseView {
	return &BaseView{
		BaseComponent: *NewBaseComponent(),
		visible:       true,
		needsRedraw:   true,
	}
}

// IsVisible returns whether the view is visible
func (v *BaseView) IsVisible() bool {
	return v.visible
}

// SetVisible sets the view's visibility
func (v *BaseView) SetVisible(visible bool) {
	v.visible = visible
	v.SetNeedsRedraw(true)
}

// Draw implements the basic drawing functionality
func (v *BaseView) Draw() {
	// Default implementation
}

// NeedsRedraw returns whether the view needs to be redrawn
func (v *BaseView) NeedsRedraw() bool {
	return v.needsRedraw
}

// SetNeedsRedraw marks the view for redrawing
func (v *BaseView) SetNeedsRedraw(needsRedraw bool) {
	v.needsRedraw = needsRedraw
}
