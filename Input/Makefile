.PHONY: all clean xkeyboard-config libxkbcommon


# 1. Get the absolute path of the directory containing THIS Makefile
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_PATH)))
CURRENT_DIR := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
INPUT_DIR   := $(dir $(MKFILE_PATH))

# 2. Compute the relative path to wayland-protocols/builddir/meson-uninstalled
# This goes up one level to 'arkrt' and then down into 'Wayland/Runtime/...'
WAYLAND_PROTOCOLS_PC_DIR := $(abspath $(INPUT_DIR)../Wayland/Runtime/wayland-protocols/builddir/meson-uninstalled)

# 3. Append to PKG_CONFIG_PATH and export it to all sub-shells triggered by Make
export PKG_CONFIG_PATH := $(WAYLAND_PROTOCOLS_PC_DIR):$(PKG_CONFIG_PATH)


all: xkeyboard-config libxkbcommon

xkeyboard-config:
	@echo 'Building xkeyboard-config (meson)...'
	@cd xkeyboard-config && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

libxkbcommon:
	@echo 'Building libxkbcommon (meson)...'
	@cd libxkbcommon && (test -f builddir/build.ninja || PKG_CONFIG_PATH="$$(find ../../Graphics/Wayland -name 'meson-uninstalled' -o -name 'pkgconfig' | tr '\n' ':')" meson setup builddir) && meson compile -C builddir

clean:
	rm -rf xkeyboard-config/builddir
	rm -rf libxkbcommon/builddir
