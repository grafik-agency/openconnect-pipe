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
          # VPN_PROTOCOL: '<string>" # Optional (Default "anyconnect").
```

Built and maintained by Grafik
