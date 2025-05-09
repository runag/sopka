#!/bin/sh

#  Copyright 2012-2025 Runag project contributors
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

# Exit if any unset variable is used.
set -o nounset

# This script installs the tool by linking the main executable and its Bash completion file.
# It must be run as './deploy.sh' from the root of a local Git repository.

# Define the main script filename and the destination directory for installation.
script_file="sopka"
script_dir="${HOME}/.local/bin"

# Prevent execution as the root user to avoid unintentional system-wide changes.
if [ "${USER}" = root ]; then
  echo "Do not run this script as the root user." >&2
  exit 1
fi

# Determine the Bash completions directory, using user-specific or default location.
completions_dir="${BASH_COMPLETION_USER_DIR:-"${XDG_DATA_HOME:-"$HOME/.local/share"}/bash-completion"}/completions"

# Create the user's local binary directory with secure permissions.
( umask 077 && mkdir -p "${script_dir}" ) ||
  { echo "Failed to create the local binary directory at '${script_dir}'." >&2; exit 1; }

# Create the user's Bash completions directory with secure permissions.
( umask 077 && mkdir -p "${completions_dir}" ) ||
  { echo "Failed to create the completions directory at '${completions_dir}'." >&2; exit 1; }

# Ensure this script is being run as 'deploy.sh' and from within a Git repository.
command_file="$(basename "$0")" || { echo "Could not determine the script name from '$0'." >&2; exit 1; }

if [ "${command_file}" != "deploy.sh" ] || [ ! -d .git ]; then
  echo "Run this script as 'deploy.sh' from the root of a local Git repository." >&2
  exit 1
fi

# Announce the start of deployment.
echo "Deploying from the local Git repository at '${PWD}'..."

# Resolve the absolute path to the target script within the bin directory.
bin_path="$(realpath --canonicalize-existing "bin/${script_file}")" ||
  { echo "Failed to locate 'bin/${script_file}' using realpath." >&2; exit 1; }

# Create a symbolic link to the script in the user's local bin directory.
ln --interactive --symbolic "${bin_path}" "${script_dir}/${script_file}" ||
  { echo "Failed to create a symbolic link from '${bin_path}' to '${script_dir}/${script_file}'." >&2; exit 1; }

# TODO: Enable once the completions script is implemented.

# # Resolve the absolute path to the Bash completion script.
# completion_path="$(realpath --canonicalize-existing "completions/bash/${script_file}")" ||
#   { echo "Failed to locate 'completions/bash/${script_file}' using realpath." >&2; exit 1; }

# # Link the completion script into the completions directory.
# ln --interactive --symbolic "${completion_path}" "${completions_dir}/${script_file}" ||
#   { echo "Failed to create a symbolic link from '${completion_path}' to '${completions_dir}/${script_file}'." >&2; exit 1; }
