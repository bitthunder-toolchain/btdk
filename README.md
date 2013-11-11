# BTDK - BitThunder Development Kit

This repository allows you to build a complete end-to-end toolchain for bitthunder.
With this toolchain you can:

	 * Build the bitthunder kernel.
	 * Build and link kernel mode applications/processes.
	 * Build separate applications to be loaded by the bt elfloader.
	 * Build bare-metal code. (I.e. no bitthunder linking or includes).

# Toolchain versions:

BTDK provides a modern toolchain and library with the following versions.

	 * binutils-2.24
	 * gcc-4.8.1
	 * newlib-2.0.0

# Building BTDK

Building the BTDK should be relatively painless :S simply:

    git submodule update --init
    make

Speed up the build using:

    make -j32

# Pre-requisites

See packages.mk for a list of all ubuntu/debian packages required for a sucessful build.

    make ubuntu.prerequisites
