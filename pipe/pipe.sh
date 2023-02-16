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


info "Running OpenConnect pipe..."

info "Configuring git..."

git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_NAME}"

git_ftp_configure() {
    info "Configuring git-ftp"
    git clone https://github.com/git-ftp/git-ftp.git
    cd git-ftp

    # choose the newest release
    tag="$(git tag | grep '^[0-9]*\.[0-9]*\.[0-9]*$' | tail -1)"

    # checkout the latest tag
    git checkout "$tag"
    make install

    git config git-ftp.url "${FTP_SERVER}"
    git config git-ftp.user "${FTP_USER}"
    git config git-ftp.password "${FTP_PASSWORD}"
    cd
}
git_ftp_configure

vpn_connect() {
    info "Attempting to connect to VPN"
    echo -n ${VPN_PASSWORD} | openconnect \
        --protocol=${VPN_PROTOCOL} \
        --user ${VPN_USER} \
        --passwd-on-stdin \
        --background \
        --servercert ${VPN_SERVER_CERT} \
        ${VPN_GATEWAY}


git_ftp_push() {
    info "Attempting to push files..."
    git ftp init
    git ftp catchup
    git add .
    git commit -m "Adding files..."
    git ftp push
}
git_ftp_push


success "Successfully pushed files."
