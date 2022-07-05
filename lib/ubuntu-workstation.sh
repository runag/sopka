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


ubuntu_workstation::dangerously_set_hostname() {
  echo "Please keep in mind that the script to change hostname is not perfect, please take time to review the script and it's results"
  echo "Please enter new hostname:"
  
  local hostname; IFS="" read -r hostname || fail

  linux::dangerously_set_hostname "${hostname}" || fail
}

ubuntu_workstation::display_if_restart_required() {
  linux::display_if_restart_required || fail
}

ubuntu_workstation::run_benchmark() {
  benchmark::run || fail
}

if [[ "${OSTYPE}" =~ ^linux ]] && declare -f sopka_menu::add >/dev/null; then
  sopka_menu::add_header "Ubuntu workstation" || fail

  sopka_menu::add ubuntu_workstation::dangerously_set_hostname || fail

  if linux::display_if_restart_required::is_available; then
    sopka_menu::add ubuntu_workstation::display_if_restart_required || fail
  fi

  if benchmark::is_available; then
    sopka_menu::add ubuntu_workstation::run_benchmark || fail
  fi

  sopka_menu::add_delimiter || fail
fi
