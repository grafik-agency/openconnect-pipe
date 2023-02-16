#!/usr/bin/env bash
#
# Connect to vpn and then deploy using git-ftp
#
# Required globals:
#   VPN_USER
#   VPN_GATEWAY
#   VPN_PASSWORD
#   FTP_SERVER
#   FTP_USER
#   FTP_PASSWORD
#   GIT_EMAIL
#   GIT_NAME

source "$(dirname "$0")/common.sh"

# mandatory parameters
VPN_USER=${VPN_USER:?'VPN_USER variable missing.'}
VPN_PASSWORD=${VPN_PASSWORD:?'VPN_PASSWORD variable missing.'}
VPN_GATEWAY=${VPN_GATEWAY:?'VPN_GATEWAY variable missing.'}
VPN_PROTOCOL=${VPN_PROTOCOL:?'VPN_PROTOCOL variable missing.'}
VPN_SERVER_CERT=${VPN_SERVER_CERT:?'VPN_SERVER_CERT variable missing.'}
FTP_SERVER=${FTP_SERVER:?'FTP_SERVER variable missing.'}
FTP_USER=${FTP_USER:?'FTP_USER variable missing.'}
FTP_PASSWORD=${FTP_PASSWORD:?'FTP_PASSWORD variable missing.'}
GIT_NAME=${GIT_NAME:?'GIT_NAME variable missing.'}
GIT_EMAIL=${GIT_EMAIL:?'GIT_EMAIL variable missing.'}
ARTIFACT=${ARTIFACT:?'ARTIFACT variable missing.'}


info "Running OpenConnect pipe..."
curl -V

configure_git() {
    info "Configuring git"
    git config --global user.email "${GIT_EMAIL}"
    git config --global user.name "${GIT_NAME}"
    mkdir deploy
    mv ${ARTIFACT} deploy
    cd deploy
    git init
    unzip -o ${ARTIFACT}
    rm -rf ${ARTIFACT}
    ls
    git add $BITBUCKET_REPO_SLUG 
    git branch -M master
    git commit -m "$BITBUCKET_COMMIT"
    cd ../
}
configure_git

git_ftp_configure() {
    info "Configuring git-ftp"
    git clone https://github.com/git-ftp/git-ftp.git
    cd git-ftp

    # choose the newest release
    tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"

    # checkout the latest tag
    git checkout "$tag"
    make install

    cd ../
}
git_ftp_configure

vpn_connect() {
    info "Attempting to connect to VPN"
    echo -n ${VPN_PASSWORD} | openconnect \
        --protocol=${VPN_PROTOCOL} \
        --user ${VPN_USER} \
        --passwd-on-stdin \
        --background \
        ${VPN_GATEWAY} \
        -v
}

git_ftp_push() {
    info "Attempting to push files..."
    cd deploy
    pwd
    git ftp init --user ${FTP_USERNAME} --passwd ${FTP_PASSWORD} ${FTP_SERVER}
    git ftp catchup
    git ftp push
}
git_ftp_push


success "Successfully pushed files."
