# SFTP & Openconnect Bitbucket Pipe

This pipe will connect to a secure vpn to allow pushing
repo files using sftp.

Open connect is currently not working for some hosts. We are working to resolve.
Currently this is just a modifed version of [Bitbucket sftp-deploy pipe](https://bitbucket.org/atlassian/sftp-deploy/src)

## How it works

Add a step to your pipeline and include the pipe like below (replace the values in < >).

```yml
  step:
    name: sftp and openconnect
    script:
      - pipe: docker://grafikdev/openconnect-pipe:latest
        variables:
          VPN_USER: $VPN_USER
          VPN_PASSWORD: $VPN_PASSWORD
          VPN_GATEWAY: $VPN_GATEWAY
          SERVER: $SERVER
          USER: $USER
          # SSH_KEY: '<string>' # Optional.
          # PASSWORD: '<string>' # Optional.
          # VPN_EXTRA_ARGS: '<string>' # Optionally pass in additional flags for openconnect.
          # SFTP_EXTRA_ARGS: '<string>' # Optionally pass in additional flags for sftp.
          # DEBUG: '<boolean>' # Optional.
          # PORT: '<string>" # Optional (Default "22").
          # VPN_PROTOCOL: '<string>' # Optional (Default "anyconnect").
          # ARTIFACT: '<string>' # Optional (Will default to sending entire repo)
          # LOCAL_PATH: '<string>' # Defaults to $BITBUCKET_CLONE_DIR

```

## Variables

### Required

- VPN_USER: username for your VPN, add ths as a repository variable.
- VPN_PASSWORD: password for your VPN, add this as a secret variable.
- VPN_GATEWAY: Server url, or IP for the VPN. Must have a secure certificate.
- SERVER: SFTP server address
- USER: SFTP username
- PASSWORD: SFTP password

### Optional

- SSH_KEY
- PASSWORD
- VPN_EXTRA_ARGS
- SFTP_EXTRA_ARGS
- DEBUG
- PORT
- VPN_PROTOCOL
- ARTIFACT
- LOCAL_PATH

---

Built and maintained by Grafik
