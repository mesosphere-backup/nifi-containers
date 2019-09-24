#!/bin/bash
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

thetag="$(cat tag.txt)"

cp ../../src/$1/requirements.txt .
printf "\n\e[1mBuilding builder-core container %s\e[0m\n" ${thetag}

docker build --no-cache -t "${thetag}" .

if [ "$1" == "push" ]; then
	docker push ${thetag}
fi

