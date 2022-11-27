ARG VERSION=latest
FROM debian:${VERSION}
RUN export DEBIAN_FRONTEND="noninteractive" \
    && echo "===> Installing tools..." \
    && apt-get -y update \
    && apt-get -y --no-install-recommends install gnupg ruby ruby-dev rubygems python3 python3-pip \
    && echo "===> Installing fpm, mkrepo..." \
    && gem install fpm \
    && pip3 install mkrepo boto3==1.4.1 univers==30.9.0 \
    && echo "===> Cleaning the system..." \
    && apt-get -f -y --auto-remove remove python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "===> Adding /src/ work directory..." \
    && mkdir /src/

WORKDIR /src/

COPY ./gpg-init.sh /gpg-init.sh

ENTRYPOINT ["/gpg-init.sh"]

CMD ["fpm"]