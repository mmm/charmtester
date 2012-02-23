#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

install_juju_packages() {
  juju-log "Installing juju for local testing..."
  apt-add-repository ppa:juju/pkgs
  # Might not pickup for current release - so ignore errors
  apt-get update || true
  apt-get -qq install -y juju charm-tools apt-cacher-ng zookeeper libvirt-bin lxc charm-helper-sh
}

generate_ssh_keys() {
  local user=$1
  local home=$2
  if [ ! -f $home/.ssh/id_rsa ]; then
    su -l $user -c "ssh-keygen -q -N '' -t rsa -b 2048 -f $home/.ssh/id_rsa"
  fi
}

create_charms_repo() {
  local user=$1
  local home=$2
  mkdir -p $home/charms/oneiric
  chown -Rf $user:nogroup $home
}

configure_juju_environment() {
  local user=$1
  local home=$2
  local juju_environments_file=$home/.juju/environments.yaml
  mkdir -p $home/.juju

  local juju_environments=$(config-get tester_environment)
  if [ -z "$juju_environments" ]; then
    ch_template_file 644 $user:nogroup default-local-environment.yaml $juju_environments_file "home"
  else
    echo "$juju_environments" > $juju_environments_file
    chmod 644 $juju_environments_file
    chown $user:nogroup $juju_environments_file
  fi

  generate_ssh_keys $user $home
  create_charms_repo $user $home
}

####
# specific to local provider

make_user_sudo() {
  local user=$1
  local sudoer_file="/etc/sudoers.d/91-$user-charmtester"
  echo "$user ALL=(ALL) NOPASSWD:ALL" > $sudoer_file
  chmod 0440 $sudoer_file
}

use_tmpfs_for_tests() {
  tmpfs_size=`config-get tmpfs_size`
  if [ ! -z "$tmpfs_size" ]; then
    grep -q lxc /etc/fstab || echo "tmpfs /var/lib/lxc tmpfs size=$tmpfs_size 0 0" >> /etc/fstab
    # maybe do the same for /var/cache/lxc?
    mount -at tmpfs 
  fi
}

configure_juju_local_provider() {
  local user=$1
  addgroup $user libvirtd 
  make_user_sudo $user
  use_tmpfs_for_tests
}

configure_juju_provider() {
  local user=$1
  configure_juju_local_provider $user
}

# specific to local provider
####

install_juju_client() {
  local user=$1
  local home=$2

  juju-log "installing juju packages"
  install_juju_packages

  juju-log "cofiguring juju provider"
  configure_juju_provider $user

  juju-log "configuring juju environment"
  configure_juju_environment $user $home

}
