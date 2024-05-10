#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

# shellcheck disable=2030
workstation::backup() {(
  export WORKSTATION_BACKUP_PROFILE="workstation"
  export WORKSTATION_BACKUP_PASSWORD="default"
  export WORKSTATION_BACKUP_REPOSITORY="default"

  local each_repository=false

  while [ "$#" -gt 0 ]; do
    case $1 in
      -p|--profile)
        WORKSTATION_BACKUP_PROFILE="$2"
        shift; shift
        ;;
      -w|--password)
        WORKSTATION_BACKUP_PASSWORD="$2"
        shift; shift
        ;;
      -r|--repository)
        WORKSTATION_BACKUP_REPOSITORY="$2"
        shift; shift
        ;;
      -e|--each-repository)
        each_repository=true
        shift
        ;;
      -*)
        softfail "Unknown argument: $1" || return $?
        ;;
      *)
        break
        ;;
    esac
  done

  local command_name="$1"; shift

  local config_dir; config_dir="$(workstation::get_config_path "workstation-backup")" || fail

  export RESTIC_COMPRESSION="auto"
  export RESTIC_PASSWORD_FILE="${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/passwords/${WORKSTATION_BACKUP_PASSWORD}"

  unset RESTIC_REPOSITORY
  unset RESTIC_REPOSITORY_FILE

  # case for single repository

  if [ "${each_repository}" = false ]; then
    export RESTIC_REPOSITORY; RESTIC_REPOSITORY="$(<"${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories/${WORKSTATION_BACKUP_REPOSITORY}")" || softfail || return $?

    "workstation::backup::${command_name}" "$@"
    softfail --unless-good --exit-status $? "Failed to run ${command_name} ($?)"
    return $? # this return should be here, do not remove it
  fi

  # case for multiple repositories (--each-repository)

  local exit_statuses=()

  local repository_config_path; for repository_config_path in "${config_dir}/profiles/${WORKSTATION_BACKUP_PROFILE}/repositories"/*; do
    if [ -f "${repository_config_path}" ]; then
      workstation::backup::run_action_with_repository_config "${command_name}" "${repository_config_path}" "$@"
      softfail --unless-good --exit-status $? "Backup command failed: ${command_name} ($?)"
      exit_statuses+=($?)
    fi
  done

  if [[ "${exit_statuses[*]}" =~ [^0[:space:]] ]]; then
    softfail "One or more ${command_name} failed (${exit_statuses[*]})"
    return $?
  fi
)}

# shellcheck disable=2031
workstation::backup::run_action_with_repository_config() {(
  local command_name="$1"; shift
  local repository_config_path="$1"; shift

  local lock_pid

  export RESTIC_REPOSITORY; RESTIC_REPOSITORY="$(<"${repository_config_path}")" || softfail || return $?
  export WORKSTATION_BACKUP_REPOSITORY; WORKSTATION_BACKUP_REPOSITORY="$(basename "${repository_config_path}")" || softfail || return $?
  
  # case if repository is not remote
  if [[ ! "${RESTIC_REPOSITORY}" =~ .+:.+ ]]; then
    # if linux
    if [[ "${OSTYPE}" =~ ^linux ]] && [[ "${RESTIC_REPOSITORY}" =~ ^(/(media/${USER}|mnt)/[^/]+)/ ]]; then
      local mount_point="${BASH_REMATCH[1]}"

      if ! findmnt --mountpoint "${mount_point}" >/dev/null; then
        return 0
      fi

      cd "${mount_point}" || softfail || return $?

      ( sleep 86400 ) &
      lock_pid=$!
    fi
  fi
  (
    log::notice "Proceeding with repository: ${RESTIC_REPOSITORY}" || softfail || return $?
    "workstation::backup::${command_name}" "$@"
  )
  local action_status=$?

  if [ -n "${lock_pid:-}" ]; then
    kill "${lock_pid}" || softfail # without return
  fi

  softfail --unless-good --exit-status "${action_status}" "Backup command failed: ${command_name} ${repository_config_path} [$*] (${action_status})"
  return "${action_status}"
)}

# shellcheck disable=2031
workstation::backup::get_output_directory() {
  if [ -n "${WORKSTATION_BACKUP_OUTPUT_DIR:-}" ]; then
    local output_directory="${WORKSTATION_BACKUP_OUTPUT_DIR}"
    ( umask 0077 && mkdir -p "${output_directory}" ) || softfail || return $?
  else
    local backups_home="${HOME}/backups"
    dir::should_exists --mode 0700 "${backups_home}" || fail

    local output_directory="${backups_home}/workstation-restore"
    dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?

    file::write --mode 0600 "${output_directory}/.backup-restore-dir-flag" "38pmZzJ687QwThYHkOSGzt" || fail

    if [ "${WORKSTATION_BACKUP_PROFILE}" != workstation ]; then
      output_directory+="/${WORKSTATION_BACKUP_PROFILE}"
      dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?
    fi

    if [ "${WORKSTATION_BACKUP_REPOSITORY}" != default ]; then
      output_directory+="/${WORKSTATION_BACKUP_REPOSITORY}"
      dir::should_exists --mode 0700 "${output_directory}" || softfail || return $?
    fi
  fi

  echo "${output_directory}"
}
