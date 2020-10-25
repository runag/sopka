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

sopka::menu() {
  local actionList=()

  if [[ "$OSTYPE" =~ ^linux ]]; then
    actionList+=(ubuntu::deploy-workstation)
    actionList+=(ubuntu::configure-workstation)
    actionList+=(ubuntu::deploy-sway-workstation)
  fi

  if [[ "$OSTYPE" =~ ^darwin ]]; then
    actionList+=(macos::deploy-workstation)
    actionList+=(macos::configure-workstation)
    actionList+=(macos::deploy-non-developer-workstation)
  fi

  if [[ "$OSTYPE" =~ ^msys ]]; then
    actionList+=(windows::deploy-workstation)
    actionList+=(windows::configure-workstation)
  fi

  actionList+=(deploy::merge-workstation-configs)

  if [[ "$OSTYPE" =~ ^linux ]] || [[ "$OSTYPE" =~ ^darwin ]]; then
    if command -v sysbench >/dev/null; then
      actionList+=(benchmark)
    fi
  fi

  echo "Please choose an action to perform:"
  local i
  for i in "${!actionList[@]}"; do
    echo "  ${i}: ${actionList[$i]}"
  done
  echo -n "> "

  local action
  IFS="" read -r action || fail

  if [ -n "${action:-}" ]; then
    local actionFunction="${actionList[$action]}"
    declare -f "${actionFunction}" >/dev/null || fail "Argument must be a function name"
    "${actionFunction}" || fail
  fi
}
