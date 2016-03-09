#!/bin/bash

TARGETS="x86_64-linux-gnu"
HOSTS="x86_64-linux-gnu"
for T in $TARGETS
do
	echo "* Building toolchains for: $T"
	for H in $HOSTS
	do
		echo "    * Building toolchain for $H"
		TARGET=$T HOST=$H make
	done
done

