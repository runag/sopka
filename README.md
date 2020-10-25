# Deployment
```sh
bin/deploy-data-pi
bin/deploy-mac-syncthing
bin/deploy-ubuntu-workstation
```

# Utilities
## Deployment shell

Any time later after the initial deployment you may wish to run those scripts again to update the system.

For that please keep the original directory somewhere.

The command ``my-computer-deploy`` will be available as a shell alias after the initial deployment. Upon execution it will open a subshell that brings you to the directory that contains the initial deployment scripts. It's ``bin`` will be in that subshell's ``PATH``.

## Misc
```sh
bin/copy-my-current-ssh-key-password-to-clipboard
```

# Merge configs between the live system and the deploy repository
```sh
bin/merge-ubuntu-workstation-configs
```

# Manual backups
```sh
bin/backup-polina-archive
bin/backup-stan-archive
```

# Secret items which are stored in Bitwarden

The names should be as the following:

``my current ssh private key``  
``my current ssh public key``  
``my current password for ssh private key``  
``Sublime Text 3 license``  
``data-pi onion address``  
``kelly disk key``  

# Please check shell scripts before commiting any changes
```sh
shellcheck bin/* *.sh **/*.sh
```
