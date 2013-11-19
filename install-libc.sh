#!/bin/bash

DIR=$(pwd)
PREFIX=${1}
TARGET=${2}

#find ${DIR}/build-newlib -name "libc.a" | sed "s|${DIR}/build-newlib/|${1}/|g" | sed "s|${TARGET}|${TARGET}/lib|g" | sed "s|newlib/||g" | grep -v libc/libc.a

SOURCES=$(find ${DIR}/build-newlib -name "libc.a" | grep -v libc/libc.a)
DESTS=$(echo ${SOURCES} | sed "s|${DIR}/build-newlib/|${1}/|g" | sed "s|${TARGET}|${TARGET}/lib|g" | sed "s|newlib/||g")

while read src dst; do
	sudo cp -v $src $dst
done < <( paste <( echo $SOURCES | tr ' ' '\n'; ) <( echo $DESTS | tr ' ' '\n'; ); )


