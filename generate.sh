

git submodule sync
git submodule update --init

rm -rf build-binutils
mkdir build-binutils
cd build-binutils
../sources/binutils/configure --target=arm-eabi-bt --prefix=/opt/bdk --enable-interwork --enable-multilib --enable-target-optspace --with-float=soft --disable-werror
make -j32

cd ..
