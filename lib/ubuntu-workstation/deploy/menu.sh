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

if [[ "${OSTYPE}" =~ ^linux ]] && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header Deploy || fail

  if [ -n "${DISPLAY:-}" ]; then
    sopka_menu::add ubuntu_workstation::deploy-full-workstation || fail
    sopka_menu::add ubuntu_workstation::deploy-secrets || fail
    sopka_menu::add ubuntu_workstation::deploy-workstation-base || fail
  fi

  if vmware::is_inside_vm; then
    sopka_menu::add ubuntu_workstation::deploy-host-folders-access || fail
    sopka_menu::add ubuntu_workstation::deploy-vm-server || fail
  fi

  sopka_menu::add ubuntu_workstation::deploy-shellrc || fail
  sopka_menu::add ubuntu_workstation::deploy-tailscale || fail

  sopka_menu::add_delimiter || fail
fi
