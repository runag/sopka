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


### Checksums

workstation::key_storage::maintain_checksums() {
  local media_path="$1"

  local dir; for dir in "${media_path}/keys"/*/*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksums::create_or_update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media_path}/keys-backups"/* "${media_path}/keys-backups"/*/keys/*/*; do
    if [ -d "${dir}" ] && [ -f "${dir}/checksums.txt" ]; then
      fs::with_secure_temp_dir_if_available checksums::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

workstation::key_storage::make_backups() {
  local media_path="$1"

  local backups_dir="${media_path}/keys-backups"
  local dest_dir; dest_dir="${backups_dir}/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail

  dir::make_if_not_exists "${backups_dir}" || fail
  dir::make_if_not_exists "${dest_dir}" || fail

  cp -R "${media_path}/keys" "${dest_dir}" || fail

  RUNAG_CREATE_CHECKSUMS_WITHOUT_CONFIRMATION=true fs::with_secure_temp_dir_if_available checksums::create_or_update "${dest_dir}" "checksums.txt" || fail

  sync || fail
  echo "Backups were made: ${dest_dir}"
}


### Password store

workstation::key_storage::add_or_update_password_store_git_remote() {(
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  cd "${password_store_dir}" || fail

  git::add_or_update_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
  git branch --move --force main || fail
  git push --set-upstream "${git_remote_name}" main || fail
)}

workstation::key_storage::create_password_store_git_remote() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  git init --bare "${password_store_git_remote_path}" || fail

  workstation::key_storage::add_or_update_password_store_git_remote "${git_remote_name}" "${password_store_git_remote_path}" || fail
}

workstation::key_storage::password_store_git_remote_clone_or_update_to_local() {
  local git_remote_name="$1"
  local password_store_git_remote_path="$2"

  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"

  if [ ! -d "${password_store_dir}" ]; then
    git clone --origin "${git_remote_name}" "${password_store_git_remote_path}" "${password_store_dir}" || fail
  else
    git -C "${password_store_dir}" pull "${git_remote_name}" main || fail
  fi
}


### GPG keys

workstation::key_storage::import_gpg_key() {
  local gpg_key_id="$1"
  local gpg_key_file="$2"
  gpg::import_key --confirm --skip-if-exists --trust-ultimately "${gpg_key_id}" "${gpg_key_file}" || fail
}


### Pass

# create_or_update
# verify
workstation::key_storage::password_store_checksum() {
  local action="$1"
  local password_store_dir="${PASSWORD_STORE_DIR:-"${HOME}/.password-store"}"
  "checksums::${action}" "${password_store_dir}" "checksums.txt" ! -path "./.git/*" || fail
}
