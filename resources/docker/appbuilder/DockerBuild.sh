#!/bin/bash
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

theapp=$1

source ../../../src/${theapp}/buildconfig.sh

printf "\n\e[1mBuilding builder container for %s tagged as %s\e[0m\n" ${theapp} ${buildenv}

cp ../../../src/$1/requirements.txt .
docker build --no-cache -t "${buildenv}" .
rm requirements.txt

if [ "$2" == "push" ]; then
	docker push ${buildenv}
fi
