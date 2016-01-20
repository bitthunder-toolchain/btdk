#!/bin/bash

TARGETS="arm-eabi-bt"
HOSTS="x86_64-linux-gnu i686-pc-mingw32"
for T in $TARGETS
do
	echo "* Building toolchains for: $T"
	for H in $HOSTS
	do
		echo "    * Building toolchain for $H"
		TARGET=$T HOST=$H make
	done
done

