# Git Push & Openconnect Bitbucket Pipe

This pipe will connect to a secure vpn to allow pushing
repo files using sftp.

Open connect is currently not working for some hosts. We are working to resolve.
Currently this is just a modifed version of [Bitbucket sftp-deploy pipe](https://bitbucket.org/atlassian/sftp-deploy/src)

## How it works

Add a step to your pipeline and include the pipe like below (replace the values in < >).

```yml
  step:
    name: git-ftp and openconnect
    script:
      - pipe: docker://grafikdev/openconnect-pipe:latest
        variables:
          VPN_USER: $VPN_USER
          VPN_PASSWORD: $VPN_PASSWORD  
          VPN_GATEWAY: $VPN_GATEWAY 
          SERVER: $SERVER
          USER: $USER          
          PASSWORD: $PASSWORD
          # SSH_KEY: '<string>' # Optional.
          # PASSWORD: '<string>' # Optional.
          # EXTRA_ARGS: '<string>' # Optional.
          # DEBUG: '<boolean>' # Optional.
          # PORT: '<string>" # Optional (Default "22").
          # VPN_PROTOCOL: '<string> # Optional (Default "anyconnect").
          # ARTIFACT: '<string>' # Optional (Will default to sending entire repo)
          # LOCAL_PATH: '<strin>' # Defaults to $BITBUCKET_CLONE_DIR

```

## Variables

VPN_USER: username for your VPN, add ths as a repository variable.
VPN_PASSWORD: password for your VPN, add this as a secret variable.
VPN_GATEWAY: Server url, or IP for the VPN. Must have a secure certificate.
SERVER: SFTP server address
USER: SFTP username
PASSWORD: SFTP password

---

Built and maintained by Grafik
