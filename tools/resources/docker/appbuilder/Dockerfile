FROM mesosnifi/builder-core:1.1

LABEL maintainer="Martijn Dekkers <mdekkers@d2iq.com>"
LABEL copyright="Copyright (c) 2019 D2iQ, Inc."
LABEL Vendor="D2iQ, Inc."
LABEL version="1.0"
LABEL site="https://www.d2iq.com"

ADD ./requirements.txt /requirements.txt

RUN pip3 install -r requirements.txt
