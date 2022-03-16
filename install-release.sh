#!/usr/bin/env bash

# The files installed by the script conform to the Filesystem Hierarchy Standard:
# https://wiki.linuxfoundation.org/lsb/fhs

# The URL of the script project is:
# https://github.com/libsgh/PanIndex-install

# The URL of the script is:
# https://raw.githubusercontent.com/libsgh/PanIndex-install/main/install.sh

# export WORKING_DIRECTORY='/usr/local/etc/PanIndex'
WORKING_DIRECTORY=${WORKING_DIRECTORY:-/usr/local/etc/PanIndex}

if [[ -f '/etc/systemd/system/PanIndex.service' ]] && [[ -f '/usr/local/bin/PanIndex' ]]; then
  PAN_INDEX_IS_INSTALLED_BEFORE_RUNNING_SCRIPT=1
else
  PAN_INDEX_IS_INSTALLED_BEFORE_RUNNING_SCRIPT=0
fi

# PanIndex current version
CURRENT_VERSION=''

# PanIndex latest release version
RELEASE_LATEST_VERSION=''

# install
INSTALL='0'

# remove
REMOVE='0'

# help
HELP='0'

# check
CHECK='0'

# color code
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message

VDIS=""

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
CURL_CMD=$(command -v curl 2>/dev/null)
TAR_CMD=$(command -v tar 2>/dev/null)
#SERVICE_CMD=$(command -v service 2>/dev/null)

PROXY=""

CHANNEL="/latest"

YES="0"

CONFIRM_MSG=""

CEcho(){
  # shellcheck disable=SC2145
  echo -e "\033[${1}${@:2}\033[0m" 1>& 2
}

show_help(){
  cat - 1>& 2 << EOF
./install-release.sh [-h] [-i] [-r] [-c] [-p] [-a] [-pre]
  -h, --help            Show help.
  -i, --install         Install or update.
  -r, --remove          Remove installed PanIndex.
  -c, --check           Check for update.
  -p, --proxy           To download through a proxy server, use -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128 etc.
  -a, --auto            Auto install or update without confirm.
  -pre                  Change channel to pre-release.
EOF
}

download_PanIndex(){
  mkdir -p "$WORKING_DIRECTORY"
	local TARGET_FILE="${WORKING_DIRECTORY}/PanIndex.tar.gz"
    DOWNLOAD_LINK="https://github.com/libsgh/PanIndex/releases/download/${RELEASE_LATEST_VERSION}/PanIndex-linux-${VDIS}.tar.gz"
    CEcho ${BLUE} "info: Downloading PanIndex: ${DOWNLOAD_LINK}"
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o "${TARGET_FILE}" ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        CEcho ${RED} "error: Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

archAffix(){
    case "${1:-"$(uname -m)"}" in
        i686|i386)
            echo '386'
        ;;
        x86_64|amd64)
            echo 'amd64'
        ;;
		armv5tel)
            echo 'arm32-v5'
        ;;
		armv6l)
        		echo 'arm32-v6'
        ;;
        *armv7*|armv7l)
            echo 'arm32-v7'
        ;;
        *armv8*|aarch64)
            echo 'arm64'
        ;;
        *)
            return 1
        ;;
    esac

	return 0
}

normalizeVersion() {
    if [ -n "$1" ]; then
        case "$1" in
            v*)
                echo "$1"
            ;;
            *)
                echo "v$1"
            ;;
        esac
    else
        echo ""
    fi
}

# 1: new version. 0: no. 2: not installed. 3: check failed. 4: don't check.
get_version(){
    if [[ -n "$VERSION" ]]; then
        RELEASE_LATEST_VERSION="$(normalizeVersion "$VERSION")"
        return 4
    else
        #get the latest release
        TAG_URL="https://api.github.com/repos/libsgh/PanIndex/releases${CHANNEL}"
        RELEASE_LATEST_VERSION="$(normalizeVersion "$(curl ${PROXY} \
            -H "Accept: application/json" \
            -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:74.0) Gecko/20100101 Firefox/74.0" \
            -s "${TAG_URL}" --connect-timeout 20 | awk -F'[ "]+' '$0~"tag_name"{print $4;exit}' )")"

        [ ! -f /usr/local/bin/PanIndex ] && return 2
        VER="$(/usr/local/bin/PanIndex -config_query=version)"
        RETVAL=$?
        CURRENT_VERSION="$(normalizeVersion "$VER")"

        if [[ $? -ne 0 ]] || [[ $RELEASE_LATEST_VERSION == "" ]]; then
            CEcho ${RED} "error: Failed to fetch release information. Please check your network or try again."
            return 3
        elif [[ $RETVAL -ne 0 ]];then
            return 2
        elif [[ $RELEASE_LATEST_VERSION != $CURRENT_VERSION ]];then
            return 1
        fi
        return 0
    fi
}

check_for_update(){
  CEcho ${BLUE} "info: Checking for update."
  get_version
  RETVAL="$?"
  if [[ $RETVAL -eq 1 ]]; then
        CEcho ${BLUE} "info: Found new version ${RELEASE_LATEST_VERSION} for PanIndex.(Current version:$CURRENT_VERSION)"
        return 1
  elif [[ $RETVAL -eq 0 ]]; then
        CEcho ${BLUE} "info: No new version. Current version is ${RELEASE_LATEST_VERSION}."
        return 0
  elif [[ $RETVAL -eq 2 ]]; then
        CEcho ${YELLOW} "warn: No PanIndex installed."
        CEcho ${BLUE} "info: The newest version for PanIndex is ${RELEASE_LATEST_VERSION}."
        return 1
  fi
  return 0
}

judgment_parameters() {
  while [[ "$#" -gt '0' ]]; do
    case "$1" in
        -p|--proxy)
        PROXY="-x ${2}"
        shift
        ;;
        -pre)
        CHANNEL=""
        shift
        ;;
        -a|--auto)
        YES="1"
        ;;
		-i|--install)
        INSTALL="1"
        ;;
        -h|--help)
        HELP="1"
        ;;
        -c|--check)
        CHECK="1"
        ;;
        -r|--remove)
        REMOVE="1"
        ;;
        *)
        # unknown option
        ;;
    esac
    shift # past argument or value
  done
}

confirm(){
 if [[ $YES -eq 1 ]]; then
 return 1
 fi
 read -r -p "$CONFIRM_MSG" input

 case $input in
    [yY][eE][sS]|[yY])
		return 1
		;;

    [nN][oO]|[nN])
		return 0
       	;;

    *)
		echo "Invalid input..."
		exit 1
		;;
 esac
 return 0
}

start_install_pan_index(){
	local ARCH=$(uname -m)
	if [[ $UID -ne 0 ]]; then
		CEcho ${YELLOW} "warn: You must run as root user."
		exit 0
	fi
	VDIS="$(archAffix)"
	if [[ -n "$VDIS" ]]; then
		check_for_update
		CU="$?"
		if [[ $CU -ne 0 ]]; then
			CONFIRM_MSG="Are you sure to install it ? [Y/n] "
			confirm
			CI="$?"
			if [[ $CI -eq 1 ]]; then
				install_pan_index
				RETVAL="$?"
				if [[ $RETVAL -eq 1 ]]; then
					install_pan_index_service
					if [[ $? -eq 1 ]]; then
						start_pan_index
						if [[ $? -eq 1 ]]; then
							CEcho ${GREEN} "info: Congratulations! PanIndex $RELEASE_LATEST_VERSION is installed successfully."
							CEcho ${GREEN} "info: Now you can access the address http://127.0.0.1:5238 to configure your PanIndex. The default password is PanIndex."
						fi
					fi   
				fi
			fi
		fi
	else
		CEcho ${RED} "error: The architecture $ARCH is not supported."
	fi
}

install_pan_index(){
	download_PanIndex
	RETVAL="$?"
	if [[ $RETVAL -eq 0 ]] ; then
		CEcho ${BLUE} "info: Extracting PanIndex package to ${WORKING_DIRECTORY}."
		mkdir -p "${WORKING_DIRECTORY}"
		tar --no-same-owner -zxf "${WORKING_DIRECTORY}/PanIndex.tar.gz" -C ${WORKING_DIRECTORY}
		rm -rf "${WORKING_DIRECTORY}/README.md" "${WORKING_DIRECTORY}/LICENSE" "${WORKING_DIRECTORY}/PanIndex.tar.gz"
		cat > "${WORKING_DIRECTORY}/config.json" << EOF
{
  "host": "0.0.0.0",
  "port": 5238,
  "log_level": "info",
  "data_path": "${WORKING_DIRECTORY}/data",
  "cert_file": "",
  "key_file": "",
  "config_query": "",
  "db_type": "sqlite",
  "dsn": "${WORKING_DIRECTORY}/data/data.db"
}
EOF
		mv "${WORKING_DIRECTORY}/PanIndex*" /usr/local/bin/PanIndex
		chmod +x '/usr/local/bin/PanIndex'
		CEcho ${BLUE} "info: Move PanIndex to /usr/local/bin."
		return 1
	fi
	return 0
}

install_pan_index_service(){
	if [[ ! -f "/etc/systemd/system/PanIndex.service" ]]; then
		cat > /etc/systemd/system/PanIndex.service << EOF
[Unit]
Description=PanIndex Service
Documentation=https://libsgh.github.io/PanIndex/
After=network.target

[Service]
User=root
WorkingDirectory=${WORKING_DIRECTORY}
ExecStart=/usr/local/bin/PanIndex -c=${WORKING_DIRECTORY}/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target  
EOF
		systemctl daemon-reload
		systemctl enable PanIndex.service
		CEcho ${GREEN} "info: PanIndex.service installed successfully."
	else
		CEcho ${BLUE} "info: PanIndex.service already exist."
	fi
	return 1
}

start_pan_index(){
	if [[ -f "/etc/systemd/system/PanIndex.service" ]]; then
		systemctl restart PanIndex.service
		return 1
	else
		CEcho ${GREEN} "warn: /etc/systemd/system/PanIndex.service does not exist."
	fi
	return 0
}

stop_pan_index(){
	if [[ -f "/etc/systemd/system/PanIndex.service" ]]; then
		systemctl stop PanIndex.service
		systemctl disable PanIndex.service
		systemctl daemon-reload
		return 1
	else
		CEcho ${YELLOW} "warn: /etc/systemd/system/PanIndex.service does not exist."
	fi
    return 0
}

remove_pan_index(){
	stop_pan_index
	if [[ $? -eq 1 ]]; then
		rm -rf /etc/systemd/system/PanIndex.service
		CEcho ${GREEN} "info: /etc/systemd/system/PanIndex.service already removed."
	fi
	if [[ -f "/usr/local/bin/PanIndex" ]]; then
		rm -rf /usr/local/bin/PanIndex
		CEcho ${GREEN} "info: /usr/local/bin/PanIndex already removed."
	else
		CEcho ${YELLOW} "warn: /usr/local/bin/PanIndex does not exist."
	fi
	if [[ -d "$WORKING_DIRECTORY" ]]; then
		YES="0"
		CONFIRM_MSG="Are you sure to remove working directory? You will lose PanIndex data .Input N to skip this operation. [Y/n] "
		confirm
		if [[ $? -eq 1 ]]; then
			rm -rf "$WORKING_DIRECTORY"
			CEcho ${GREEN} "info: $WORKING_DIRECTORY already removed."
		fi
	else
		CEcho ${YELLOW} "warn: $WORKING_DIRECTORY does not exist."
	fi
	CEcho ${GREEN} "info: All installed files have been removed."
}

check_environment(){
  if [[ ! -n "$TAR_CMD" ]]; then
    CEcho ${RED} "error: tar command not found."
    return 0
  elif [[ ! -n "$CURL_CMD" ]]; then
    CEcho ${RED} "error: curl command not found."
    return 0
  elif [[ ! -n "$SYSTEMCTL_CMD" ]]; then
    CEcho ${RED} "error: systemctl command not found."
    return 0
  else
    CEcho ${BLUE} "info: The environment is ok."
    return 1
  fi
  return 1
}

main(){
  judgment_parameters "$@"
  # Parameter information
  [[ "$HELP" -eq '1' ]] && show_help && return
  check_environment
  [[ $? -eq 0 ]] && return
  [[ "$CHECK" -eq '1' ]] && check_for_update && return
  [[ "$INSTALL" -eq '1' ]] && start_install_pan_index && return
  [[ "$YES" -eq '1' ]] && start_install_pan_index && return
  [[ "$REMOVE" -eq '1' ]] && remove_pan_index && return
}
main "$@"