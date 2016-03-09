#!/usr/bin/python3

import os
import sys
import json
import collections
import subprocess
import argparse

proc = subprocess.Popen(['gcc', '-dumpmachine'], stdout=subprocess.PIPE)
native = proc.stdout.read().decode().strip()

proc = subprocess.Popen(['git', 'describe', '--dirty'], stdout=subprocess.PIPE)
version = proc.stdout.read().decode().strip()

with open('configs.json') as config_file:
	configs = json.load(config_file, object_pairs_hook=collections.OrderedDict)

print(native)

env = dict(os.environ)

parser = argparse.ArgumentParser()
parser.add_argument('--targets', required=False)
parser.add_argument('--hosts', required=False)

args, unknown = parser.parse_known_args()

target_list = []
host_list = []

if args.targets != None:
	for target in args.targets.split(','):
		target_list.append(target)

if args.hosts != None:
	for host in args.hosts.split(','):
		host_list.append(host)

def get_config_var(name, target, host):
	var = None
	if name in target:
		var = target[name]
	if name in target["hosts"][host]:
		var = target["hosts"][host][name]

	return var
	

def build_host(target_name, target_config, host_name, host_config):
	binutils_config = get_config_var("binutils_config", target, h)
	gcc_config = get_config_var("gcc_config", target, h)
	gcc_bootstrap_config = get_config_var("gcc_bootstrap_config", target, h)

	env['TARGET'] = target_name
	env['HOST'] = host_name
	env['BUILD'] = host_name
			
	if binutils_config != None:
		env['BINUTILS_CONFIG'] = binutils_config
	if gcc_config != None:
		env['GCC_CONFIG'] = gcc_config
	if gcc_bootstrap_config != None:
		env['GCC_BOOTSTRAP_CONFIG'] = gcc_bootstrap_config

	print("Building a %s toolchain for %s." % (target_name, host_name))
	
	p = subprocess.Popen(['make -j16'], env=env, shell=True)
	p.wait()

for k, target in configs["targets"].items():
	if len(target_list) > 0 and k not in target_list:
		print("skipping %s" % k)
		continue	

	if "hosts" in target:
		for h, host in target["hosts"].items():
			if len(host_list) > 0 and h not in host_list:
				continue
			build_host(k, target, h, host)
			

sys.exit(1)

for k, host in hosts.items():
    for target in host["targets"]:
        env['TARGET'] = k
        env['HOST'] = h
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
