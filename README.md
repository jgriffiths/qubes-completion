Command line completion for Qubes commands
------------------------------------------

Script to provide command completion for [Qubes](https://www.qubes-os.org/) admin commands.

Usage
-----

```
# Put `qvm_completion.sh` somewhere in your home directory, e.g.
mkdir ~/.qubes
mv qvm_completion.sh ~/.qubes/.qvm_completion.sh

# Source the file from your login script, e.g.
echo '. ~/.qubes/qvm_completion.sh' >>~/.bashrc
```

To use in non-dom0 VMs (template, proxy and app VMs), also do e.g.

```
# Add VM names to ~/.qubes/known_vms
# Use 'qvm-ls --raw-list' in dom0 to get a full list
mkdir ~/.qubes
vms="dom0 sys-net sys-firewall fedora-23 vault work personal untrusted"
for vm in $vms; do echo "$vm" >> ~/.qubes/known_vms; done
```

Note
----

VMs outside of dom0 cannot usually get a list of the other VMs on the
system AFAICS.

Adding VM names to `known_vms` makes them visible to any app that
can read this file. Bear in mind that this file could therefore be used
to fingerprint a VM and/or discover other VMs on the system if
non-default VMs are added to it.

You may wish to place only the default installation VMs to `known_vms`
in your template VM. These names are fixed on install and so do not
give away any new information. In your app VMs you can then add the
non-default VM names that you use regularly taking care to assess the
risk of leaking this information in each VM.
