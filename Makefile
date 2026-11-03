HS_DIR     ?= $(HOME)/.hammerspoon
CONFIG_DIR ?= $(HOME)/.config/splitview
CFLAGS      = -fobjc-arc -framework Foundation -framework CoreGraphics

build/svctl: src/svctl.m
	mkdir -p build
	clang $(CFLAGS) $< -o $@

# Copies svctl into Hammerspoon's config, symlinks the Lua module, and seeds
# the ratios file if there isn't one yet.
install: build/svctl
	mkdir -p $(HS_DIR)/bin $(CONFIG_DIR)
	cp build/svctl $(HS_DIR)/bin/svctl
	ln -sf $(CURDIR)/hammerspoon/splitview.lua $(HS_DIR)/splitview.lua
	[ -e $(CONFIG_DIR)/ratios.txt ] || cp config/ratios.txt $(CONFIG_DIR)/ratios.txt

clean:
	rm -rf build

.PHONY: install clean
