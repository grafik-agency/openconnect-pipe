# Git Push & Openconnect Bitbucket Pipe

This pipe will connect to a secure vpn to allow pushing
repo files using git-ftp.

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
          FTP_SERVER: $FTP_SERVER
          FTP_USER: $FTP_USER          
          FTP_PASSWORD: $FTP_PASSWORD
          GIT_EMAIL: <git_email> # notified of backup
          GIT_NAME: <git_name> # can be anything
```

Built and maintained by Grafik
