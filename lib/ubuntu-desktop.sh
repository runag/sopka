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

ubuntu::desktop::configure() {
  apt::install dconf-editor || fail

  # configure gnome desktop
  ubuntu::desktop::configure-gnome || fail

  # imwheel
  apt::install imwheel || fail
  ubuntu::desktop::setup-imwhell || fail

  # fixes for nvidia
  if nvidia::is-card-present; then
    nvidia::fix-screen-tearing || fail
    nvidia::fix-gpu-background-image-glitch || fail
  fi

  # enable wayland for firefox
  ubuntu::desktop::moz-enable-wayland || fail

  # remove user dirs
  ubuntu::desktop::remove-user-dirs || fail

  # hide folders
  ubuntu::desktop::hide-folder "Desktop" || fail
  ubuntu::desktop::hide-folder "snap" || fail
  ubuntu::desktop::hide-folder "VirtualBox VMs" || fail

  # vitals gnome shell extension
  if ! vmware::linux::is-inside-vm; then
    ubuntu::desktop::install-vitals || fail
  fi
}

ubuntu::desktop::remove-user-dirs() {
  local dirsFile="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirsFile}" ]; then
    local tmpFile; tmpFile="$(mktemp)" || fail

    if [ -d "$HOME/Desktop" ]; then
      echo 'XDG_DESKTOP_DIR="$HOME/Desktop"' >>"${tmpFile}" || fail
    fi

    if [ -d "$HOME/Downloads" ]; then
      echo 'XDG_DOWNLOADS_DIR="$HOME/Downloads"' >>"${tmpFile}" || fail
    fi

    mv "${tmpFile}" "${dirsFile}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    fs::remove-dir-if-empty "$HOME/Documents" || fail
    fs::remove-dir-if-empty "$HOME/Music" || fail
    fs::remove-dir-if-empty "$HOME/Pictures" || fail
    fs::remove-dir-if-empty "$HOME/Public" || fail
    fs::remove-dir-if-empty "$HOME/Templates" || fail
    fs::remove-dir-if-empty "$HOME/Videos" || fail

    if [ -f "$HOME/examples.desktop" ]; then
      rm "$HOME/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi
}

# use dconf-editor to find key/value pairs
#
# Don't use dbus-launch here because it will introduce
# side-effect to git::ubuntu::add-credentials-to-keyring and ssh::ubuntu::add-key-password-to-keyring

ubuntu::desktop::configure-gnome() {
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    # Enable fractional scaling
    ubuntu::desktop::enable-fractional-scaling || fail

    # Automatic timezone
    gsettings::perhaps-set org.gnome.desktop.datetime automatic-timezone true || fail

    # Terminal
    gsettings::perhaps-set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false || fail

    if gsettings get org.gnome.Terminal.ProfilesList default >/dev/null; then
      local terminalProfile; terminalProfile="$(gsettings get org.gnome.Terminal.ProfilesList default)" || fail "Unable to determine terminalProfile ($?)"
      local profilePath="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${terminalProfile:1:-1}/"

      gsettings::perhaps-set "$profilePath" exit-action 'hold' || fail
      gsettings::perhaps-set "$profilePath" login-shell true || fail
    fi

    # Nautilus
    gsettings::perhaps-set org.gnome.nautilus.list-view default-zoom-level 'small' || fail
    gsettings::perhaps-set org.gnome.nautilus.list-view use-tree-view true || fail
    gsettings::perhaps-set org.gnome.nautilus.preferences default-folder-viewer 'list-view' || fail
    gsettings::perhaps-set org.gnome.nautilus.preferences show-delete-permanently true || fail
    gsettings::perhaps-set org.gnome.nautilus.preferences show-hidden-files true || fail

    # Desktop
    gsettings::perhaps-set org.gnome.shell.extensions.desktop-icons show-trash false || fail
    gsettings::perhaps-set org.gnome.shell.extensions.desktop-icons show-home false || fail

    # Dash
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dock-fixed false || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock hide-delay 0.10000000000000001 'BOTTOM' || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show false || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true 'BOTTOM' || fail
    gsettings::perhaps-set org.gnome.shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail

    # Disable sound alerts
    gsettings::perhaps-set org.gnome.desktop.sound event-sounds false || fail

    # 1600 DPI mouse
    gsettings::perhaps-set org.gnome.desktop.peripherals.mouse speed -0.75 || fail

    # Input sources
    # on mac host: ('xkb', 'ru+mac')
    gsettings::perhaps-set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail
  fi
}
