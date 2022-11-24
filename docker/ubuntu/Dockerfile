ARG VERSION=latest
FROM ubuntu:${VERSION}
RUN export DEBIAN_FRONTEND="noninteractive" \
    && echo "===> Installing tools..." \
    && apt-get -y update \
    && apt-get -y install ruby ruby-dev rubygems build-essential autoconf libtool libarchive-tools rpm binutils \
    && echo "===> Installing fpm..." \
    && gem install fpm \
    && echo "===> Cleaning the system..." \
    && apt-get -f -y --auto-remove remove build-essential autoconf libtool \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "===> Adding /src/ work directory..." \
    && mkdir /src/
    
WORKDIR /src/

COPY ./gpg-init.sh /gpg-init.sh

ENTRYPOINT ["/gpg-init.sh"]

CMD ["fpm"]