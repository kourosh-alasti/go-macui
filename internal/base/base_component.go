package base

import (
	"image"
)

// Component represents the base interface for all UI components
type Component interface {
	// Core properties
	ID() string
	SetID(id string)
	Parent() Component
	SetParent(parent Component)

	// Layout and positioning
	Frame() image.Rectangle
	SetFrame(frame image.Rectangle)

	// Component hierarchy
	AddChild(child Component)
	RemoveChild(child Component)
	Children() []Component

	// Lifecycle
	Init()
	Update()
	Cleanup()

	// Event handling
	HandleEvent(event interface{}) bool
}

// BaseComponent provides a default implementation of the Component interface
type BaseComponent struct {
	id       string
	parent   Component
	children []Component
	frame    image.Rectangle
}

func NewBaseComponent() *BaseComponent {
	return &BaseComponent{
		children: make([]Component, 0),
		frame:    image.Rectangle{},
	}
}

// ID returns the component's unique identifier
func (b *BaseComponent) ID() string {
	return b.id
}

// SetID sets the component's unique identifier
func (b *BaseComponent) SetID(id string) {
	b.id = id
}

// Parent returns the component's parent
func (b *BaseComponent) Parent() Component {
	return b.parent
}

// SetParent sets the component's parent
func (b *BaseComponent) SetParent(parent Component) {
	b.parent = parent
}

// Frame returns the component's frame
func (b *BaseComponent) Frame() image.Rectangle {
	return b.frame
}

// SetFrame sets the component's frame
func (b *BaseComponent) SetFrame(frame image.Rectangle) {
	b.frame = frame
}

// AddChild adds a child component
func (b *BaseComponent) AddChild(child Component) {
	child.SetParent(b)
	b.children = append(b.children, child)
}

// RemoveChild removes a child component
func (b *BaseComponent) RemoveChild(child Component) {
	for i, c := range b.children {
		if c == child {
			b.children = append(b.children[:i], b.children[i+1:]...)
			child.SetParent(nil)
			return
		}
	}
}

// Children returns all child components
func (b *BaseComponent) Children() []Component {
	return b.children
}

// Init initializes the component
func (b *BaseComponent) Init() {
	// Default implementation
}

// Update updates the component state
func (b *BaseComponent) Update() {
	// Default implementation
}

// Cleanup performs cleanup when component is destroyed
func (b *BaseComponent) Cleanup() {
	// Default implementation
}

// HandleEvent handles incoming events
func (b *BaseComponent) HandleEvent(event interface{}) bool {
	// Default implementation returns false to indicate event wasn't handled
	return false
}
