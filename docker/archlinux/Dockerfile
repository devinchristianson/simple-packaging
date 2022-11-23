ARG VERSION=latest
FROM archlinux:${VERSION}

RUN echo "===> Installing tools..." \
    && pacman -Syu --noconfirm ruby \
    && echo "===> Installing fpm..." \
    && gem install --bindir /usr/local/bin fpm \
    && echo "===> Cleaning the system..." \
    && pacman -Scc --noconfirm \
    && rm -rf /var/cache/pacman/pkg/ \
    && echo "===> Adding /src/ work directory..." \
    && mkdir /src

WORKDIR /src/

ENTRYPOINT ["fpm"]