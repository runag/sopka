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

sopkafile::load() {
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail

  . "${selfDir}/config.sh" || fail

  if [[ "${OSTYPE}" =~ ^linux ]]; then
    . "${selfDir}/lib/ubuntu-workstation/backup.sh" || fail
    . "${selfDir}/lib/ubuntu-workstation/configure.sh" || fail
    . "${selfDir}/lib/ubuntu-workstation/deploy.sh" || fail
    . "${selfDir}/lib/ubuntu-workstation/install.sh" || fail
    . "${selfDir}/lib/ubuntu-workstation/keys.sh" || fail
  fi

  if [[ "${OSTYPE}" =~ ^darwin ]]; then . "${selfDir}/lib/macos-workstation.sh" || fail; fi
  if [[ "${OSTYPE}" =~ ^msys ]]; then . "${selfDir}/lib/windows-workstation.sh" || fail; fi

  . "${selfDir}/lib/workstation.sh" || fail
  . "${selfDir}/lib/sublime-merge/sublime-merge.sh" || fail
  . "${selfDir}/lib/sublime-text/sublime-text.sh" || fail
  . "${selfDir}/lib/vscode/vscode.sh" || fail
}

sopkafile::load || fail

if declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add sopka::update || fail
  sopka-menu::add "sopka::with-update-secrets sopka-menu::display" || fail
  sopka-menu::add "sopka::with-verbose-tasks sopka-menu::display" || fail

  if [[ "${OSTYPE}" =~ ^linux ]]; then
    sopka-menu::add linux::display-if-restart-required || fail
  fi

  if benchmark::is-available; then
    sopka-menu::add benchmark::run || fail
  fi
fi
