SHELL := /bin/bash
.DEFAULT_GOAL := generate

BIN			= $(CURDIR)/bin
BUILD_DIR	= $(CURDIR)/build

GOPATH			= $(HOME)/go
GOBIN			= $(GOPATH)/bin
GO				?= GOGC=off $(shell which go)
NODE			?= $(shell which node)
PNPM			?= $(shell which pnpm)
PKGS			= $(or $(PKG),$(shell env $(GO) list ./...))
VERSION			?= $(shell git describe --tags --always --match=v*)
SHORT_COMMIT	?= $(shell git rev-parse --short HEAD)

PATH := $(GOBIN):$(BIN):$(PATH)

# Printing
V ?= 0
Q = $(if $(filter 1,$V),,@)
M = $(shell printf "\033[34;1m▶\033[0m")

$(BUILD_DIR):
	@mkdir -p $@

# Tools
$(BIN):
	@mkdir -p $@
$(BIN)/%: | $(BIN) ; $(info $(M) building $(@F)…)
	$Q GOBIN=$(BIN) $(GO) install $(shell $(GO) list tool | grep $(@F))

$(EMBEDDED):
	$Q mkdir -p $(shell dirname $@)
	$Q touch $@

$(BIN)/protoc: | $(BIN) ; $(info $(M) building protoc…)
	$Q ./etc/install-protoc.sh $(BIN)

BUF = $(BIN)/buf
OAPI_CODEGEN = $(BIN)/oapi-codegen
PROTOC = $(BIN)/protoc
PROTOC_GEN_GO = $(BIN)/protoc-gen-go
PROTOC_GEN_GO_GRPC = $(BIN)/protoc-gen-go-grpc
PROTOC_GEN_GOGO = $(BIN)/protoc-gen-gogo

TOOLCHAIN = $(OAPI_CODEGEN) $(PROTOC) $(PROTOC_GEN_GO) $(PROTOC_GEN_GO_GRPC) $(PROTOC_GEN_GOGO) $(BUF)

.PHONY: update # Update all dependencies
update: | $(TOOLCHIAN) ; $(info $(M) updating dependencies…) @
	$Q $(BUF) dep update;
	$Q $(BUF) dep prune;

.PHONY: fmt
fmt: | $(EMBEDDED) ; $(info $(M) running fmt…) @ ## Format all source files
	$Q $(BUF) format -w

.PHONY: generate
generate: | $(EMBEDDED) $(TOOLCHAIN) ; $(info $(M) running generate…) @ ## Generate all source files
	$Q $(BUF) generate -v .
	$Q $(MAKE) fmt

.PHONY: clean
clean: ; $(info $(M) cleaning…)	@ ## Cleanup everything
	@rm -rf $(BIN)
	@rm -rf $(BUILD)
	@find . -name '*_mock_test.go' -exec rm -r {} \;
	@find . -name '*_string.go' -exec rm -r {} \;
	@find . -name '*_gen.go' -exec rm -r {} \;
	@find . -name '*.pb.go' -exec rm -r {} \;

.PHONY: help
help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
