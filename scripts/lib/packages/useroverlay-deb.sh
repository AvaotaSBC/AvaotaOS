#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# This file is a part of the Avaota Build Framework
# https://github.com/AvaotaSBC/AvaotaOS/

# gen_md5 <file> <path>
gen_md5(){
pushd $2
find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -r0 md5sum > $1
popd
}
