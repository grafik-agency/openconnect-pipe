#!/usr/bin/env bash
#
# Connect to vpn and then deploy using sftp
#
#
# Required globals:
#   SERVER
#   USER
#   VPN_USER
#   VPN_GATEWAY
#   VPN_PASSWORD
#   REMOTE_PATH
#
# Optional globals:
#   LOCAL_PATH
#   PASSWORD
#   SSH_KEY
#   VPN_EXTRA_ARGS
#   SFTP_EXTRA_ARGS
#   DEBUG

set -e
set -o pipefail

grey="\\e[37m"
blue="\\e[36m"
red="\\e[31m"
green="\\e[32m"
reset="\\e[0m"

# Logging, loosely based on http://www.ludovicocaldara.net/dba/bash-tips-4-use-logging-levels/
info() { echo -e "${blue}INFO: $*${reset}"; }
error() { echo -e "${red}ERROR: $*${reset}"; }
debug() { if [[ "${DEBUG}" == "true" ]]; then echo -e "${grey}DEBUG: $*${reset}"; fi }
success() { echo -e "${green}✔ $*${reset}"; }
fail() { echo -e "${red}✖ $*${reset}"; }

SFTP_DEBUG_ARGS=
VPN_DEBUG_ARGS=
## Enable debug mode.
enable_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    info "Enabling debug mode."
    set -x
    SFTP_DEBUG_ARGS="-v"
    VPN_DEBUG_ARGS="-v"
  fi
}

validate() {
    # mandatory parameters
    : VPN_GATEWAY=${VPN_GATEWAY:?'VPN_GATEWAY variable missing.'}
    : VPN_USER=${VPN_USER:?'VPN_USER variable missing.'}
    : VPN_PROTOCOL=${VPN_PROTOCOL:="anyconnect"}
    : VPN_PASSWORD=${VPN_PASSWORD:?'VPN_PASSWORD variable missing.'}
    : SERVER=${SERVER:?'SERVER variable missing.'}
    : USER=${USER:?'USER variable missing.'}
    : PASSWORD =${PASSWORD:?'PASSWORD variable missing.'}
    : REMOTE_PATH=${REMOTE_PATH:?'REMOTE_PATH variable missing.'}
    : LOCAL_PATH=${LOCAL_PATH:="${BITBUCKET_CLONE_DIR}/*"}
    : PORT=${PORT:="22"}
}

handle_artifact() {
    if [[ -z "${ARTIFACT}" ]]; then
        echo ""
    else
        info "Sending $"
        unzip ${ARTIFACT}
    fi
}

vpn_connect() {
    info "Attempting to connect to VPN"
    echo -n ${VPN_PASSWORD} | openconnect \
        --protocol=${VPN_PROTOCOL} \
        --user ${VPN_USER} \
        --passwd-on-stdin \
        --background \
        ${VPN_EXTRA_ARGS} \
        ${VPN_DEBUG_ARGS} \
        --server ${VPN_GATEWAY}

}

setup_ssh_dir() {
    INJECTED_SSH_CONFIG_DIR="/opt/atlassian/pipelines/agent/ssh"
    # The default ssh key with open perms readable by alt uids
    IDENTITY_FILE="${INJECTED_SSH_CONFIG_DIR}/id_rsa_tmp"
    # The default known_hosts file
    KNOWN_HOSTS_FILE="${INJECTED_SSH_CONFIG_DIR}/known_hosts"

    mkdir -p ~/.ssh || debug "adding ssh keys to existing ~/.ssh"
    touch ~/.ssh/authorized_keys

    if [[ -z "${PASSWORD}" ]]; then
      # If given, use SSH_KEY, otherwise check if the default is configured and use it
      if [ "${SSH_KEY}" != "" ]; then
         debug "Using passed SSH_KEY"
         (umask  077 ; echo ${SSH_KEY} | base64 -d > ~/.ssh/pipelines_id)
      elif [ ! -f ${IDENTITY_FILE} ]; then
         error "No default SSH key configured in Pipelines."
         exit 1
      else
         debug "Using default ssh key"
         cp ${IDENTITY_FILE} ~/.ssh/pipelines_id
      fi
    fi

    if [ ! -f ${KNOWN_HOSTS_FILE} ]; then
        error "No SSH known_hosts configured in Pipelines."
        exit 2
    fi

    # copy know_hosts from repo to pipe
    cat ${KNOWN_HOSTS_FILE} >> ~/.ssh/known_hosts
    # fetch host from server and add to known_hosts
    ssh-keyscan -p ${PORT} ${SERVER} >> ~/.ssh/known_hosts
    if [ -f ~/.ssh/config ]; then
        debug "Appending to existing ~/.ssh/config file"
    fi

    if [[ -z "${PASSWORD}" ]]; then
      echo "IdentityFile ~/.ssh/pipelines_id" >> ~/.ssh/config
    fi
    chmod -R go-rwx ~/.ssh/
}

run_pipe() {
    info "Starting SFTP deployment to ${SERVER}:${REMOTE_PATH}..."
    set +e
    if [[ -z "${PASSWORD}" ]]; then
      debug Executing echo \"mput ${LOCAL_PATH}\" \| sftp -b - -rp ${SFTP_DEBUG_ARGS} ${SFTP_EXTRA_ARGS} -P ${PORT} ${USER}@${SERVER}:${REMOTE_PATH}
      echo "mput ${LOCAL_PATH}" | sftp -b - -rp ${SFTP_DEBUG_ARGS} ${SFTP_EXTRA_ARGS} -P ${PORT} ${USER}@${SERVER}:${REMOTE_PATH}
    else
      debug Executing echo \"mput ${LOCAL_PATH}\" \| sshpass -p ${PASSWORD} sftp -o PubkeyAuthentication=no -rp ${SFTP_DEBUG_ARGS} ${SFTP_EXTRA_ARGS} -P ${PORT} ${USER}@${SERVER}:${REMOTE_PATH}
      echo "mput ${LOCAL_PATH}" | sshpass -p ${PASSWORD} sftp -o PubkeyAuthentication=no -rp ${SFTP_DEBUG_ARGS} ${SFTP_EXTRA_ARGS} -P ${PORT} ${USER}@${SERVER}:${REMOTE_PATH}
    fi
    STATUS=$? # status of last command of pipe, i.e. sftp
    set -e

    if [[ "${STATUS}" == "0" ]]; then
      success "Deployment finished."
    else
      fail "Deployment failed."
    fi

    exit $STATUS
}

validate
enable_debug
handle_artifact
if [[ -z "${PASSWORD}" ]]; then
  info "Using SSH."
else
  info "Using PASSWORD."
fi
setup_ssh_dir
run_pipe
