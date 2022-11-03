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

key-storage::populate_sopka_menu() {
  local dir

  if [[ "${OSTYPE}" =~ ^msys ]]; then
    key-storage::add_sopka_menu_for_directory "/k" || fail

  elif [[ "${OSTYPE}" =~ ^darwin ]]; then
    for dir in "/Volumes/"*KEYS* ; do
      key-storage::add_sopka_menu_for_directory "$dir" || fail
    done

  elif [[ "${OSTYPE}" =~ ^linux ]]; then
    for dir in "/media/${USER}/"*KEYS* ; do
      key-storage::add_sopka_menu_for_directory "$dir" || fail
    done

  fi

  key-storage::add_sopka_menu_for_directory "." || fail
}

key-storage::add_sopka_menu_for_directory() {
  local dir="$1"
  if [ -d "$dir" ] && [ -d "$dir/"*keys* ]; then
    sopka_menu::add_header "Key storage in ${dir}" || fail
    
    sopka_menu::add key-storage::maintain_checksums "${dir}" || fail
    sopka_menu::add key-storage::make_copies "${dir}" || fail
  fi
}

key-storage::maintain_checksums() {
  local media="$1"

  local dir; for dir in "${media}/"*keys* ; do
    if [ -d "${dir}" ]; then
      fs::with_secure_temp_dir_if_available checksums::create_or_update "${dir}" "checksums.txt" || fail
    fi
  done

  local dir; for dir in "${media}/copies/"*/* ; do
    if [ -d "${dir}" ]; then
      fs::with_secure_temp_dir_if_available checksums::verify "${dir}" "checksums.txt" || fail
    fi
  done
}

key-storage::make_copies() {
  local media="$1"

  local copies_dir="${media}/copies"
  dir::make_if_not_exists "${copies_dir}" || fail
  
  local dest_dir; dest_dir="${copies_dir}/$(date --utc +"%Y%m%dT%H%M%SZ")" || fail
  dir::make_if_not_exists "${dest_dir}" || fail

  local dir; for dir in "${media}/"*keys* ; do
    if [ -d "${dir}" ]; then
      cp -R "${dir}" "${dest_dir}" || fail
    fi
  done
  sync || fail
  echo "${dest_dir}"
}

if declare -f sopka_menu::add >/dev/null; then
  key-storage::populate_sopka_menu || fail
fi
