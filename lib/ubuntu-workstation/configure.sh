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

ubuntu-workstation::configure-system() {
  # increase inotify limits
  linux::configure_inotify || fail

  # install vm-network-loss-workaround
  if vmware::is_inside_vm; then
    ubuntu-workstation::install-vm-network-loss-workaround || fail
  fi
}

ubuntu-workstation::configure-servers() {
  # postgresql
  sudo systemctl --quiet --now enable postgresql || fail
  postgresql::create_role_if_not_exists "${USER}" WITH SUPERUSER CREATEDB CREATEROLE LOGIN || fail
}

ubuntu-workstation::configure-desktop-software() {
  # configure firefox
  ubuntu-workstation::configure-firefox || fail
  firefox::enable_wayland || fail

  # configure imwheel
  if [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then
    ubuntu-workstation::configure-imwhell || fail
  fi

  # configure home folders
  ubuntu-workstation::configure-home-folders || fail

  # configure gnome desktop
  ubuntu-workstation::configure-gnome || fail
}

ubuntu-workstation::configure-firefox() {
  firefox::set_pref "mousewheel.default.delta_multiplier_x" 200 || fail
  firefox::set_pref "mousewheel.default.delta_multiplier_y" 200 || fail
}

ubuntu-workstation::configure-imwhell() {
  local repetitions="2"
  local output_file="${HOME}/.imwheelrc"
  tee "${output_file}" <<EOF || fail "Unable to write file: ${output_file} ($?)"
".*"
None,      Up,   Button4, ${repetitions}
None,      Down, Button5, ${repetitions}
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
EOF

  dir::make_if_not_exists "${HOME}/.config" 755 || fail
  dir::make_if_not_exists "${HOME}/.config/autostart" 700 || fail

  local output_file="${HOME}/.config/autostart/imwheel.desktop"
  tee "${output_file}" <<EOF || fail "Unable to write file: ${output_file} ($?)"
[Desktop Entry]
Type=Application
Exec=/usr/bin/imwheel
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Custom scroll speed
Comment=Custom scroll speed
EOF

  /usr/bin/imwheel --kill
}

ubuntu-workstation::configure-home-folders() {
  local dirs_file="${HOME}/.config/user-dirs.dirs"

  if [ -f "${dirs_file}" ]; then
    local temp_file; temp_file="$(mktemp)" || fail

    if [ -d "${HOME}/Desktop" ]; then
      # shellcheck disable=SC2016
      echo 'XDG_DESKTOP_DIR="${HOME}/Desktop"' >>"${temp_file}" || fail
    fi

    if [ -d "${HOME}/Downloads" ]; then
      # shellcheck disable=SC2016
      echo 'XDG_DOWNLOADS_DIR="${HOME}/Downloads"' >>"${temp_file}" || fail
    fi

    mv "${temp_file}" "${dirs_file}" || fail

    echo 'enabled=false' >"${HOME}/.config/user-dirs.conf" || fail

    dir::remove_if_exists_and_empty "${HOME}/Documents" || fail
    dir::remove_if_exists_and_empty "${HOME}/Music" || fail
    dir::remove_if_exists_and_empty "${HOME}/Pictures" || fail
    dir::remove_if_exists_and_empty "${HOME}/Public" || fail
    dir::remove_if_exists_and_empty "${HOME}/Templates" || fail
    dir::remove_if_exists_and_empty "${HOME}/Videos" || fail

    if [ -f "${HOME}/examples.desktop" ]; then
      rm "${HOME}/examples.desktop" || fail
    fi

    xdg-user-dirs-update || fail
  fi

  ( umask 0177 && touch "${HOME}/.hidden" ) || fail
  file::append_line_unless_present "Desktop" "${HOME}/.hidden" || fail
  file::append_line_unless_present "snap" "${HOME}/.hidden" || fail
}

ubuntu-workstation::configure-gnome() {(
  # use dconf-editor to find key/value pairs
  #
  # Please do not use dbus-launch here because it will introduce side-effect to
  # git:add-credentials-to-gnome-keyring and
  # ssh::add-key-password-to-gnome-keyring
  #
  gnome-set() { gsettings set "org.gnome.$1" "${@:2}" || fail; }
  gnome-get() { gsettings get "org.gnome.$1" "${@:2}"; }

  # Terminal
  local profile_id profile_path

  if profile_id="$(gnome-get Terminal.ProfilesList default 2>/dev/null)"; then
    local profile_path="Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id:1:-1}/"
    
    gnome-set "${profile_path}" exit-action 'hold' || fail
    # TODO: I think I need to try to live with the defaults
    # gnome-set "${profile_path}" login-shell true || fail
  fi

  gnome-set Terminal.Legacy.Settings menu-accelerator-enabled false || fail
  gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ copy '<Primary>c'
  gnome-set Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ paste '<Primary>v'

  # Desktop
  gnome-set shell.extensions.desktop-icons show-trash false || fail
  gnome-set shell.extensions.desktop-icons show-home false || fail

  # Dash
  gnome-set shell.extensions.dash-to-dock dash-max-icon-size 32 || fail
  gnome-set shell.extensions.dash-to-dock dock-fixed false || fail
  gnome-set shell.extensions.dash-to-dock dock-position 'BOTTOM' || fail
  gnome-set shell.extensions.dash-to-dock hide-delay 0.10000000000000001 || fail
  gnome-set shell.extensions.dash-to-dock require-pressure-to-show false || fail
  gnome-set shell.extensions.dash-to-dock show-apps-at-top true || fail
  gnome-set shell.extensions.dash-to-dock show-delay 0.10000000000000001 || fail

  # Nautilus
  gnome-set nautilus.list-view default-zoom-level 'small' || fail
  gnome-set nautilus.list-view use-tree-view true || fail
  gnome-set nautilus.preferences default-folder-viewer 'list-view' || fail
  gnome-set nautilus.preferences show-delete-permanently true || fail
  gnome-set nautilus.preferences show-hidden-files true || fail

  # Automatic timezone
  gnome-set desktop.datetime automatic-timezone true || fail

  # Input sources
  # on mac host: ('xkb', 'ru+mac')
  gnome-set desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]" || fail

  # Disable sound alerts
  gnome-set desktop.sound event-sounds false || fail

  # Enable fractional scaling
  # gnome-set mutter experimental-features "['scale-monitor-framebuffer', 'x11-randr-fractional-scaling']" || fail

  # 1600 DPI mouse
  # gnome-set desktop.peripherals.mouse speed -0.75 || fail

  # dark theme
  gnome-set desktop.interface gtk-theme 'Yaru-dark' || fail
)}
