<!--
Copyright 2012-2021 Stanislav Senotrusov <stan@senotrusov.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->
# 🚞 Sopkafile to configure my workstation

A script to configure my workstation. I run it on a freshly installed Linux, MacOS, or Windows.

It will do the following:

1. Installs the basic software I frequently use.
2. Installs keys and software licenses from my bitwarden database.
3. Makes a few tweaks to the system and to the desktop software.
4. Installs a few shell aliases.
5. Installs configuration for the Sublime Text and Visual Studio Code (there is also a script to keep configuration in the repository up to date with the local changes).

This script is idempotent. It can be run multiple times to produce a system which is up-to date with the recent software updates and with my configuration changes.

The file ``config.sh`` contains my name and email to use in configuration. Please remove them if you happen to fork this script.

## Linux

```sh
bash <(wget -qO- https://raw.githubusercontent.com/senotrusov/sopka/main/deploy.sh) \
senotrusov/sopkafile
```

## MacOS

```sh
bash <(curl -Ssf https://raw.githubusercontent.com/senotrusov/sopka/main/deploy.sh) \
senotrusov/sopkafile
```

## Windows

1. Start PowerShell as administrator, run the following and wait for it to complete:

```sh
iwr -UseBasicParsing "https://raw.githubusercontent.com/senotrusov/sopkafile/main/deploy.ps1" | iex
```

2. At this point, Git Bash should be installed by the first script. Start Git Bash as your regular user and run the following:

```sh
~/.sopka/bin/sopka
```

3. Start PowerShell as a regular user, and make sure you really understand consequences of the next command before you run it:

```sh
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

## Secret items which are expected to be found in a Bitwarden

Record names should be as the following:

<!-- # bitwarden-object: see list below -->

```
"my github personal access token"
"my microsoft account"
"my password for ssh private key"
"my ssh private key"
"my ssh public key"
"my tailscale reusable key"
"sublime text 3 license"
```

## Contributing

### Please check shell scripts before commiting any changes
```sh
lint/lint.sh
```
