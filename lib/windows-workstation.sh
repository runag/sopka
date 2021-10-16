#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

if [[ "${OSTYPE}" =~ ^msys ]] && declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add windows-workstation::deploy || fail
fi

windows-workstation::deploy() {
  # check dependencies
  command -v bw >/dev/null || fail "bw command is not found"
  command -v jq >/dev/null || fail "jq command is not found"
  command -v code >/dev/null || fail "code command is not found"

  # shell aliases
  shellrc::install-loader "${HOME}/.bashrc" || fail
  shellrc::install-nano-editor-rc || fail
  shellrc::install-sopka-path-rc || fail

  # git
  workstation::configure-git || fail

  # vscode
  workstation::vscode::install-config || fail
  workstation::vscode::install-extensions || fail

  # sublime merge config
  workstation::sublime-merge::install-config || fail

  # sublime text config
  workstation::sublime-text::install-config || fail

  # secrets
  if [ -t 0 ]; then
    (
      # add ssh key
      workstation::install-ssh-keys || fail

      # rubygems
      workstation::install-rubygems-credentials || fail

      # npm
      workstation::install-npm-credentials || fail

      # sublime text license
      workstation::sublime-text::install-license || fail
    ) || fail
  fi

  log::success "Done windows-workstation::deploy" || fail
}
