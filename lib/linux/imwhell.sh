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

workstation::linux::imwheel::deploy() {
  workstation::linux::imwheel::configure || fail
  workstation::linux::imwheel::reenable || fail
}

workstation::linux::imwheel::configure() {

  # Rationale
  #
  # 1. It seems to me that in applications that use Skia, scrolling works twice as slow when compared to Firefox or to Gnome applications
  # 2. In the absence of the following tedious list of modifiers, fast scrolling (alt + scroll) in Visual Studio Code does not work

  file::write "${HOME}/.imwheelrc" <<EOF || fail
"^(Code)$"
None,      Up,   Button4, 2
None,      Down, Button5, 2
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Alt_L|Button4
Alt_L,     Down, Alt_L|Button5
Alt_R,     Up,   Alt_R|Button4
Alt_R,     Down, Alt_R|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5

"^(Sublime_merge|Chromium|Bitwarden)$"
None,      Up,   Button4, 2
None,      Down, Button5, 2
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Control_R, Up,   Control_R|Button4
Control_R, Down, Control_R|Button5
Alt_L,     Up,   Button4, 8
Alt_L,     Down, Button5, 8
Alt_R,     Up,   Alt_R|Button4
Alt_R,     Down, Alt_R|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
Shift_R,   Up,   Shift_R|Button4
Shift_R,   Down, Shift_R|Button5
Meta_L,    Up,   Meta_L|Button4
Meta_L,    Down, Meta_L|Button5
Meta_R,    Up,   Meta_R|Button4
Meta_R,    Down, Meta_R|Button5

EOF

# ".*" will match all

}

workstation::linux::imwheel::reenable() {
  dir::make_if_not_exists "${HOME}/.config" 755 || fail
  dir::make_if_not_exists "${HOME}/.config/autostart" 700 || fail

  file::write "${HOME}/.config/autostart/imwheel.desktop" <<EOF || fail
[Desktop Entry]
Type=Application
Exec=/usr/bin/imwheel
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;XFCE;
Name[en_US]=IMWheel
Name=IMWheel
Comment[en_US]=Scripting for mouse wheel and buttons
Comment=Scripting for mouse wheel and buttons
EOF

  /usr/bin/imwheel --kill
}

workstation::linux::imwheel::disable() {
  rm "${HOME}/.config/autostart/imwheel.desktop" || fail
  pkill --full "/usr/bin/imwheel"
  [[ $? =~ ^[01]$ ]] || fail
}

workstation::linux::imwheel::debug() {
  /usr/bin/imwheel --kill --detach --debug
}
