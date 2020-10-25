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

deploy::data-pi() {
  ubuntu::deploy-data-pi || fail
}

deploy::macos-workstation() {
  macos::deploy-workstation || fail
}

deploy::macos-non-developer-workstation() {
  DEPLOY_NON_DEVELOPER_WORKSTATION=true deploy::macos-workstation || fail
}

deploy::ubuntu-workstation() {
  ubuntu::deploy-workstation || fail
}

deploy::ubuntu-sway-workstation() {
  DEPLOY_SWAY=true deploy::ubuntu-workstation || fail
}

deploy::merge-workstation-configs() {
  deploy-lib::footnotes::init || fail

  vscode::merge-config || fail
  sublime::merge-config || fail
  sway::merge-config || fail

  deploy-lib::footnotes::flush || fail
}
