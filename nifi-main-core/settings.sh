#!/usr/bin/env bash

NIFI_VERSION="1.9.2"
FROMIMAGE_VERSION="8-jre"
DOCKERTAG_VERSION="-4"

## Base settings
printhdr "Image Builder Settings:"
FROMIMAGE="openjdk:${FROMIMAGE_VERSION}"; printmsg "Docker FROM" "${FROMIMAGE}"
DOCKERTAG="mesosphere/nifi:main-core-${NIFI_VERSION}${DOCKERTAG_VERSION}"; printmsg "Setting Tag"  "${DOCKERTAG}"
IMAGE_VERSION="${NIFI_VERSION}${DOCKERTAG_VERSION}"; printmsg "Version" "${IMAGE_VERSION}"
ALWAYSPUSH="False"; printmsg "Always Push" "${ALWAYSPUSH}"

## Image specific settings
printhdr "Image Settings:"
DOCKER_UID=1000; printmsg "Docker UID" ${DOCKER_UID}
DOCKER_GID=1000; printmsg "Docker GID" ${DOCKER_GID}
NIFI_TAG="apache/nifi:${NIFI_VERSION}"; printmsg "NiFi Tag" ${NIFI_TAG}
printmsg "NiFi Version" ${NIFI_VERSION}
MIRROR="https://archive.apache.org/dist"; printmsg "NiFi Mirror" ${MIRROR}
MIRROR_BASE_URL="http://192.168.86.21:8000"; printmsg "NiFi Local Mirror" ${MIRROR_BASE_URL}
