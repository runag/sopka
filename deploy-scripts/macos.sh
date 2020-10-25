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

macos::deploy-non-developer-workstation() {
  DEPLOY_NON_DEVELOPER_WORKSTATION=true macos::deploy-workstation || fail
}

macos::deploy-workstation() {
  # init footnotes
  deploy-lib::footnotes::init || fail

  # maxfiles limit
  macos::increase-maxfiles-limit || fail

  # basic packages
  macos::install-basic-packages || fail

  if [ "${DEPLOY_NON_DEVELOPER_WORKSTATION:-}" != "true" ]; then
    # developer packages
    macos::install-developer-packages || fail

    # shell aliases
    deploy-lib::shellrcd::install || fail
    deploy-lib::shellrcd::use-nano-editor || fail
    deploy-lib::shellrcd::my-computer-deploy-path || fail
    deploy-lib::shellrcd::hook-direnv || fail
    data-pi::shellrcd::shell-aliases || fail

    # SSH keys
    deploy-lib::ssh::install-keys || fail
    macos::ssh::add-use-keychain-to-ssh-config || fail
    macos::ssh::add-ssh-key-password-to-keychain || fail

    # git
    deploy-lib::git::configure || fail

    # vscode
    vscode::install-config || fail
    vscode::install-extensions || fail

    # sublime text
    sublime::install-config || fail

    # hide folders
    macos::hide-folders || fail
  fi

  # flush footnotes
  deploy-lib::footnotes::flush || fail
  deploy-lib::footnotes::display-elapsed-time || fail

  # communicate to the user that we have reached the end of a script without major errors
  echo "macos::deploy-workstation completed"
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
  brew cask install libreoffice || fail
  brew cask install skype || fail
  brew cask install the-unarchiver || fail
  brew cask install grandperspective || fail

  # please install it from the app store, as direct sources may be blocked in some countries
  # brew cask install telegram || fail

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

  # servers
  brew install memcached || fail
  brew services start memcached || fail

  brew install redis || fail
  brew services start redis || fail
  
  brew install postgresql || fail
  brew services start postgresql || fail

  # tor
  brew install tor || fail
  brew services start tor || fail

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

  # iterm2
  brew cask install iterm2 || fail

  # linode-cli
  pip3 install linode-cli --upgrade || fail

  # direnv
  brew install direnv || fail

  # gnupg
  brew install gnupg || fail

  # ruby

  # a) latest ruby
  # brew install ruby || fail
  # macos::shellrcd::homebrew-ruby || fail

  # b) rbenv
  brew install rbenv || fail
  rbenv rehash || fail
  deploy-lib::shellrcd::rbenv || fail
  deploy-lib::ruby::install-gemrc || fail

  # nodejs

  # a) latest nodejs
  # brew install node || fail
  # brew install yarn || fail

  # b) node
  brew install nodenv || fail
  deploy-lib::shellrcd::nodenv || fail
  brew install yarn || fail

  # bitwarden-cli (after nodejs)
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
