# Copyright (c) 2019 D2iQ.
# Licensed under the Apache 2.0 License

ARG FROMIMAGE
FROM ${FROMIMAGE}
ARG IMGVERSION

LABEL maintainer="Martijn Dekkers <mdekkers@d2iq.com>"
LABEL copyright="Copyright (c) 2019 D2iQ, Inc."
LABEL vendor="D2iQ, Inc."
LABEL version=${IMGVERSION}
LABEL site="https://www.d2iq.com"

ARG NIFI_VERSION=${NIFI_VERSION}
ARG BASE_URL=${MIRROR}
ARG MIRROR_BASE_URL=${MIRROR_BASE_URL:-${BASE_URL}}
ARG NIFI_BINARY_PATH=${NIFI_BINARY_PATH:-/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip}
ARG NIFI_TOOLKIT_BINARY_PATH=${NIFI_TOOLKIT_BINARY_PATH:-/nifi/${NIFI_VERSION}/nifi-toolkit-${NIFI_VERSION}-bin.zip}

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME ${NIFI_BASE_DIR}/nifi-current
ENV NIFI_TOOLKIT_HOME ${NIFI_BASE_DIR}/nifi-toolkit-current

##### DC/OS Permissive Mode #####
# Setup NiFi user and create necessary directories
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} nifi || groupmod -n nifi `getent group ${GID} | cut -d: -f1` \
    && useradd --shell /bin/bash -u ${UID} -g ${GID} -m nifi \
    && mkdir -p ${NIFI_BASE_DIR} \
    && chown -R nifi:nifi ${NIFI_BASE_DIR} \
    && apt-get update \
    && apt-get install -y jq xmlstarlet procps

USER nifi

##### DC/OS Strict Mode #####
# ARG UID=99
# ARG GID=99
#RUN usermod -u 99 nobody && groupmod -g 99 nogroup
#
#RUN mkdir -p ${NIFI_BASE_DIR} \
#    && chown -R nobody:nogroup ${NIFI_BASE_DIR} \
#    && apt-get update \
#    && apt-get install -y jq xmlstarlet procps
#USER nobody

# Download, validate, and expand Apache NiFi Toolkit binary.
RUN curl -fSL ${MIRROR_BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH} -o ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && echo "$(curl ${MIRROR_BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH}.sha256) *${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip" | sha256sum -c - \
    && unzip ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip -d ${NIFI_BASE_DIR} \
    && rm ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && mv ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION} ${NIFI_TOOLKIT_HOME} \
    && ln -s ${NIFI_TOOLKIT_HOME} ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}

RUN mkdir -p ${NIFI_TOOLKIT_HOME}/work

WORKDIR /opt/nifi/nifi-toolkit-current/work
