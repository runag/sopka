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

ubuntu_workstation::deploy_tailscale() {
  # install gpg keys
  ubuntu_workstation::install_gpg_keys || fail

  # install bitwarden cli and login
  ubuntu_workstation::install_bitwarden_cli_and_login || fail

  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] || ! command -v tailscale >/dev/null || tailscale::is_logged_out; then
    bitwarden::unlock_and_sync || fail

    local tailscale_key; tailscale_key="$(bw get password "my tailscale reusable key")" || fail
    
    # shellcheck disable=2034
    local SOPKA_TASK_STDERR_FILTER=task::install_filter
    bitwarden::beyond_session task::run_with_short_title ubuntu_workstation::deploy_tailscale::stage_two "${tailscale_key}" || fail
  fi
}

ubuntu_workstation::deploy_tailscale::stage_two() {
  local tailscale_key="$1"

  # install tailscale
  if ! command -v tailscale >/dev/null; then
    tailscale::install || fail
    if vmware::is_inside_vm; then
      tailscale::install_issue_2541_workaround || fail
    fi
  fi

  # logout if SOPKA_UPDATE_SECRETS is set
  if [ "${SOPKA_UPDATE_SECRETS:-}" = true ] && ! tailscale::is_logged_out; then
    sudo tailscale logout || fail
  fi

  # configure tailscale
  sudo tailscale up --authkey "${tailscale_key}" || fail
}
