#!/usr/bin/env bash

FROMIMAGE_VERSION="8-jre"
DOCKERTAG_VERSION="1.0"

## Base settings
printhdr "Image Builder Settings:"
FROMIMAGE="openjdk:${FROMIMAGE_VERSION}"; printmsg "Docker FROM" "${FROMIMAGE}"
DOCKERTAG="mesosnifi/java-diag:${DOCKERTAG_VERSION}"; printmsg "Setting Tag"  "${DOCKERTAG}"
IMAGE_VERSION="${DOCKERTAG_VERSION}"; printmsg "Version" "${IMAGE_VERSION}"
ALWAYSPUSH="False"; printmsg "Always Push" "${ALWAYSPUSH}"

## Image specific settings
printhdr "Image Settings:"
printmsg "N/A"