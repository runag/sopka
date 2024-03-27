#!/usr/bin/env bash

#  Copyright 2012-2022 Rùnag project contributors
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

workstation::backup::init() {
  # set compression=none for parent directory if repository is on a local btrfs
  if [[ ! "${RESTIC_REPOSITORY}" =~ .+:.+ ]]; then
    local parent_dir; parent_dir="$(dirname "${RESTIC_REPOSITORY}")" || softfail || return $?

    ( umask 0077 && mkdir -p "${parent_dir}" ) || softfail || return $?

    if command -v btrfs >/dev/null && btrfs property get "${parent_dir}" compression >/dev/null 2>&1; then
      btrfs property set "${parent_dir}" compression none || softfail || return $?
    fi
  fi

  restic init || softfail "Unable to init restic repository" || return $?
}

workstation::backup::init_unless_exists() {
  local remote_proto remote_host remote_path

  <<<"${RESTIC_REPOSITORY}" IFS=: read -r remote_proto remote_host remote_path || softfail || return $?

  if [ "${remote_proto}" = sftp ]; then
    <<<pwd sftp "${remote_host}" >/dev/null 2>&1 || softfail "Unable to connect to a sftp server" || return $?
  fi

  if restic::is_repository_not_exists; then
    workstation::backup::init || softfail || return $?
  fi
}

workstation::backup::create() {(
  workstation::backup::init_unless_exists || softfail || return $?

  local machine_id; machine_id="$(os::machine_id)" || softfail || return $?

  cd "${HOME}" || softfail || return $?

  # TODO: benchmark --read-concurrency

  if [ "${WORKSTATION_BACKUP_REPOSITORY}" = "workstation-sync" ]; then
    restic backup \
      --one-file-system \
      --tag "machine-id:${machine_id}" \
      --group-by "host,paths,tags" \
      --exclude-caches \
      --exclude-if-present .exclude-from-workstation-sync-backup \
      \
      --exclude "${HOME}/.*" \
      --exclude "!${HOME}/.gnupg" \
      --exclude "!${HOME}/.password-store" \
      --exclude "!${HOME}/.runag" \
      --exclude "!${HOME}/.ssh" \
      \
      --exclude "runagfile/data-backup" \
      \
      --exclude "${HOME}/Downloads/*" \
      \
      --exclude "${HOME}/snap" \
      \
      . || softfail || return $?
  else
    restic backup \
      --one-file-system \
      --tag "machine-id:${machine_id}" \
      --group-by "host,paths,tags" \
      --exclude-caches \
      \
      --exclude "${HOME}/.cache/*" \
      --exclude "${HOME}/.local/state/*" \
      \
      --exclude "${HOME}/.config/**/Cache/*" \
      --exclude "${HOME}/.config/**/Code Cache/*" \
      --exclude "${HOME}/.config/**/DawnCache/*" \
      --exclude "${HOME}/.config/**/GPUCache/*" \
      --exclude "${HOME}/.config/**/GraphiteDawnCache/*" \
      --exclude "${HOME}/.config/**/GrShaderCache/*" \
      --exclude "${HOME}/.config/**/ShaderCache/*" \
      \
      --exclude "${HOME}/.config/Code/CachedConfigurations/*" \
      --exclude "${HOME}/.config/Code/CachedData/*" \
      --exclude "${HOME}/.config/Code/CachedExtensionVSIXs/*" \
      --exclude "${HOME}/.config/Code/CachedProfilesData/*" \
      \
      --exclude "${HOME}/.config/Code/Backups/*" \
      --exclude "${HOME}/.config/Code/Crashpad/*/*" \
      --exclude "${HOME}/.config/Code/logs/*" \
      --exclude "${HOME}/.config/Code/User/History/*" \
      \
      --exclude "${HOME}/.config/micro/backups/*" \
      --exclude "${HOME}/.config/micro/buffers/*" \
      \
      --exclude "${HOME}/.local/*-browser" \
      --exclude "${HOME}/.local/share/Trash/*" \
      \
      --exclude "${HOME}/Downloads/*" \
      \
      --exclude "${HOME}/snap/*/*" \
      --exclude "!${HOME}/snap/*/common" \
      \
      --exclude "${HOME}/snap/**/Cache/*" \
      --exclude "${HOME}/snap/**/Code Cache/*" \
      --exclude "${HOME}/snap/**/DawnCache/*" \
      --exclude "${HOME}/snap/**/GPUCache/*" \
      --exclude "${HOME}/snap/**/GraphiteDawnCache/*" \
      --exclude "${HOME}/snap/**/GrShaderCache/*" \
      --exclude "${HOME}/snap/**/ShaderCache/*" \
      --exclude "${HOME}/snap/*/*/.cache/*" \
      \
      --exclude "${HOME}/snap/chromium" \
      --exclude "${HOME}/snap/firefox" \
      \
      . || softfail || return $?
  fi
)}

workstation::backup::snapshots() {
  restic snapshots || softfail || return $?
}

workstation::backup::check() {
  # TODO: benchmark
  # restic check --read-data -o local.connections=1 -o stfp.connections=1 || softfail || return $?
  restic check --read-data || softfail || return $?
  
  log::elapsed_time || softfail || return $?
}

workstation::backup::forget() {
  if [ "${WORKSTATION_BACKUP_REPOSITORY}" = "workstation-sync" ]; then
    restic forget \
      --group-by "host,paths,tags" \
      --keep-within 7d \
      --keep-within-daily 30d \
      --keep-within-weekly 3m \
      --keep-within-monthly 1y || softfail || return $?
  else
    restic forget \
      --group-by "host,paths,tags" \
      --keep-within 14d \
      --keep-within-daily 30d \
      --keep-within-weekly 3m \
      --keep-within-monthly 3y || softfail || return $?
  fi
}

workstation::backup::prune() {
  restic prune || softfail || return $?
}

workstation::backup::maintenance() {
  restic check || softfail || return $?
  workstation::backup::forget || softfail || return $?
  workstation::backup::prune || softfail || return $?
}

workstation::backup::unlock() {
  restic unlock || softfail || return $?
}


# restore

workstation::backup::mount() {
  local mount_directory; mount_directory="$(workstation::backup::get_output_directory)/mount" || softfail || return $?

  if findmnt --mountpoint "${mount_directory}" >/dev/null; then
    fusermount -u -z "${mount_directory}" || softfail || return $?
  fi

  dir::should_exists --mode 0700 "${mount_directory}" || softfail || return $?

  restic::open_mount_when_available "${mount_directory}" || softfail || return $?

  local open_mount_pid=$!

  if ! restic mount --owner-root "${mount_directory}"; then
    kill "${open_mount_pid}"
    softfail || return $?
  fi
}

workstation::backup::umount() {
  local mount_directory; mount_directory="$(workstation::backup::get_output_directory)/mount" || softfail || return $?

  fusermount -u -z "${mount_directory}" || softfail || return $?
}

workstation::backup::restore() {
  local snapshot_id="${1:-"latest"}"

  local restore_directory; restore_directory="$(workstation::backup::get_output_directory)/${snapshot_id}" || softfail || return $?

  if [ -d "${restore_directory}" ]; then
    softfail "Restore directory already exists, unable to restore" || return $?
  fi

  dir::should_exists --mode 0700 "${restore_directory}" || softfail || return $?

  # TODO: optional --verify?
  restic restore --target "${restore_directory}" "${snapshot_id}" || softfail || return $?

  log::elapsed_time || softfail || return $?
}


# shell

workstation::backup::shell() {
  "${SHELL}"
  softfail --unless-good --exit-status $? "Abnormal termination of workstation::backup::shell ($?)"
}

# shellcheck disable=2031
workstation::backup::remote_shell() {
  local remote_proto remote_host remote_path

  <<<"${RESTIC_REPOSITORY}" IFS=: read -r remote_proto remote_host remote_path || softfail || return $?

  test "${remote_proto}" = sftp || softfail || return $?

  ssh -t "${remote_host}" "cd $(printf "%q" "${remote_path}"); exec \"\${SHELL}\" -l"
  softfail --unless-good --exit-status $? "Abnormal termination of workstation::backup::remote_shell ($?)"
}
