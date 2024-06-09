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


# one command to encompass the whole workstation deployment process.
workstation::linux::deploy_workstation() {
  # install packages & configure
  workstation::linux::install_packages || fail
  workstation::linux::configure || fail

  # deploy keys
  if local key_path="/media/${USER}/workstation-sync" && [ -d "${key_path}" ]; then
    workstation::linux::deploy_keys "${key_path}" || fail
    
  elif [ -d "${HOME}/.runag/.virt-deploy-keys" ]; then
    workstation::linux::deploy_virt_keys || fail
  fi
 
  # deploy identities & credentials
  workstation::linux::deploy_identities || fail

  # setup backup
  workstation::backup::credentials::deploy_remote backup/remotes/my-backup-server || fail
  workstation::backup::credentials::deploy_profile backup/profiles/workstation || fail
  workstation::backup::services::deploy || fail

  # setup remote repositories backup
  if ! systemd-detect-virt --quiet; then
    workstation::remote_repositories_backup::initial_deploy || fail
  fi

  # fix for nvidia gpu
  if nvidia::is_device_present; then
    nvidia::enable_preserve_video_memory_allocations || fail
  fi
}

workstation::linux::deploy_keys() {
  local key_storage_volume="/media/${USER}/workstation-sync"

  # install gpg keys
  workstation::key_storage::maintain_checksums --skip-backups --verify-only "${key_storage_volume}" || fail

  local gpg_key_path; for gpg_key_path in "${key_storage_volume}/keys/workstation/gpg"/* ; do
    if [ -d "${gpg_key_path}" ]; then
      local gpg_key_id; gpg_key_id="$(basename "${gpg_key_path}")" || fail

      workstation::key_storage::import_gpg_key "${gpg_key_id}" "${gpg_key_path}/secret-subkeys.asc" || fail
    fi
  done

  # install password store
  workstation::key_storage::password_store_git_remote_clone_or_update_to_local keys/workstation "${key_storage_volume}/keys/workstation/password-store" || fail
}

workstation::linux::deploy_virt_keys() (
  pack() {
    if [ -d "${HOME}/.$1" ]; then
      tar -czf ".virt-deploy-keys/$1.tgz" -C "${HOME}" ".$1"
    fi
  }

  unpack() {
    if [ -f ".virt-deploy-keys/$1.tgz" ]; then
      if [ -d "${HOME}/.$1" ]; then
        local temp_dir; temp_dir="$(mktemp -d "${HOME}/.$1-preceding-XXXXXXXXXX")" || fail
        mv "${HOME}/.$1" "${temp_dir}" || fail
      fi
      tar -xzf ".virt-deploy-keys/$1.tgz" -C "${HOME}" || fail
    fi
  }

  cd "${HOME}/.runag" || fail

  umask 077 || fail

  if ! systemd-detect-virt --quiet; then
    chmod 700 ".virt-deploy-keys" || fail

    pack password-store || fail
    pack gnupg || fail
  
  elif systemd-detect-virt --quiet; then
    unpack password-store || fail
    unpack gnupg || fail
  fi
)

workstation::linux::deploy_identities() {
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  local absolute_identity_path; for absolute_identity_path in "${password_store_dir}/identity"/* ; do
    if [ -d "${absolute_identity_path}" ]; then
      local identity_path="${absolute_identity_path:$((${#password_store_dir}+1))}"

      workstation::identity::use --with-system-credentials "${identity_path}" || fail
    fi
  done
}
