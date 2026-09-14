.PHONY: all clean cairo pixman fribidi pango freetype harfbuzz fontconfig

all: cairo pixman fribidi pango freetype harfbuzz fontconfig

cairo:
	@echo 'Building cairo (meson)...'
	@cd cairo && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

pixman:
	@echo 'Building pixman (meson)...'
	@cd pixman && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

fribidi:
	@echo 'Building fribidi (meson)...'
	@cd fribidi && (test -f builddir/build.ninja || meson setup builddir -Ddocs=false) && meson compile -C builddir

pango:
	@echo 'Building pango (meson)...'
	@cd pango && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

freetype:
	@echo 'Building freetype (meson)...'
	@cd freetype && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

harfbuzz:
	@echo 'Building harfbuzz (meson)...'
	@cd harfbuzz && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

fontconfig:
	@echo 'Building fontconfig (meson)...'
	@cd fontconfig && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

clean:
	rm -rf cairo/builddir
	rm -rf pixman/builddir
	rm -rf fribidi/builddir
	rm -rf pango/builddir
	rm -rf freetype/builddir
	rm -rf harfbuzz/builddir
	rm -rf fontconfig/builddir
