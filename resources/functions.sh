#!/usr/bin/env bash

# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

# This file is sourced from toolmaker.sh and defines all used functions

builder() {

	docker container run -it --rm -v $PWD:/pybuild --workdir /pybuild ${buildenv} $1

}


buildapp() {

	case ${buildmode} in
		dev)
			printf "\n\e[1mBuilding %s in DEV mode.\e[0m\n" ${theapp}
			printf "\n\e[1mRunning PyInstaller...\e[0m\n\n"
			builder "pyinstaller -y\
				--distpath ./work/dist \
				--specpath ./work/ \
				--workpath ./work/build \
				--onefile \
				--clean \
				--log-level INFO \
				${scriptpath}"
			printf "\n\e[1mRunning StaticX...\e[0m\n\n"
			builder "staticx --loglevel INFO work/dist/${theapp} work/dist/${theapp}"
			builder "chmod +x work/dist/${theapp}"
			printf "\n\e[1mFinished! Built:\e[0m\n"
			file work/dist/${theapp}
			;;

		debug)
			printf "\n\e[1mBuilding %s in DEBUG mode.\e[0m\n" ${theapp}
			printf "\n\e[1mRunning PyInstaller...\e[0m\n\n"
			builder "pyinstaller -y\
				--distpath ./work/dist \
				--specpath ./work/ \
				--workpath ./work/build \
				--onefile \
				--clean \
				--log-level DEBUG \
				--debug all \
				${scriptpath}"
			printf "\n\e[1mRunning StaticX...\e[0m\n\n"
			builder "staticx --loglevel INFO work/dist/${theapp} work/dist/${theapp}"
			builder "chmod +x work/dist/${theapp}"
			printf "\n\e[1mFinished! Built:\e[0m\n"
			file work/dist/${theapp}
			;;

		dist)
			printf "\n\e[1mBuilding %s in DIST mode\e[0m\n" ${theapp}
			printf "\n\e[1mRunning PyInstaller...\e[0m\n\n"
			builder "pyinstaller -y\
				--strip \
				--distpath ./work/dist \
				--specpath ./work/ \
				--workpath ./work/build \
				--onefile \
				--clean \
				--log-level DEBUG \
				${scriptpath}"
			printf "\n\e[1mRunning StaticX...\e[0m\n\n"
			builder "staticx --strip --loglevel INFO work/dist/${theapp} bin/${theapp}"
			builder "chmod +x bin/${theapp}"
			builder "rm -rf work/build"
			builder "rm -rf work/dist"
			printf "\n\e[1mFinished! Built:\e[0m\n"
			file bin/${theapp}
			;;

		*)
			printf "\n\e[1mInvalid Build Mode specified!\e[0m\n"
			usage


	esac
}


testapp() {

	builder "work/dist/${theapp} getcert \
		--debug	\
		--cluster ${cluster} \
		--username ${svcusr} \
		--userkey $svckey \
		--cn ${certcn} \
		--host ${certhost} \
		--ks \
		--ks-path ."
	mv {*.pem,*.jks} work/
}


cleanup() {

 rm -rf work/*

}


makeenv() {

	cd resources/docker/appbuilder

	if [ "${buildmode}" == "push" ]; then
		./DockerBuild.sh ${theapp} ${buildmode}
	else
		./DockerBuild.sh ${theapp}
	fi

	cd ../../
}


usage() {
		printf "\n\e[1mAbout:\e[0m\n"
		printf "Simple script that will build or test a python script in a container.\n"
		printf "Will create a correct build container if required.\n"
		printf "Expects that the script lives in the ./<appname> directory with a filename of <appname>.py \n"
		printf "Built scripts are first packed with pyinstaller, and then linked with staticx\n\n"
		printf "\e[33m\e[1mUsage:\e[0m\n"
		printf "$0 {build|test|makeenv|cleanup}\n"
		printf "\t\e[1mbuild\e[0m <app> {dev|debug|dist}\n"
		printf "\t\tBuilds the <app> script with the stated buildmode:\n"
		printf "\t\t\e[1mdev\e[0m:\tleaves all staticx and pyinstaller build artefacts in place in the "work" folder\n"
		printf "\t\t\e[1mdebug\e[0m:\tenables debug mode for everything\n"
		printf "\t\t\e[1mdist\e[0m:\tcleans up everything, disables debug, strips the resulting application,\n"
		printf "\t\t\tand places the built application in the bin directory\n"
		printf "\t\t\e[1mcleanup\e[0m:\tCleans up the work directory\n"
		printf "\n\t\e[1mtest\e[0m <app>\n"
		printf "\t\tTest the stated script. Set application options in resources/testconfig.sh\n"
		printf "\n\t\e[1mmakeenv\e[0m <app> [push]\n"
		printf "\t\tBuilds the container used by this script to actually build the app. Ensure a requirements.txt\n"
		printf "\t\texists in your app src directory containing the required pip3 installable modules.\n"
		printf "\t\t\e[1mpush\e[0m:\tpush the built container to dockerhub. Make sure to configre src/<app>/buildconfig.sh\n"
		printf "\t\t\twith the correct tag.\n"
		printf "\e[0m\n"
}