#!/usr/bin/env bash

#  Copyright 2012-2022 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Workstation" || fail
  sopka_menu::add workstation::add_private_sopkafiles || fail
  sopka_menu::add workstation::merge_editor_configs || fail
  sopka_menu::add workstation::remove_nodejs_and_ruby_installations || fail
  sopka_menu::add workstation::backup_my_github_repositories || fail
  sopka_menu::add_delimiter || fail

  sopka_menu::add_header "Workstation: pass" || fail
  sopka_menu::add workstation::pass::deploy || fail
  sopka_menu::add workstation::pass::import_offline || fail
  sopka_menu::add workstation::pass::sync_offline || fail
  sopka_menu::add workstation::pass::init || fail
  sopka_menu::add_delimiter || fail
fi

workstation::deploy_secrets() {
  # install gpg keys
  workstation::install_gpg_keys || fail

  # import password store
  workstation::pass::import_offline || fail

  # ssh key
  workstation::install_ssh_keys || fail

  # git
  workstation::configure_git_user || fail
  workstation::configure_git_signing_key || fail
  workstation::configure_git_credentials || fail

  # rubygems
  workstation::install_rubygems_credentials || fail

  # npm
  workstation::install_npm_credentials || fail

  # sublime text license
  workstation::sublime_text::install_license || fail

  # sublime merge license
  # workstation::sublime_merge::install_license || fail
}

workstation::install_gpg_keys() {
  gpg::import_key_with_ultimate_ownertrust "${MY_GPG_KEY}" "${MY_GPG_OFFLINE_KEY_FILE}" || fail
}

workstation::install_ssh_keys() {
  ssh::install_ssh_key_from_pass "${MY_SSH_KEY_PATH}" || fail
}

workstation::configure_git() {
  git config --global core.autocrlf input || fail
  git config --global init.defaultBranch main || fail
}

workstation::configure_git_user() {
  git config --global user.name "${MY_GIT_USER_NAME}" || fail
  git config --global user.email "${MY_GIT_USER_EMAIL}" || fail
}

workstation::configure_git_signing_key() {
  git::configure_signing_key "${MY_GPG_SIGNING_KEY}!" || fail
}

workstation::configure_git_credentials() {
  if [[ "${OSTYPE}" =~ ^linux ]]; then
    git::use_libsecret_credential_helper || fail
    pass::use "${MY_GITHUB_ACCESS_TOKEN_PATH}" git::gnome_keyring_credentials "${MY_GITHUB_LOGIN}" || fail
  fi
}

workstation::install_rubygems_credentials() {
  dir::make_if_not_exists "${HOME}/.gem" 755 || fail
  pass::use "${MY_RUBYGEMS_CREDENTIALS_PATH}" rubygems::credentials || fail
}

workstation::install_npm_credentials() {(
  nodenv::load_shellrc_if_exists || fail
  pass::use "${MY_NPM_PUBLISH_TOKEN_PATH}" npm::auth_token || fail
)}

workstation::make_keys_directory_if_not_exists() {
  dir::make_if_not_exists_and_set_permissions "${MY_KEYS_PATH}" 700 || fail
}

workstation::remove_nodejs_and_ruby_installations() {
  rm -rf "${HOME}/.nodenv/versions"/* || fail
  rm -rf "${HOME}/.rbenv/versions"/* || fail
  rm -rf "${HOME}/.cache/yarn" || fail
  rm -rf "${HOME}/.solargraph" || fail
  rm -rf "${HOME}/.bundle" || fail
  rm -rf "${HOME}/.node-gyp" || fail
}

workstation::merge_editor_configs() {
  workstation::vscode::merge_config || fail
  workstation::sublime_merge::merge_config || fail
  workstation::sublime_text::merge_config || fail
}

workstation::pass::deploy() {
  # install gpg keys
  workstation::install_gpg_keys || fail

  # import password store
  workstation::pass::import_offline || fail
}

workstation::pass::import_offline() {
  pass::import_store "${MY_PASSWORD_STORE_OFFLINE_PATH}" || fail
}

workstation::pass::sync_offline() {
  pass::sync_to "${MY_PASSWORD_STORE_OFFLINE_PATH}" || fail
}

workstation::pass::init() {
  pass init "${MY_GPG_KEY}" || fail
}

workstation::add_private_sopkafiles() {
  pass::use "${MY_PRIVATE_SOPKAFILES_LIST_PATH}" --body --pipe | sopkafile::add_from_list
  test "${PIPESTATUS[*]}" = "0 0" || fail
}

workstation::backup_my_github_repositories() {
  local backup_path="${HOME}/my/my-github-backup"

  dir::make_if_not_exists "${backup_path}" || fail

  local github_access_token; github_access_token="$(pass::use "${MY_GITHUB_ACCESS_TOKEN_PATH}")" || fail

  local page_number=1

  local full_name
  local git_url

  # url for public repos for the specific user
  # --url "https://api.github.com/users/${MY_GITHUB_LOGIN}/repos?page=${page_number}&per_page=100" |\

  while true; do
    curl \
      --fail \
      --show-error \
      --silent \
      --user "${MY_GITHUB_LOGIN}:${github_access_token}" \
      --url "https://api.github.com/user/repos?page=${page_number}&per_page=100&visibility=all" |\
    jq '.[] | [.full_name, .html_url] | @tsv' --raw-output --exit-status |\
    while IFS=$'\t' read -r full_name git_url; do
      log::notice "Backing up ${full_name}..." || fail
      git::place_up_to_date_clone "${git_url}" "${backup_path}/${full_name}" || fail
    done

    local saved_pipe_status=("${PIPESTATUS[@]}")

    if [ "${saved_pipe_status[*]}" = "0 4 0" ]; then
      return
    elif [ "${saved_pipe_status[*]}" != "0 0 0" ]; then
      fail "Abnormal termination: ${saved_pipe_status[*]}"
    fi

    ((page_number++))
  done
}
