package components

// View represents a basic view component that can be added to windows and other containers
type View interface {
	// Native returns the native view handle (NSView*)
	Native() uintptr
}
