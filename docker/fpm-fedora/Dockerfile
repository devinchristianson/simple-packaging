ARG VERSION=latest
FROM fedora:${VERSION}

RUN echo "===> Installing tools..." \
    && dnf install -y ruby-devel gcc make rpm-build squashfs-tools \
    && dnf module -y install python39 \
    && echo "===> Installing fpm, mkrepo..." \
    && gem install fpm \
    && pip3 install mkrepo boto3==1.4.1 univers==30.9.0 \
    && echo "===> Cleaning the system..." \
    && dnf remove -y gcc make\
    && dnf clean all \
    && echo "===> Adding /src/ work directory..." \
    && mkdir /src

WORKDIR /src/

COPY ./gpg-init.sh /gpg-init.sh

ENTRYPOINT ["/gpg-init.sh"]

CMD ["fpm"]