#!/usr/bin/env bash

#  Copyright 2012-2019 Stanislav Senotrusov <stan@senotrusov.com>
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

vscode::install-and-configure(){
  vscode::snap::install || fail
  vscode::install-config || fail
  vscode::install-extensions "${SOPKAFILE_DIR}/lib/vscode/extensions.txt" || fail
}

vscode::install-config() {
  vscode::determine-config-path || fail

  config::install "${SOPKAFILE_DIR}/lib/vscode/settings.json" "${VSCODE_CONFIG_PATH}/User/settings.json" || fail
  config::install "${SOPKAFILE_DIR}/lib/vscode/keybindings.json" "${VSCODE_CONFIG_PATH}/User/keybindings.json" || fail
}

vscode::merge-config() {
  vscode::determine-config-path || fail

  config::merge "${SOPKAFILE_DIR}/lib/vscode/settings.json" "${VSCODE_CONFIG_PATH}/User/settings.json" || fail
  config::merge "${SOPKAFILE_DIR}/lib/vscode/keybindings.json" "${VSCODE_CONFIG_PATH}/User/keybindings.json" || fail

  local extensionsList; extensionsList="$(vscode::list-extensions-to-temp-file)" || fail "Unable get extensions list"
  config::merge "${SOPKAFILE_DIR}/lib/vscode/extensions.txt" "${extensionsList}" || fail
  rm "${extensionsList}" || fail
}
