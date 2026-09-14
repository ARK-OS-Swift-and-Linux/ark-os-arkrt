.PHONY: all clean xkeyboard-config libxkbcommon

all: xkeyboard-config libxkbcommon

xkeyboard-config:
	@echo 'Building xkeyboard-config (meson)...'
	@cd xkeyboard-config && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

libxkbcommon:
	@echo 'Building libxkbcommon (meson)...'
	@cd libxkbcommon && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

clean:
	rm -rf xkeyboard-config/builddir
	rm -rf libxkbcommon/builddir
