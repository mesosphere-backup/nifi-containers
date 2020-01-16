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

RUN apt-get update \
    && apt-get install -y jq xmlstarlet procps mc nano telnet unzip w3m links2 ldap-utils vi

ADD unboundid/ /unboundid/
ADD certs /certs/

CMD sleep 100000