#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

__usage="
Usage: fetch [OPTIONS]
Fetch build sources.

Options: 
  -b, --board BOARD                   The board name.
  -g, --githubmirror GITHUB_MIRROR    Use GitHub mirror.
  -h, --help                          Show command help.
"

help()
{
    echo "$__usage"
    exit $1
}

default_param() {
    BOARD=avaota-a1
    GITHUB_MIRROR=none
}

parseargs()
{
    if [ "x$#" == "x0" ]; then
        return 0
    fi

    while [ "x$#" != "x0" ];
    do
        if [ "x$1" == "x-h" -o "x$1" == "x--help" ]; then
            return 1
        elif [ "x$1" == "x" ]; then
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--board" ]; then
            BOARD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-i" -o "x$1" == "x--githubmirror" ]; then
            GITHUB_MIRROR=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

clone_linux()
{
    if [ -d ${workspace}/linux ];then
        pushd ${workspace}/linux
        git remote -v update
        remote_url=$(git config --get remote.origin.url)
        current_branch=$(git symbolic-ref --short HEAD)
        if [[ "${remote_url}" == "${LINUX_REPO}" && "${current_branch}" == "${LINUX_BRANCH}" ]];then
            git pull
        else
            rm -rf ${workspace}/linux
            cd ${workspace}
            git clone --depth=1 ${LINUX_REPO} -b ${LINUX_BRANCH} linux
        fi
        popd
    else
        cd ${workspace}
        git clone --depth=1 ${LINUX_REPO} -b ${LINUX_BRANCH} linux
    fi
}

clone_syterkit()
{
    if [ -d ${workspace}/SyterKit ];then
    	pushd ${workspace}/SyterKit
        rm -rf build-${BOARD}
        git pull
        popd
    else
        git clone --depth=1 ${SYTERKIT_REPO} -b ${SYTERKIT_BRANCH} SyterKit
    fi
}

workspace=$(pwd)
cd ${workspace}

default_param
parseargs "$@" || help $?

source ../boards/${BOARD}.conf
source ../boot/SyterKit/SyterKit.conf

if [[ ${LINUX_REPO:0:18} == "https://github.com" && ${GITHUB_MIRROR} != "none" ]];then
    echo "Use GitHub Proxy: ${GITHUB_MIRROR}/${LINUX_REPO}"
    LINUX_REPO=${GITHUB_MIRROR}/${LINUX_REPO}
fi

clone_syterkit
clone_linux
