.PHONY: all clean pcre2 libffi libjpeg-turbo libxml2 zlib expat libtiff libpng

all: pcre2 libffi libjpeg-turbo libxml2 zlib expat libtiff libpng

pcre2:
	@echo 'Building pcre2 (cmake)...'
	@cd pcre2 && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

libffi:
	@echo 'Building libffi (autotools)...'
	@cd libffi && (test -f Makefile || (./autogen.sh && ./configure)) && make

libjpeg-turbo:
	@echo 'Building libjpeg-turbo (cmake)...'
	@cd libjpeg-turbo && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

libxml2:
	@echo 'Building libxml2 (meson)...'
	@cd libxml2 && (test -f builddir/build.ninja || meson setup builddir) && meson compile -C builddir

zlib:
	@echo 'Building zlib (cmake)...'
	@cd zlib && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

expat:
	@echo 'Building expat (cmake)...'
	@cd expat/expat && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

libtiff:
	@echo 'Building libtiff (cmake)...'
	@cd libtiff && sed -i 's/add_subdirectory(build)/# add_subdirectory(build)/' CMakeLists.txt && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

libpng:
	@echo 'Building libpng (cmake)...'
	@cd libpng && (test -f builddir/Makefile || cmake -B builddir -S .) && cmake --build builddir

clean:
	rm -rf pcre2/builddir
	@cd libffi && (test -f Makefile && make clean) || true
	rm -rf libjpeg-turbo/builddir
	rm -rf libxml2/builddir
	rm -rf zlib/builddir
	rm -rf expat/expat/builddir
	rm -rf libtiff/builddir
	rm -rf libpng/builddir
