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

# install dependencies
ubuntu_workstation::deploy_secrets::install_dependencies(){
  apt::lazy_update || fail
  apt::install_gnome_keyring_and_libsecret || fail
  git::install_libsecret_credential_helper || fail
}

ubuntu_workstation::deploy_secrets() {
  bitwarden::beyond_session task::run_with_install_filter ubuntu_workstation::deploy_secrets::install_dependencies || fail

  # install gpg keys
  ubuntu_workstation::install_gpg_keys || fail

  # install bitwarden cli and login
  ubuntu_workstation::install_bitwarden_cli_and_login || fail

  # ssh key
  workstation::install_ssh_keys || fail
  bitwarden::use password "${MY_SSH_KEY_PASSWORD_ID}" ssh::gnome_keyring_credentials || fail


  # git user
  workstation::configure_git_user || fail

  # git access token
  git::use_libsecret_credential_helper || fail
  bitwarden::use password "${MY_GITHUB_ACCESS_TOKEN_ID}" git::gnome_keyring_credentials "${MY_GITHUB_LOGIN}" || fail

  # configure git to use gpg signing key
  git::configure_signing_key "${MY_GPG_SIGNING_KEY}!" || fail


  # rubygems
  workstation::install_rubygems_credentials || fail

  # npm
  workstation::install_npm_credentials || fail

  # sublime text license
  workstation::sublime_text::install_license || fail
}
