ASSETS_DIR := assets
BINARY := $(ASSETS_DIR)/bootstrap
ZIP := $(ASSETS_DIR)/forwarder.zip

.PHONY: build clean

build: $(ZIP)

$(ZIP): $(BINARY)
	cd $(ASSETS_DIR) && zip forwarder.zip bootstrap && rm bootstrap

$(BINARY): src/main.go src/go.mod src/go.sum
	mkdir -p $(ASSETS_DIR)
	cd src && GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags="-s -w" -o ../$(BINARY) .

clean:
	rm -f $(ZIP)
