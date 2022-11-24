ARG VERSION=latest
FROM fedora:${VERSION}

RUN echo "===> Installing tools..." \
    && dnf install -y ruby-devel gcc make rpmdevtools \
    && echo "===> Installing fpm..." \
    && gem install fpm \
    && echo "===> Cleaning the system..." \
    && dnf clean all \
    && echo "===> Adding /src/ work directory..." \
    && mkdir /src

WORKDIR /src/

COPY ./gpg-init.sh /gpg-init.sh

ENTRYPOINT ["/gpg-init.sh"]
CMD ["fpm"]