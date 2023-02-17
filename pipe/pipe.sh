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
REMOTE_PATH=${REMOTE_PATH:?'REMOTE_PATH variable missing.'}
LOCAL_PATH=${LOCAL_PATH:="${BITBUCKET_CLONE_DIR}/*"}


info "Running OpenConnect pipe..."

vpn_connect() {
    info "Attempting to connect to VPN"
    echo -n ${VPN_PASSWORD} | openconnect \
        --protocol=${VPN_PROTOCOL} \
        --user ${VPN_USER} \
        --passwd-on-stdin \
        --background \
        ${VPN_GATEWAY} \
        -v

    if [[ "${STATUS}" == "0" ]]; then
      success "Deployment finished."
    else
      fail "Deployment failed."
    fi
}

setup_ssh_dir() {
  INJECTED_SSH_CONFIG_DIR="/opt/atlassian/pipelines/agent/ssh"
  # The default ssh key with open perms readable by alt uids
  IDENTITY_FILE="${INJECTED_SSH_CONFIG_DIR}/id_rsa_tmp"
  # The default known_hosts file
  KNOWN_HOSTS_FILE="${INJECTED_SSH_CONFIG_DIR}/known_hosts"

  mkdir -p ~/.ssh || debug "adding ssh keys to existing ~/.ssh"
  touch ~/.ssh/authorized_keys

  if [[ -z "${FTP_PASSWORD}" ]]; then
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

  cat ${KNOWN_HOSTS_FILE} >> ~/.ssh/known_hosts
  if [ -f ~/.ssh/config ]; then
      debug "Appending to existing ~/.ssh/config file"
  fi

  if [[ -z "${FTP_PASSWORD}" ]]; then
    echo "IdentityFile ~/.ssh/pipelines_id" >> ~/.ssh/config
  fi
  chmod -R go-rwx ~/.ssh/
}

run_pipe() {
    info "Starting SFTP deployment to ${SERVER}:${REMOTE_PATH}..."
    set +e
    if [[ -z "${FTP_PASSWORD}" ]]; then
      debug Executing echo \"mput ${LOCAL_PATH}\" \| sftp -b - -rp ${USER}@${SERVER}:${REMOTE_PATH}
      echo "mput ${LOCAL_PATH}" | sftp -b - -rp ${USER}@${SERVER}:${REMOTE_PATH}
    else
      debug Executing echo \"mput ${LOCAL_PATH}\" \| sshpass -p ${FTP_PASSWORD} sftp -o PubkeyAuthentication=no -rp ${USER}@${SERVER}:${REMOTE_PATH}
      echo "mput ${LOCAL_PATH}" | sshpass -p ${FTP_PASSWORD} sftp -o PubkeyAuthentication=no -rp ${USER}@${SERVER}:${REMOTE_PATH}
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

if [[ -z "${FTP_PASSWORD}" ]]; then
  info "Using SSH."
else
  info "Using PASSWORD."
fi
setup_ssh_dir
sftp_deploy
