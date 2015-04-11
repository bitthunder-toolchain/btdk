TARGET=mips-none-elf
PREFIX=$(shell pwd)/output
#HOST=i686-pc-mingw32
BUILD=
NEWLIB_OPTIONS=--enable-target-optspace --enable-newlib-hw-fp

export PATH := $(PATH):${PREFIX}/bin/
export __BTDK_VERSION__ := $(shell git describe --dirty)

# Simple dependency tree
all: toolchain done

toolchain: binutils gcc_pre gcc newlib libmpfr libgmp libmpc
gcc_pre: binutils libgmp libmpc libmpfr
libmpc: libgmp libmpfr
libmpfr: libgmp
newlib: gcc_pre
gcc: newlib
done: gcc

include packages.mk

PKGVERSION="BitThunder BTDK ($(shell git describe --dirty))"

ROOT=$(shell pwd)

binutils:
	@rm -rf build-binutils
	@mkdir build-binutils
	@cd build-binutils && ../sources/binutils/configure --host=${HOST} --build=${BUILD} --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror --with-pkgversion=${PKGVERSION}
	@cd build-binutils && $(MAKE)
	@cd build-binutils && $(MAKE) install
	@touch binutils

libmpfr:
	@rm -rf build-libmpfr
	@mkdir build-libmpfr
	@cd build-libmpfr && ../sources/libmpfr/configure --host=${HOST} --build=${BUILD} --prefix=$(shell pwd)/libmpfr --with-gmp=$(ROOT)/libgmp --disable-shared --enable-static
	@cd build-libmpfr && $(MAKE)
	@cd build-libmpfr && $(MAKE) check
	@cd build-libmpfr && $(MAKE) install

libgmp:
	@rm -rf build-libgmp
	@mkdir build-libgmp
	@cd build-libgmp && ../sources/libgmp/configure --host=${HOST} --build=${BUILD} --prefix=$(shell pwd)/libgmp --disable-shared --enable-static --without-readline --enable-cxx
	@cd build-libgmp && $(MAKE)
	#@cd build-libgmp && $(MAKE) check
	@cd build-libgmp && $(MAKE) install

libmpc:
	@rm -rf build-libmpc
	@mkdir build-libmpc
	@cd build-libmpc && ../sources/libmpc/configure --host=${HOST} --build=${BUILD} --prefix=$(shell pwd)/libmpc --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --disable-shared --enable-static
	@cd build-libmpc && $(MAKE)
	@cd build-libmpc && $(MAKE) install

gcc_pre:
	@rm -rf build-gcc
	@mkdir build-gcc
	@cd sources/gcc && git update-index --assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@sed -i 's:__BTDK_VERSION__:\"${__BTDK_VERSION__}\":g' sources/gcc/gcc/config/arm/bt-eabi.h sources/gcc/gcc/config/arm/bitthunder-eabi.h
	@cd build-gcc && ../sources/gcc/configure --host=${HOST} --build=${BUILD} --target=${TARGET} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-languages="c,c++" --with-newlib --without-headers --disable-shared --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-pkgversion=${PKGVERSION} --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --with-mpc=$(ROOT)/libmpc --with-system-zlib
	@cd build-gcc && $(MAKE) all-gcc
	@cd build-gcc && $(MAKE) install-gcc
	@cd build-gcc && $(MAKE) all-target-libgcc
	@cd build-gcc && $(MAKE) install-target-libgcc
	@touch gcc_pre

newlib:
	@rm -rf build-newlib
	@mkdir build-newlib
	@cd build-newlib && CFLAGS=-DBTDK__VERSION ../sources/newlib/configure --host=${HOST} --target=${TARGET} --prefix=${PREFIX} ${NEWLIB_OPTIONS} --enable-interwork --enable-multilib --enable-languages="c,c++" --with-gnu-as --with-gnu-ls --disable-libgloss --disable-libssp --with-pkgversion=${PKGVERSION}
	@cd build-newlib && sed -i "s|RANLIB_FOR_TARGET=${TARGET}-ranlib|RANLIB_FOR_TARGET=${PREFIX}/bin/${TARGET}-ranlib|g" Makefile
	@cd build-newlib && $(MAKE) all

newlib.install:
	@cd build-newlib && $(MAKE) install
	@touch newlib

gcc:
	@cd build-gcc && ../sources/gcc/configure --host=${HOST} --target=${TARGET} --build=${BUILD} --prefix=${PREFIX} --enable-interwork --enable-multilib --enable-languages="c,c++" --with-newlib --disable-shared --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-pkgversion=${PKGVERSION} --with-gmp=$(ROOT)/libgmp --with-mpfr=$(ROOT)/libmpfr --with-mpc=$(ROOT)/libmpc --with-system-zlib
	@cd build-gcc && $(MAKE) all
	@cd build-gcc && $(MAKE) install
	@touch gcc
	@cd sources/gcc && git update-index --no-assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@cd sources/gcc && git checkout gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h

libc.update:
	@cd build-newlib && $(MAKE) all-gcc
	@cd build-newlib && $(MAKE) install
	@bash install-libc.sh $(PREFIX) $(TARGET)

libc.install: newlib
	@bash install-libc.sh $(PREFIX) $(TARGET)

toolchain:
	@echo "BTDK sucessfully compiled"

ubuntu.prerequisites:
	@sudo apt-get install ${PACKAGES}

clean:
	@cd sources/gcc && git update-index --no-assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@cd sources/gcc && git checkout gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@-rm binutils gcc_pre newlib gcc
	@-rm -rf libgmp libmpfr libmpc
	@-rm -rf build-*

done:
	@cd sources/gcc && git update-index --no-assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@cd sources/gcc && git checkout gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h

