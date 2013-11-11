#
# Ensure submodules
#

#git submodule sync
#git submodule update --init

#sudo apt-get install libmpfr-dev libmpc-dev

TARGET=arm-eabi-bt
PREFIX=/opt/btdk

export PATH=$PATH:$PREFIX/bin/

rm -rf build-binutils
mkdir build-binutils
cd build-binutils
../sources/binutils/configure --target=$TARGET --prefix=$PREFIX --enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror
make -j32
sudo make install

cd ..

rm -rf build-gcc
mkdir build-gcc
cd build-gcc
../sources/gcc/configure --target=$TARGET --prefix=$PREFIX --enable-interwork --enable-languages="c" --with-newlib --without-headers --disable-shared --with-gnu-as --with-gnu-ld --disable-nls
make all-gcc -j32
sudo make install-gcc
make all-target-libgcc -j32
sudo make install-target-libgcc

cd ..

rm -rf build-newlib
mkdir build-newlib
cd build-newlib
../sources/newlib/configure --target=$TARGET --prefix=$PREFIX --enable-interwork --enable-multilib --with-gnu-as --with-gnu-ls --disable-libgloss
sed -i "s|RANLIB_FOR_TARGET=$TARGET-ranlib|RANLIB_FOR_TARGET=$PREFIX/bin/$TARGET-ranlib|g" Makefile
make all -j32
sudo make install
cd ..

cd build-gcc
make -j32
sudo make install
cd ..
