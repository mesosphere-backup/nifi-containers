#!/usr/bin/env bash
# Copyright (c) 2019 Martijn Dekkers, D2iQ.
# Licensed under the Apache 2.0 License
# Martijn Dekkers <mdekkers@d2iq.com>

source functions.sh
source settings.sh

docker build \
	--no-cache \
	--progress plain \
	--build-arg FROMIMAGE=${FROMIMAGE} \
	--build-arg IMGVERSION=${IMAGE_VERSION} \
	--build-arg UID="$DOCKER_UID" \
	--build-arg GID="$DOCKER_GID" \
	--build-arg NIFI_VERSION="${NIFI_VERSION}" \
	--build-arg DOCKERTAG="${DOCKERTAG}" \
		-t "${DOCKERTAG}" \
	. \
	>>${BUILDRUN} 2>&1 &
printhdr "Building Image "; progress "$!"

printhdr "Image Built! "

if [[ $1 == "push" || ${ALWAYSPUSH} == "True" ]]; then
	printhdr "Pushing Image ${DOCKERTAG} to Docker Hub"
	docker push ${DOCKERTAG}
else
	printhdr "Push not requested. Run with $0 push to push to configured Docker Registry"
fi
