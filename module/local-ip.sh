#!/bin/sh

set -eu

script_dir=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
# shellcheck source=network-common.sh
. "$script_dir/network-common.sh"

network_field prefsrc
