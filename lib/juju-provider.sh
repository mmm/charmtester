#!/bin/bash

[ -f lib/ch-user.sh ] && . lib/ch-user.sh
[ -f lib/ch-file.sh ] && . lib/ch-file.sh

environment_releases() {
  local home=$1
  local environments_file="$home/.juju/environments.yaml"
  [ -f $environments_file ] && cat $environments_file | awk '/\ default-series:\ / { print $2 }' || echo ""
}

releases() {
  ( environment_releases $home; lsb_release -cs ) | sort | uniq
}

has_release() {
  local home=$1
  local release=$2
  for configured_release in `environment_releases $home`; do
    if [ $release == $configured_release ]; then
      return 0
    fi
  done
  return 1
}

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

refresh_local_provider_cache() {
  local user=$1
  local home=$2
  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup precache-lxc $home/bin/
  for release in `releases $home`; do
    [ -f /var/cache/lxc/$release ] || sudo -HEsu jenkins $home/bin/precache-lxc $release
  done
}

configure_juju_local_provider() {
  local user=$1
  local home=$2

  addgroup $user libvirtd 

  local tmpfs_size=`config-get tmpfs_size`
  [ -z "$tmpfs_size" ] || ch_create_tmpfs $tmpfs_size "/var/lib/lxc"

  local precache_lxc=`config-get precache_lxc`
  [ -z "$precache_lxc" ] || refresh_local_provider_cache $user $home

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

