#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/juju-provider.sh ] && . lib/juju-provider.sh

job_name_for_charm() {
  local charm_name=$1
  local provider=$2
  local series=$3
  echo "$series-$provider-charm-$charm_name"
}

get_api_token() {
  local home=$1
  cat $home/API_TOKEN
}

create_job_for_charm() {
  local charm_name=$1
  local user=$2
  local home=$3
  local provider=$4
  local job_name=$(job_name_for_charm $charm_name $provider $release)
  local juju_env=""
  local API_TOKEN=$(get_api_token $home)
  local build_publisher_enabled=$(config-get build_publisher_enabled)
  local ircbot_enabled=$(config-get ircbot_enabled)
  mkdir -p -m755 $home/jobs/$job_name
  ch_template_file 755 \
                   $user:nogroup \
                   job-config.xml \
                   $home/jobs/$job_name/config.xml \
                   "user home provider charm_name job_name API_TOKEN build_publisher_enabled ircbot_enabled juju_env"
}

charm_listed_in_file() {
  local charm_name=$1
  local file=$2

  for charm in `cat ${file}`; do
    if [ $charm == $charm_name ]; then
      return 0
    fi
  done

  return 1
}

blacklisted_charm() {
  local charm_name=$1
  local provider=$2

  local provider_blacklist="etc/${provider}-blacklisted-charms"
  [ -f $provider_blacklist ] && charm_listed_in_file $charm_name $provider_blacklist && return 0

  local global_blacklist="etc/common-blacklisted-charms"
  [ -f $global_blacklist ] && charm_listed_in_file $charm_name $global_blacklist && return 0

  return 1
}

#update_charm_jobs() {
#  local user=$1
#  local home=$2
#
#  for charm_name in `su -l $user -c "charm list | grep lp:charms | sed 's/lp:charms\///'"`; do
#    for provider in `provider_types $home`; do
#      if blacklisted_charm $charm_name $provider ; then
#        juju-log "skipping blacklisted $charm_name for provider $provider"
#      else
#        create_job_for_charm $charm_name $user $home $provider
#      fi
#    done
#  done
#
#}

charm_name_from_branch() {
  local branch=$1
  echo $branch | sed 's/lp:charms\///'
}

list_branches_to_test() {
  #whitelist yes
  #  from branch
  #  from store
  #blacklist no
  #return a bash list of charms
  # grab the charm whitelist...  this is a list of either charm names or branches

  raw_whitelist=`config-get charm_whitelist`
  #IFS=',' whitelist_branches=(${raw_whitelist//[[:space:]]/}) && unset IFS
  # too bad I can't do whitelist_charms=$( IFS=',' (${raw_whitelist//[[:space:]]/}) )
  whitelist_charms=( $(IFS=',' echo ${raw_whitelist//[[:space:]]/}) )
  if [ ${whitelist_charms[@]} =~ /all/ ]; then
  fi

  #if [ $whitelist -eq "all" ]; then   # just test if it _contains_ "all"
    read -a charms_in_store <<< su -l $user -c "charm list | grep lp:charms"
    #remove 'all' from the list
    #${arrayZ[@]//iv/YY}I
  #fi


  # kind of a for_each...
  #echo ${arrayZ[@]//*/$(replacement optional_arguments)}

  #for whitelist_entry in extract_bash_list(`config-get charm_whitelist`); do
  #  if is_a_branch(whitelist_entry); then
  #    job_from_charm_branch $whitelist_entry
  #  else
  #    job_from_store $whitelist_entry
  #  fi
  #done

}

update_charm_jobs() {
  local user=$1
  local home=$2

  for charm in $(list_branches_to_test); do
    local charm_name=$(charm_name_from_branch $charm)
    for provider in $(provider_types $home); do
      if blacklisted_charm $charm_name $provider ; then
        juju-log "skipping blacklisted $charm_name for provider $provider"
      else
        create_job_for_charm $charm_name $user $home $provider
      fi
    done
  done

  chown -Rf $user:nogroup $home/jobs/
}
