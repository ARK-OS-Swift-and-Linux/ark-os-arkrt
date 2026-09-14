.PHONY: all clean seatd

all: seatd

seatd:
	@echo 'Building seatd (meson)...'
	@cd seatd && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

clean:
	rm -rf seatd/builddir
