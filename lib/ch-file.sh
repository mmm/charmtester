
ch_install_file() {
  local perms=$1
  local user_dot_group=$2
  local filename=$3
  local destination=$4
  if [ -d $destination ]; then
    destination="$destination/$filename"
  fi
  cp files/$filename $destination
  chmod $perms $destination
  chown -Rf $user_dot_group $destination
}

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
