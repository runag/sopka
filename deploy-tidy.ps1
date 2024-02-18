#  Copyright 2012-2022 Rùnag project contributors
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


$ErrorActionPreference = "Stop"

# Allow untrusted script execution
Write-Output "Setting execution policy..." 
Set-ExecutionPolicy Bypass -Scope Process -Force


# Install and configure chocolatey
if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  Write-Output "Installing chocolatey..." 
  # Set-ExecutionPolicy Bypass -Scope Process -Force
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://chocolatey.org/install.ps1"))
}

if (-Not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
  throw "Unable to find choco"
}

choco feature enable -n allowGlobalConfirmation
if ($LASTEXITCODE -ne 0) { throw "Unable to set chocolatey feature" }


# Install packages
choco install firefox
if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }

choco install far
if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }

choco install windirstat
if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }

choco install discord
if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }

choco install streamlabs-obs
if ($LASTEXITCODE -ne 0) { throw "Unable to install package" }


# Upgrade packages
choco upgrade all --yes
if ($LASTEXITCODE -ne 0) { throw "Unable to upgrade installed choco packages" }
