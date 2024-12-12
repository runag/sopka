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

workstation::linux::install_packages() (
  # Load operating system identification data
  . /etc/os-release || fail

  # perform system upgrade
  linux::upgrade_system || fail

  # install tools to use by the rest of the script
  linux::install_runag_essential_dependencies || fail

  # ensure ~/.local/bin exists
  dir::should_exists --mode 0700 "${HOME}/.local" || fail
  dir::should_exists --mode 0700 "${HOME}/.local/bin" || fail

  # install shellfiles
  shellfile::install_loader::bash || fail
  shellfile::install_runag_path_profile --source-now || fail
  shellfile::install_local_bin_path_profile --source-now || fail
  shellfile::install_direnv_rc || fail

  # install packages
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    workstation::linux::install_packages::debian || fail
  elif [ "${ID:-}" = arch ]; then
    workstation::linux::install_packages::arch || fail
  fi

  # install aws-cli from snap
  if [ "${ID:-}" = ubuntu ]; then
    sudo snap install aws-cli --classic || fail
  fi

  # install restic from github
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    restic::install "0.17.1" || fail
  fi

  # asdf
  asdf::install_dependencies || fail
  asdf::install_with_shellrc || fail

  # nodejs
  nodejs::install_dependencies || fail
  asdf::add_plugin_install_package_and_set_global nodejs || fail

  # ruby
  ruby::dangerously_append_nodocument_to_gemrc || fail
  ruby::install_disable_spring_shellfile || fail
  ruby::install_dependencies || fail
  ruby::without_docs asdf::add_plugin_install_package_and_set_global ruby || fail

  # python
  python::install || fail

  # erlang & elixir
  erlang::install_dependencies || fail
  erlang::install_dependencies::observer || fail
  asdf::add_plugin_install_package_and_set_global erlang || fail
  asdf::add_plugin_install_package_and_set_global elixir || fail
  mix local.hex --if-missing --force || fail
  mix local.rebar --if-missing --force || fail
  mix archive.install hex phx_new --force || fail

  # gnome-keyring and libsecret (for git and ssh)
  linux::install_gnome_keyring_and_libsecret || fail

  # install libsecret credential helper for git
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    git::install_libsecret_credential_helper || fail
  fi

  # install micro text editor plugins
  # micro -plugin install filemanager || fail

  # install vscode
  if [ "${ID:-}" = debian ] || [ "${ID_LIKE:-}" = debian ]; then
    vscode::install::apt || fail
    # sudo snap install code --classic || fail
  elif [ "${ID:-}" = arch ]; then
    true # TODO: install vscode
    # sudo pacman --sync --needed --noconfirm code || fail
  fi

  # install sublime text and sublime merge
  sublime_merge::install || fail
  sublime_text::install || fail

  # install syncthing
  syncthing::install || fail

  # insall blankfast
  blankfast::install || fail
)

workstation::linux::install_packages::debian() (
  # Load operating system identification data
  . /etc/os-release || fail

  local package_list=(
    # # desktop: browsers

    # # desktop: text editors
    ghex
    meld

    # # desktop: content creation
    # inkscape
    # obs-studio
    krita
    libreoffice-calc
    libreoffice-writer

    # # desktop: content consumption
    calibre
    vlc

    # # desktop: misc tools
    # gpa # gnu privacy assistant
    # gparted
    # thunar
    dconf-editor
    qtpass

    # # desktop: fonts

    # # desktop: hardware
    # ddcutil # display control
    # pavucontrol # volume control
    imwheel # mouse wheel
    v4l-utils # webcam control

    # # terminal ui
    # debian-goodies # checkrestart
    # htop
    direnv
    mc
    micro
    ncdu
    tmux
    xclip
    xkcdpass
    zsh

    # # build and developer tools
    # inotify-tools
    build-essential
    git
    gnupg
    libsqlite3-dev
    libssl-dev
    shellcheck

    # # databases and servers
    # memcached
    # redis-server
    libpq-dev
    postgresql
    postgresql-contrib
    sqlite3

    # # cloud and networking
    # ethtool
    certbot
    whois

    # # batch media processing
    # graphviz
    ffmpeg
    imagemagick
    zbar-tools

    # # storage and files
    # btrfs-compsize
    # dosfstools # gparted dependencies for fat partitions
    # mtools # gparted dependencies for fat partitions
    # rclone
    nvme-cli
    p7zip-full

    # # benchmarks
    # apache2-utils
    # hyperfine
    # iperf3
    # sysbench
  )

  if [ "${ID:-}" = debian ]; then
    package_list+=(awscli)
  fi

  if [ "$(systemd-detect-virt)" = "kvm" ]; then
    package_list+=(spice-vdagent)
  fi

  apt::install "${package_list[@]}" || fail
)

workstation::linux::install_packages::arch() {
  local package_list=(
    # # desktop: browsers
    chromium
    firefox

    # # desktop: text editors
    ghex
    meld

    # # desktop: content creation
    # inkscape
    # obs-studio
    krita
    libreoffice-fresh

    # # desktop: content consumption
    calibre
    vlc

    # # desktop: misc tools
    # gparted
    # thunar
    dconf-editor
    gnome-terminal
    qtpass

    # # desktop: fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    ttf-dejavu

    # # desktop: hardware
    # ddcutil # display control
    # pavucontrol # volume control
    imwheel # mouse wheel
    v4l-utils # webcam control

    # # terminal ui
    # htop
    direnv
    fzf
    mc
    micro
    ncdu
    tmux
    xclip
    xkcdpass
    zsh

    # # build and developer tools
    # inotify-tools
    base-devel
    git
    gnupg
    openssl
    shellcheck

    # # databases and servers
    # memcached
    # redis-server
    postgresql
    sqlite

    # # cloud and networking
    # ethtool
    aws-cli
    certbot
    whois

    # # batch media processing
    # graphviz
    ffmpeg
    imagemagick
    zbar

    # # storage and files
    # compsize
    # dosfstools # gparted dependencies for fat partitions
    # mtools # gparted dependencies for fat partitions
    # rclone
    nvme-cli
    p7zip
    restic

    # # benchmarks
    # apache
    # fio
    # hyperfine
    # iperf3
    # sysbench
  )

  # software for kvm
  if [ "$(systemd-detect-virt)" = "kvm" ]; then
    package_list+=(spice-vdagent)
  fi

  sudo pacman --sync --needed --noconfirm "${package_list[@]}" || fail

  # patch things for restic
  if ! command -v fusermount >/dev/null; then
    ln -s /bin/fusermount3 ~/.local/bin/fusermount || fail
  fi
}
