#!/usr/bin/python3

import os
import sys
import subprocess

proc = subprocess.Popen(['gcc', '-dumpmachine'], stdout=subprocess.PIPE)
native = proc.stdout.read().decode().strip()

proc = subprocess.Popen(['git', 'describe', '--dirty'], stdout=subprocess.PIPE)
version = proc.stdout.read().decode().strip()


print(native)

hosts = {
    "x86_64-linux-gnu": {
        "targets": {
#            "arm-none-eabi": {
#
#            },
            "arm-eabi-bt": {

            },
#            "arm-eabi-bitthunder": {
#
#            },
#            "mips-none-elf": {
#
#            },
        }
    },
    "i686-pc-mingw32": {
        "targets": {
#            #"arm-none-eabi": {
#
#            },
            "arm-eabi-bt": {

            },
#            "mips-none-elf": {
#
#           },
        }
    }
}

env = dict(os.environ)


for k, host in hosts.items():
    for target in host["targets"]:
        env['TARGET'] = target
        env['HOST'] = k
        print("Building a %s toolchain for %s." % (target, k))
        logfile = "output/%s/%s/%s/build.log" % (version, target, k)
        with open(logfile, 'w') as f:
            p = subprocess.Popen(['make'], env=env, stdout=subprocess.PIPE)
            i = 0
            for line in iter(p.stdout.readline, ''):
                #sys.stdout.write(line.decode())
                sys.stdout.write("Logged: %d lines to %s\r" % (i, logfile))
                i = i + 1
                f.write(line.decode())
                f.flush()

        p.wait()
