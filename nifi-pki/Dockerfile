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

ARG UID=1000
ARG GID=1000

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME ${NIFI_BASE_DIR}/nifi-current
ENV NIFI_LOG_DIR=${NIFI_HOME}/logs
ENV NIFI_PID_DIR=${NIFI_HOME}/run

ADD start.sh ${NIFI_BASE_DIR}/nifi-toolkit-current/bin/start.sh

USER nifi

WORKDIR ${NIFI_BASE_DIR}/nifi-toolkit-current/work

CMD ["../bin/start.sh"]
