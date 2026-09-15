.PHONY: all clean mesa libdrm gtk3 libepoxy weston

all: mesa libdrm gtk3 libepoxy weston

mesa:
	@echo 'Building mesa (meson)...'
	@cd mesa && (test -f builddir/build.ninja || meson setup builddir -Dgallium-rusticl=false -Dvulkan-drivers=swrast,amd,intel -Dgallium-drivers=llvmpipe,softpipe,virgl,radeonsi,iris,crocus,i915) && meson compile -C builddir

libdrm:
	@echo 'Building libdrm (meson)...'
	@cd libdrm && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

gtk3:
	@echo 'Building gtk3 (meson)...'
	@cd gtk3 && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

libepoxy:
	@echo 'Building libepoxy (meson)...'
	@cd libepoxy && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

weston:
	@echo 'Building weston (meson)...'
	@grep -q wayland_scanner ../../Wayland/wayland/builddir/meson-uninstalled/wayland-scanner-uninstalled.pc || echo 'wayland_scanner=$${prefix}/src/wayland-scanner' >> ../../Wayland/wayland/builddir/meson-uninstalled/wayland-scanner-uninstalled.pc
	@cd weston && (test -f builddir/build.ninja || PKG_CONFIG_PATH="$$(find $$(realpath ../../../Wayland ../../Support) -name 'meson-uninstalled' -o -name 'pkgconfig' | tr '\n' ':')" meson setup builddir -Dbackend-drm=true -Dbackend-headless=false -Dbackend-rdp=false -Dbackend-x11=false -Dcolor-management-lcms=false -Dsystemd=false -Dbackend-pipewire=false) && meson compile -C builddir

clean:
	rm -rf mesa/builddir
	rm -rf libdrm/builddir
	rm -rf gtk3/builddir
	rm -rf libepoxy/builddir
	rm -rf weston/builddir
