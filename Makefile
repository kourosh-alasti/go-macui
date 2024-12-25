.PHONY: all clean test

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get

# Component source files
COMPONENT_SRCS=pkg/native/darwin/base.m \
              pkg/native/darwin/button.m \
              pkg/native/darwin/text.m \
              pkg/native/darwin/container.m \
              pkg/native/darwin/progress.m \
              pkg/native/darwin/media.m \
              pkg/native/darwin/selection.m \
              pkg/native/darwin/checkbox.m \
              pkg/native/darwin/combobox.m \
              pkg/native/darwin/imageview.m \
              pkg/native/darwin/progressbar.m \
              pkg/native/darwin/progressspinner.m \
              pkg/native/darwin/radiobutton.m \
              pkg/native/darwin/scrollview.m \
              pkg/native/darwin/slider.m \
              pkg/native/darwin/stackview.m \
              pkg/native/darwin/tabview.m

# CGO parameters
CGO_CFLAGS=-x objective-c -fobjc-arc
CGO_LDFLAGS=-framework Cocoa -framework QuartzCore -framework Foundation

# Build targets
all: build

build:
	CGO_CFLAGS="$(CGO_CFLAGS)" CGO_LDFLAGS="$(CGO_LDFLAGS)" $(GOBUILD) -v ./...

test:
	CGO_CFLAGS="$(CGO_CFLAGS)" CGO_LDFLAGS="$(CGO_LDFLAGS)" $(GOTEST) ./...

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
