FROM alpine:3.5
MAINTAINER Richard Bolkey <https://github.com/rbolkey>

RUN apk --update add nodejs git openssh ca-certificates dumb-init sshpass && \
    rm -rf /var/cache/apk/* && \
    npm install git2consul@0.12.13 --global && \
    mkdir -p /etc/git2consul.d

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["git2consul"]
