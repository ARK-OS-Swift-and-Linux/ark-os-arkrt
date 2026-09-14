.PHONY: all clean wayland Runtime/wayland-protocols

all: wayland Runtime/wayland-protocols

wayland:
	@echo 'Building wayland (meson)...'
	@cd wayland && (test -f builddir/build.ninja || meson setup builddir -Ddocumentation=false -Dtests=false -Ddtd_validation=false --default-library=both) && meson compile -C builddir

Runtime/wayland-protocols:
	@echo 'Building Runtime/wayland-protocols (meson)...'
	@cd Runtime/wayland-protocols && (test -f builddir/build.ninja || meson setup builddir -Dtests=false) && meson compile -C builddir

clean:
	rm -rf wayland/builddir
	rm -rf Runtime/wayland-protocols/builddir
