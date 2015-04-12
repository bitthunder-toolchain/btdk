#!/bin/bash

TARGETS="mips-none-elf"
HOSTS="$(gcc -dumpmachine)"

for T in $TARGETS
do
	echo "* Building toolchains for: $T"
	for H in $HOSTS
	do
		echo "    * Building toolchain for $H"
		TARGET=$T HOST=$H make -j12
	done
done

