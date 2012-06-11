
# example:
# ch_template_file 755 me:nogroup environments.yaml $HOME/.juju/environments.yaml "HOME VAR1 VAR2"
#
ch_template_file() {
  local perms=$1
  local user_dot_group=$2
  local filename=$3
  local destination=$4
  shift 4 && local environment=$*
  for var in $environment; do
    export $var
  done
  if [ -d $destination ]; then
    destination="$destination/$filename"
  fi
  cheetah fill --stdout --env templates/$filename > $destination
  chmod $perms $destination
  chown -Rf $user_dot_group $destination
}

ch_create_tmpfs() {
  local tmpfs_size=$1
  local mount_point=$2

  #TODO on precise use /etc/fstab.d/

  if [ ! -z "$tmpfs_size" ]; then
    grep -q $mount_point /etc/fstab || echo "tmpfs $mount_point tmpfs size=$tmpfs_size 0 0" >> /etc/fstab
    mount -at tmpfs 
  fi
}
