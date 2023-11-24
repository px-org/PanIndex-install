# PanIndex-install

Bash script for installing PanIndex in operating systems such as CentOS / Debian that support systemd

Please run it as a root user.

```
installed service: /etc/systemd/system/PanIndex.service
installed executable file: /usr/local/bin/PanIndex
installed working directory(data): /usr/local/etc/PanIndex
```

### Install or Update (from release or pre release, default release)
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -i
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -i -pre
```

### Help
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -h
```

### Check for update
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -c
```

### Remove PanIndex
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -r
```

### Install without confirm
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -a
```

### Install Pre-release
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -a -pre
```

### Install with proxy
```
# bash <(curl -L https://github.com/px-org/PanIndex-install/raw/main/install-release.sh) -i -p=socks5://127.0.0.1:1089
```

### Change working directory

```
# export WORKING_DIRECTORY='/usr/local/etc/PanIndex'
```