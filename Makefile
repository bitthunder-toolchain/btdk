override TARGET?=arm-eabi-bt
override HOST?=$(shell gcc -dumpmachine)
VERSION:=$(shell git describe)
PREFIX=$(shell pwd)/output/${VERSION}/${TARGET}/${HOST}/
ifndef HOST
BUILD:=$(shell gcc -dumpmachine)
else
BUILD:=$(shell ${HOST}-gcc -dumpmachine)
endif

BASE:=$(shell readlink -f $(dir $(lastword $(MAKEFILE_LIST))))

NEWLIB_OPTIONS=--enable-target-optspace --enable-newlib-hw-fp --enable-interwork --enable-multilib --with-gnu-as --with-gnu-ls --disable-libgloss --disable-libssp

export PATH := $(PATH):${PREFIX}/output/bin/
export __BTDK_VERSION__ := $(shell git describe --dirty)

# Simple dependency tree
all: toolchain done
info:
	@echo "TARGET    : ${TARGET}"
	@echo "HOST      : ${HOST}"
	@echo "BUILD     : ${BUILD}"
	@echo "PREFIX    : ${PREFIX}"
	@echo "BASE      : ${BASE}"

#
#	Top-level invoke targets
#

.PHONY: binutils
binutils:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/binutils


.PHONY: gcc_configure
gcc_configure:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/gcc_configure

.PHONY: gcc_pre
gcc_pre:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/gcc_pre

.PHONY: gcc
gcc:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/gcc

.PHONY: libgcc
libgcc:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/libgcc_pre

.PHONY: newlib
newlib:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/newlib

.PHONY: newlib.install
newlib.install:
	TARGET=$(TARGET) HOST=$(HOST) BUILD=$(BUILD) $(MAKE) $(PREFIX)/newlib.install

#
#	Top-level dependencies
#
.PHONY: toolchain
toolchain: $(PREFIX)/binutils $(PREFIX)/gcc $(PREFIX)/newlib
$(PREFIX)/newlib: $(PREFIX)/libmpfr $(PREFIX)/libgmp $(PREFIX)/libmpc

#
#	GCC dependency tree
#
$(PREFIX)/gcc: $(PREFIX)/binutils $(PREFIX)/newlib $(PREFIX)/gcc_pre
$(PREFIX)/gcc_configure: $(PREFIX)/libmpfr $(PREFIX)/libgmp $(PREFIX)/libmpc $(PREFIX)/binutils
$(PREFIX)/gcc_pre: $(PREFIX)/gcc_configure
$(PREFIX)/libgcc_pre: $(PREFIX)/gcc_pre

$(PREFIX)/libmpc: $(PREFIX)/libgmp $(PREFIX)/libmpfr
$(PREFIX)/libmpfr: $(PREFIX)/libgmp
$(PREFIX)/newlib: $(PREFIX)/gcc_pre $(PREFIX)/libgcc_pre
$(PREFIX)/gcc: $(PREFIX)/newlib.install
$(PREFIX)/newlib.install: $(PREFIX)/newlib
done: $(PREFIX)/gcc

include packages.mk

PKGVERSION="BitThunder BTDK ($(shell git describe --dirty))"

ROOT=$(shell pwd)

override BINUTILS_CONFIG?=--enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror --disable-tui
override LIBGMP_CONFIG?=--disable-shared --enable-static --without-readline --enable-cxx
override LIBMPFR_CONFIG?=--disable-shared --enable-static
override LIBMPC_CONFIG?=--disable-shared --enable-static
override GCC_BASE_CONFIG?=--disable-shared --enable-interwork --enable-multilib --enable-languages="c,c++" --without-headers --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-system-zlib
override NEWLIB_CONFIG?=--enable-interwork --enable-multilib --with-gnu-as --with-gnu-ls --disable-libgloss --disable-libssp --enable-target-optspace --enable-newlib-hw-fp
override GCC_CONFIG?=--enable-interwork --enable-multilib --enable-languages="c,c++" --with-newlib --disable-shared --disable-libssp --with-gnu-as --with-gnu-ld --disable-nls --with-system-zlib --disable-hosted-libstdcxx

$(PREFIX)/binutils:
	@rm -rf $(PREFIX)/build/binutils
	@mkdir -p $(PREFIX)/build/binutils
	cd $(PREFIX)/build/binutils && $(BASE)/sources/binutils/configure --host=${HOST} --build=${BUILD} --target=${TARGET} --prefix=${PREFIX}/output  --with-pkgversion=${PKGVERSION} ${BINUTILS_CONFIG}
	@cd $(PREFIX)/build/binutils && $(MAKE)
	@cd $(PREFIX)/build/binutils && $(MAKE) install
	@touch $(PREFIX)/binutils

$(PREFIX)/libgmp:
	@rm -rf $(PREFIX)/build/libgmp
	@mkdir $(PREFIX)/build/libgmp
	cd $(PREFIX)/build/libgmp && $(BASE)/sources/libgmp/configure --host=${HOST} --build=${BUILD} --prefix=${PREFIX}/output ${LIBGMP_CONFIG}
	@cd $(PREFIX)/build/libgmp && $(MAKE)
	#@cd $(PREFIX)/build/libgmp && $(MAKE) check
	cd $(PREFIX)/build/libgmp && $(MAKE) install
	@touch $(PREFIX)/libgmp

$(PREFIX)/libmpfr:
	@rm -rf $(PREFIX)/build/libmpfr
	@mkdir $(PREFIX)/build/libmpfr
	@cd $(PREFIX)/build/libmpfr && $(BASE)/sources/libmpfr/configure --host=${HOST} --build=${BUILD} --prefix=${PREFIX}/output --with-gmp=${PREFIX}/output ${LIBMPFR_CONFIG}
	@cd $(PREFIX)/build/libmpfr && $(MAKE)
	@cd $(PREFIX)/build/libmpfr && $(MAKE) check
	@cd $(PREFIX)/build/libmpfr && $(MAKE) install
	@touch $(PREFIX)/libmpfr

$(PREFIX)/libmpc:
	@rm -rf $(PREFIX)/build/libmpc
	@mkdir $(PREFIX)/build/libmpc
	@cd $(PREFIX)/build/libmpc && $(BASE)/sources/libmpc/configure --host=${HOST} --build=${BUILD} --prefix=${PREFIX}/output --with-gmp=${PREFIX}/output --with-mpfr=${PREFIX}/output ${LIBMPC_CONFIG}
	@cd $(PREFIX)/build/libmpc && $(MAKE)
	@cd $(PREFIX)/build/libmpc && $(MAKE) install
	@touch $(PREFIX)/libmpc

$(PREFIX)/gcc_configure:
	@rm -rf $(PREFIX)/build/gcc
	@mkdir $(PREFIX)/build/gcc
	@cd sources/gcc && git update-index --assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@sed -ibak 's:__BTDK_VERSION__:\"${__BTDK_VERSION__}\":g' sources/gcc/gcc/config/arm/bt-eabi.h sources/gcc/gcc/config/arm/bitthunder-eabi.h
	@cd $(PREFIX)/build/gcc && $(BASE)/sources/gcc/configure --host=${HOST} --build=${BUILD} --target=${TARGET} --prefix=${PREFIX}/output --with-pkgversion=${PKGVERSION} --with-gmp=${PREFIX}/output --with-mpfr=${PREFIX}/output --with-mpc=${PREFIX}/output ${GCC_BASE_CONFIG}
	@touch $(PREFIX)/gcc_configure

$(PREFIX)/gcc_pre:
	@cd $(PREFIX)/build/gcc && $(MAKE) all-gcc
	@cd $(PREFIX)/build/gcc && $(MAKE) install-gcc
	@touch $(PREFIX)/gcc_pre

$(PREFIX)/libgcc_pre:
	@cd $(PREFIX)/build/gcc && $(MAKE) all-target-libgcc
	@cd $(PREFIX)/build/gcc && $(MAKE) install-target-libgcc
	@touch $(PREFIX)/libgcc_pre

$(PREFIX)/newlib:
	@rm -rf $(PREFIX)/build/newlib
	@mkdir $(PREFIX)/build/newlib
	cd $(PREFIX)/build/newlib && CFLAGS=-DBTDK__VERSION $(BASE)/sources/newlib/configure --target=${TARGET} --prefix="${PREFIX}/output" ${NEWLIB_OPTIONS} --with-pkgversion=${PKGVERSION}
	#@cd $(PREFIX)/build/newlib && sed -ibak "s|RANLIB_FOR_TARGET=${TARGET}-ranlib|RANLIB_FOR_TARGET=${PREFIX}/output/bin/${TARGET}-ranlib|g" Makefile
	@cd $(PREFIX)/build/newlib && $(MAKE) all
	cd $(PREFIX)/build/newlib $(MAKE) install
	@touch $(PREFIX)/newlib

$(PREFIX)/newlib.install:
	@cd $(PREFIX)/build/newlib && $(MAKE) install
	@touch $(PREFIX)/newlib.install

$(PREFIX)/gcc:
	@cd $(PREFIX)/build/gcc && $(BASE)/sources/gcc/configure --host=${HOST} --target=${TARGET} --build=${BUILD} --prefix=${PREFIX}/output --with-pkgversion=${PKGVERSION} --with-gmp=${PREFIX}/output --with-mpfr=${PREFIX}/output --with-mpc=${PREFIX}/output ${GCC_CONFIG}
	@cd $(PREFIX)/build/gcc && $(MAKE) all
	@cd $(PREFIX)/build/gcc && $(MAKE) install
	@touch $(PREFIX)/gcc
	@cd $(BASE)/sources/gcc && git update-index --no-assume-unchanged gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h
	@cd $(BASE)/sources/gcc && git checkout gcc/config/arm/bt-eabi.h gcc/config/arm/bitthunder-eabi.h

.PHONY: libc.update
libc.update:
	@cd $(PREFIX)/build/newlib && $(MAKE) all
	@cd $(PREFIX)/build/newlib && $(MAKE) install
	@bash $(BASE)/install-libc.sh $(PREFIX)/output $(TARGET)

.PHONY: libc.install
libc.install: newlib
	@bash install-libc.sh $(PREFIX)/output $(TARGET)

.PHONY: toolchain
toolchain:
	@echo "BTDK sucessfully compiled"

.PHONY: ubuntu.prerequisites
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
