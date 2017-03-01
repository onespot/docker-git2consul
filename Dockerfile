FROM alpine:3.5
MAINTAINER Richard Bolkey <https://github.com/rbolkey>

# Need testing in order to use gosu https://pkgs.alpinelinux.org/packages?name=gosu
RUN addgroup git2consul && \
    adduser -S -G git2consul git2consul && \
    echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk --update add nodejs git openssh ca-certificates gosu dumb-init sshpass && \
    rm -rf /var/cache/apk/* && \
    npm install git2consul@0.12.13 --global && \
    mkdir -p /etc/git2consul.d

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["git2consul"]
