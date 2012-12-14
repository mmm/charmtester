#!/bin/bash

[ -f lib/ch-user.sh ] && . lib/ch-user.sh
[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/juju-provider-info.sh ] && . lib/juju-provider-info.sh

refresh_local_provider_cache() {
  local user=$1
  local home=$2
  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/precache-lxc $home/bin/
  for release in `releases $home`; do
    [ -f /var/cache/lxc/$release ] || sudo -HEsu $user $home/bin/precache-lxc $release
  done
}

configure_juju_local_provider() {
  local user=$1
  local home=$2

  addgroup $user libvirtd 

  local tmpfs_size=`config-get tmpfs_size`
  [ -n "$tmpfs_size" ] && ch_create_tmpfs $tmpfs_size "/var/lib/lxc"

  local precache_lxc=`config-get precache_lxc`
  [ -n "$precache_lxc" ] && refresh_local_provider_cache $user $home

  local data_dir=`HOME=$home $home/bin/juju-environment -e local data-dir`
  [ -n "$data_dir" ] && mkdir -p -m755 $data_dir && chown -Rf $user:nogroup $data_dir

}

configure_juju_providers() {
  local user=$1
  local home=$2

  make_user_sudo $user

  #TODO handle multiple local envs?

  juju-log "configuring local provider"
  has_provider $home local && configure_juju_local_provider $user $home

  juju-log "done confiuring providers"

}

