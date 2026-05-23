BUILD_DIR := .build
BINARY := $(BUILD_DIR)/bootstrap
ZIP := $(BUILD_DIR)/forwarder.zip

.PHONY: build clean

build: $(ZIP)

$(ZIP): $(BINARY)
	cd $(BUILD_DIR) && zip forwarder.zip bootstrap

$(BINARY): src/main.go src/go.mod src/go.sum
	mkdir -p $(BUILD_DIR)
	cd src && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -o ../$(BINARY) .

clean:
	rm -rf $(BUILD_DIR)
