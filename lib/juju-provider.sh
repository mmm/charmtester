#!/bin/bash

[ -f lib/ch-user.sh ] && . lib/ch-user.sh
[ -f lib/ch-file.sh ] && . lib/ch-file.sh

provider_types() {
  local home=$1
  local environments_file="$home/.juju/environments.yaml"
  [ -f $environments_file ] && cat $environments_file | awk '/\ type:\ / { print $2 }' || echo ""
}

has_provider() {
  local home=$1
  local provider=$2
  for configured_provider in `provider_types $home`; do
    if [ $provider == $configured_provider ]; then
      return 0
    fi
  done
  return 1
}

configure_juju_local_provider() {
  local user=$1
  local home=$2

  addgroup $user libvirtd 

  make_user_sudo $user

  local tmpfs_size=`config-get tmpfs_size`
  ch_create_tmpfs $tmpfs_size "/var/lib/lxc"
}

configure_juju_provider() {
  local user=$1
  local home=$2

  has_provider $home "local" && configure_juju_local_provider $user $home
}

