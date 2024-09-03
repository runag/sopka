#!/usr/bin/env bash

#  Copyright 2012-2024 Rùnag project contributors
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

workstation::linux::configure() {
  ## System ##

  # enable systemd user instance without the need for the user to login
  sudo loginctl enable-linger "${USER}" || fail

  # configure bash
  shellfile::install_flush_history_rc || fail
  shellfile::install_short_prompt_rc || fail

  # configure ssh
  ssh::add_ssh_config_d_include_directive || fail
  <<<"ServerAliveInterval 30" file::write --mode 0600 "${HOME}/.ssh/ssh_config.d/server-alive-interval.conf" || fail
  <<<"IdentitiesOnly yes" file::write --mode 0600 "${HOME}/.ssh/ssh_config.d/identities-only.conf" || fail

  # increase inotify limits
  linux::configure_inotify || fail

  # udisks mount options
  workstation::linux::storage::configure_udisks_mount_options || fail

  # btrfs configuration
  if [ "${CI:-}" != "true" ]; then
    fstab::add_mount_option --filesystem-type btrfs flushoncommit || fail
    fstab::add_mount_option --filesystem-type btrfs noatime || fail
  fi

  # configuration related to the case when the system is running inside a virtual machine
  if [ "$(systemd-detect-virt)" = "vmware" ]; then
    # for network to work
    workstation::vmware::install_vm_network_loss_workaround || fail
  fi

  # In order for backup to work, configure passwordless sudo for dmidecode in get machine uuid
  if systemd-detect-virt --quiet; then
    workstation::backup::configure_passwordless_sudo_for_dmidecode || fail
  fi

  # disable unattended-upgrades, not so sure about that
  # apt::remove unattended-upgrades || fail


  ## Developer ##

  # configure git
  workstation::configure_git || fail

  # set editor
  shellfile::install_editor_rc micro || fail
  workstation::install_micro_config || fail

  # install vscode configuration
  workstation::vscode::install_extensions || fail
  workstation::vscode::install_config || fail

  # install sublime merge configuration
  workstation::sublime_merge::install_config || fail

  # install sublime text configuration
  workstation::sublime_text::install_config || fail

  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists --with "SUPERUSER CREATEDB CREATEROLE LOGIN" || fail

  ## Desktop ##

  # configure gnome desktop
  workstation::linux::gnome::configure || fail

  # configure and start imwheel
  #
  # When running linux guest in vmware workstation, if you scroll and move your mouse at the same
  # time, then mouse scrolling stops. The use of imwheel fixes that somehow.
  #
  # Also some software need faster scrolling on X11
  #
  workstation::linux::imwheel::deploy || fail

  # firefox
  # TODO: remove as debian's firefox reaches version 121
  firefox::enable_wayland || fail
}
