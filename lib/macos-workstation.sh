#!/usr/bin/env bash

#  Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>
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

if declare -f sopka-menu::add >/dev/null; then
  sopka-menu::add macos-workstation::deploy || fail
  sopka-menu::add macos-workstation::configure || fail
fi

macos-workstation::deploy() {
  macos-workstation::install-basic-packages || fail
  macos-workstation::install-developer-packages || fail
  macos-workstation::configure || fail
  
  log::success "Done macos-workstation::deploy" || fail
}

macos-workstation::install-basic-packages() {
  # install homebrew
  macos::install-homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew install --cask macs-fan-control || fail
  brew install --cask coconutbattery || fail

  # productivity tools
  brew install --cask bitwarden || fail
  brew install --cask discord || fail
  brew install --cask grandperspective || fail
  brew install --cask libreoffice || fail
  brew install --cask skype || fail
  brew install --cask telegram || fail
  brew install --cask the-unarchiver || fail

  # chromium
  brew install --cask chromium || fail

  # media tools
  brew install --cask vlc || fail
  brew install --cask obs || fail
}

macos-workstation::install-developer-packages() {
  # basic tools
  brew install jq || fail
  brew install midnight-commander || fail
  brew install ranger || fail
  brew install ncdu || fail
  brew install htop || fail
  brew install p7zip || fail
  brew install sysbench || fail
  brew install hwloc || fail
  brew install tmux || fail

  # dev tools
  if [ ! -e /usr/local/bin/aws ]; then
    brew install awscli || fail
  fi

  brew install graphviz || fail
  brew install imagemagick || fail
  brew install ghostscript || fail
  brew install shellcheck || fail

  # memcached
  brew install memcached || fail
  brew services start memcached || fail

  # redis
  brew install redis || fail
  brew services start redis || fail

  # postgresql
  brew install postgresql || fail
  brew services start postgresql || fail

  # ffmpeg
  brew install ffmpeg || fail

  # meld
  brew install --cask meld || fail

  # sublime merge
  brew install --cask sublime-merge || fail

  # sublime text
  brew install --cask sublime-text || fail

  # vscode
  brew install --cask visual-studio-code || fail

  # iterm2
  brew install --cask iterm2 || fail

  # linode-cli
  pip3 install linode-cli --upgrade || fail

  # direnv
  brew install direnv || fail

  # gnupg
  brew install gnupg || fail

  # ruby
  brew install rbenv || fail

  # nodejs
  brew install nodenv || fail
  brew install yarn || fail

  # bitwarden-cli
  brew install bitwarden-cli || fail

  # sshfs
  # That will fail in CI test environment, so I disabled error checking here. Perhaps there is a better solution for that.
  brew install sshfs || true
}

macos-workstation::configure() {
  # increase maxfiles limits
  macos::increase-maxfiles-limit || fail

  # hide folders
  macos-workstation::hide-folders || fail

  # shell aliases
  shellrc::install-loader "${HOME}/.bashrc" || fail
  shellrc::install-loader "${HOME}/.zshrc" || fail
  shellrc::install-nano-editor-rc || fail
  shellrc::install-sopka-path-rc || fail
  shellrc::install-direnv-rc || fail

  # ruby
  ruby::dangerously-append-nodocument-to-gemrc || fail
  ruby::install-rbenv-shellrc || fail
  ruby::load-rbenv || fail

  # nodejs
  nodejs::install-nodenv-shellrc || fail
  nodejs::configure-mismatched-binaries-workaround || fail
  nodejs::load-nodenv || fail

  # vscode
  vscode::install-config || fail
  local selfDir; selfDir="$(dirname "${BASH_SOURCE[0]}")" || fail
  vscode::install-extensions "${selfDir}/vscode/extensions.txt" || fail

  # sublime text config
  sublime-text::install-config || fail

  # secrets
  if [ -t 0 ]; then
    (
      # add ssh key, configure ssh to use it
      workstation::install-ssh-keys || fail
      ssh::macos-keychain::configure-use-on-all-hosts || fail
      bitwarden::use password "my password for ssh private key" ssh::macos-keychain || fail

      # rubygems
      workstation::install-rubygems-credentials || fail

      # npm
      workstation::install-npm-credentials || fail

      # sublime text license
      sublime-text::install-license || fail
    ) || fail
  fi

  # git
  workstation::configure-git || fail

  log::success "Done macos-workstation::configure" || fail
}

macos-workstation::hide-folders() {
  macos::hide-folder "${HOME}/Applications" || fail
  macos::hide-folder "${HOME}/Desktop" || fail
  macos::hide-folder "${HOME}/Documents" || fail
  macos::hide-folder "${HOME}/Movies" || fail
  macos::hide-folder "${HOME}/Music" || fail
  macos::hide-folder "${HOME}/Pictures" || fail
  macos::hide-folder "${HOME}/Public" || fail
  macos::hide-folder "${HOME}/Virtual Machines.localized" || fail
  macos::hide-folder "${HOME}/VirtualBox VMs" || fail
}
