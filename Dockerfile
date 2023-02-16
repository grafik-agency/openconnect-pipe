FROM alpine

RUN apk add --update --no-cache \
    bash \
    openssl \
    make \
    git \
    openconnect

COPY pipe /
COPY pipe.yml README.md /
RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

RUN chmod a+x /*.sh

ENTRYPOINT ["/pipe.sh"]
