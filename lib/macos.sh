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

macos::deploy-workstation() {
  macos::install-basic-packages || fail
  macos::install-developer-packages || fail
  macos::configure-workstation || fail
  tools::display-elapsed-time || fail
}

macos::configure-workstation() {
  macos::increase-maxfiles-limit || fail

  # shell aliases
  shellrcd::install || fail
  shellrcd::use-nano-editor || fail
  shellrcd::sopka-src-path || fail
  shellrcd::hook-direnv || fail

  # ruby
  rbenv rehash || fail
  shellrcd::rbenv || fail
  ruby::install-gemrc || fail

  # nodejs
  shellrcd::nodenv || fail

  # git
  git::configure || fail

  # vscode
  vscode::install-config || fail

  # sublime text
  sublime::install-config || fail

  # SSH keys
  ssh::install-keys || fail
  macos::ssh::add-use-keychain-to-ssh-config || fail
  macos::ssh::add-ssh-key-password-to-keychain || fail

  # hide folders
  macos::hide-folders || fail
}

macos::install-basic-packages() {
  # install homebrew
  macos::install-homebrew || fail

  # update and upgrade homebrew
  brew update || fail
  brew upgrade || fail

  # fan and battery
  brew cask install macs-fan-control || fail
  brew cask install coconutbattery || fail

  # syncthing
  brew install syncthing || fail
  brew services start syncthing || fail

  # productivity tools
  brew cask install bitwarden || fail
  brew cask install discord || fail
  brew cask install grandperspective || fail
  brew cask install libreoffice || fail
  brew cask install skype || fail
  brew cask install telegram || fail
  brew cask install the-unarchiver || fail

  # chromium
  brew cask install chromium || fail

  # media tools
  brew cask install vlc || fail
  brew cask install obs || fail
}

macos::install-developer-packages() {
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
  brew install awscli || fail
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
  brew cask install meld || fail

  # sublime merge
  brew cask install sublime-merge || fail

  # sublime text
  brew cask install sublime-text || fail

  # vscode
  brew cask install visual-studio-code || fail
  vscode::install-extensions || fail

  # iterm2
  brew cask install iterm2 || fail

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
  brew install sshfs || fail
}

macos::hide-folders() {
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
