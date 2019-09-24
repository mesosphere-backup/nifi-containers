#!/usr/bin/env bash


# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

# Builds a python3 script inside a docker container for testing and distribution.

source resources/functions.sh
source resources/testconfig.sh

theapp=$2
buildmode=$3
scriptpath="src/${theapp}/${theapp}.py"

case $1 in
	build)
		source src/${theapp}/buildconfig.sh
		buildapp
		;;

	test)
		source src/${theapp}/buildconfig.sh
		setconfig
		testapp
		;;

	makeenv)
		source src/${theapp}/buildconfig.sh
		makeenv
		;;

	cleanup)
		cleanup
		;;

	*)
		usage
		;;

esac