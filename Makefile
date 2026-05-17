# Makefile for the TDI Mattermost Policy Plugin

PLUGIN_ID ?= com.archtis.mattermost-policy-plugin
PLUGIN_VERSION ?= $(shell node -p "require('./plugin.json').version")
INCLUDE_WEBAPP ?= false
ifeq ($(INCLUDE_WEBAPP),true)
BUNDLE_SUFFIX ?= -webapp
else
BUNDLE_SUFFIX ?=
endif
BUNDLE_NAME ?= $(PLUGIN_ID)-$(PLUGIN_VERSION)$(BUNDLE_SUFFIX).tar.gz

## Build the plugin server binaries (Linux only — Mattermost runs on Linux)
.PHONY: build
build:
	@echo "Building for Linux..."
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o dist/plugin-linux-amd64 .
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -trimpath -ldflags='-s -w' -o dist/plugin-linux-arm64 .

## Build the webapp
.PHONY: webapp
webapp:
	@echo "Building webapp..."
	cd webapp && npm ci && INCLUDE_CLASSIFY_RHS=$(INCLUDE_WEBAPP) npm run build

## Bundle the plugin for distribution
## Mattermost expects plugin.json at the ROOT of the extracted archive (no top-level folder)
.PHONY: bundle
ifeq ($(INCLUDE_WEBAPP),true)
bundle: build webapp
else
bundle: build webapp
endif
	@echo "Creating plugin bundle..."
	rm -rf dist/bundle
	mkdir -p dist/bundle/server/dist
	cp dist/plugin-linux-* dist/bundle/server/dist/
ifeq ($(INCLUDE_WEBAPP),true)
	mkdir -p dist/bundle/webapp/dist
	cp webapp/dist/main.js dist/bundle/webapp/dist/
	cp plugin.json dist/bundle/
else
	mkdir -p dist/bundle/webapp/dist
	cp webapp/dist/main.js dist/bundle/webapp/dist/
	node -e "const fs=require('fs'); const manifest=require('./plugin.json'); if (manifest.settings_schema?.settings) manifest.settings_schema.settings = manifest.settings_schema.settings.filter((setting) => setting.key !== 'MattermostAPIToken'); fs.writeFileSync('dist/bundle/plugin.json', JSON.stringify(manifest, null, 2) + '\n');"
endif
	cd dist/bundle && tar -czf ../$(BUNDLE_NAME) .
	@echo "Plugin bundle created: dist/$(BUNDLE_NAME)"

## Run tests with the race detector
.PHONY: test
test:
	go test -race ./...

## Run go vet
.PHONY: vet
vet:
	go vet ./...

## Run production readiness verification
.PHONY: verify
verify:
	./scripts/verify.sh

## Clean build artifacts
.PHONY: clean
clean:
	rm -rf dist/

## Install dependencies
.PHONY: deps
deps:
	go mod download
	go mod tidy

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build        - Build plugin server binaries for Linux (amd64 + arm64)"
	@echo "  webapp       - Build the webapp bundle"
	@echo "  bundle       - Create public bundle with ScopedTeamNames admin setting"
	@echo "  bundle INCLUDE_WEBAPP=true - Create internal bundle with classify RHS and -webapp suffix"
	@echo "  test         - Run Go tests with the race detector"
	@echo "  vet          - Run go vet"
	@echo "  verify       - Run Go tests and webapp build"
	@echo "  clean        - Remove build artifacts"
	@echo "  deps         - Install dependencies"
