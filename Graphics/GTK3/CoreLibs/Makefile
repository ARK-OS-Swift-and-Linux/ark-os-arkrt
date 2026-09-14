.PHONY: all clean glib gobject-introspection gdk-pixbuf at-spi2-core

all: glib gobject-introspection gdk-pixbuf at-spi2-core

glib:
	@echo 'Building glib (meson)...'
	@cd glib && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

gobject-introspection:
	@echo 'Building gobject-introspection (meson)...'
	@cd gobject-introspection && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

gdk-pixbuf:
	@echo 'Building gdk-pixbuf (meson)...'
	@cd gdk-pixbuf && (test -f builddir/build.ninja || meson setup builddir -Dglycin=disabled -Dtests=false -Dman=false) && meson compile -C builddir

at-spi2-core:
	@echo 'Building at-spi2-core (meson)...'
	@cd at-spi2-core && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

clean:
	rm -rf glib/builddir
	rm -rf gobject-introspection/builddir
	rm -rf gdk-pixbuf/builddir
	rm -rf at-spi2-core/builddir
