FROM archlinux:latest

RUN pacman -Syu
RUN pacman-key --init
RUN pacman -S \
    bash \
    zip \
    openssh \
    grep \
    openssl \
    git \
    openconnect

COPY pipe /
COPY pipe.yml README.md /
RUN wget -P / https://bitbucket.org/bitbucketpipelines/bitbucket-pipes-toolkit-bash/raw/0.4.0/common.sh

RUN chmod a+x /*.sh

ENTRYPOINT ["/pipe.sh"]
