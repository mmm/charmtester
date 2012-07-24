#!/bin/bash

make_user_sudo() {
  local user=$1
  local sudoer_file="/etc/sudoers.d/91-$user-charmtester"
  echo "$user ALL=(ALL) NOPASSWD:ALL" > $sudoer_file
  chmod 0440 $sudoer_file
}

turn_off_host_key_checking() {
  local user=$1
  local home=$2
  local ssh_config_file="$home/.ssh/config"
  echo "StrictHostKeyChecking no" > $ssh_config_file
  echo "UserKnownHostsFile /dev/null" >> $ssh_config_file
  chown $user:nogroup $ssh_config_file
  chmod 0400 $ssh_config_file
}

generate_ssh_keys() {
  local user=$1
  local home=$2
  if [ ! -f $home/.ssh/id_rsa ]; then
    su -l $user -c "ssh-keygen -q -N '' -t rsa -b 2048 -f $home/.ssh/id_rsa"
  fi

  turn_off_host_key_checking $user $home
}

