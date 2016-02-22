#
# Bash command line completion for Qubes admin commands.
#
# Copyright (C) 2016 Jon Griffiths <jon_p_griffiths@yahoo.com>
#
# FIXME:
# qvm-init-storage Takes no args (should take help at least)
# qvm-sync-appmenus forwards to /usr/libexec/qubes-appmenus/qubes-receive-appmenus
# qvm-convert-pdf/qvm-mru-entry

_qvm_known_vms()
{
    if [[ -x /usr/bin/qvm-ls ]]; then
        /usr/bin/qvm-ls --raw-list | sort
    elif [[ -f ~/.qubes/known_vms ]]; then
        cat ~/.qubes/known_vms | tr ' ' '\n' | sed '/^$/d' | tr '\n' ' '
    fi
}

_qvm_ssl_list()
{
    openssl $1 | fgrep -v "=>" | sort | uniq
}

_qvm_ciphers() { _qvm_ssl_list list-cipher-algorithms; }
_qvm_digests() { _qvm_ssl_list list-message-digest-algorithms; }

_qvm_known_devices()
{
    /usr/bin/qvm-block --list | grep "$1" | sed 's/\t.*//g' | sort | tr '\n' ' '
}

_qvm_cmd()
{
    local cmd=$1; shift
    local breaks="$COMP_WORDBREAKS"
    COMP_WORDBREAKS="${breaks//:}"
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [[ $prev == "-h" || $prev == "--help" ]]; then
        return 0 # Nothing ever follows -h/--help
    fi

    if [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W "-h --help $*" -- $cur)) # Options
        return 0
    fi

     if [[ $cmd == 'qvm-backup' ]]; then
        if [[ $prev == '-E' || $prev == '--enc-algo' ]]; then
            COMP_WORDBREAKS="$breaks"
            COMPREPLY=($(compgen -W "$(_qvm_ciphers)" -- $cur)) # Ciphers
            return 0
        elif [[ $prev == '-H' || $prev == '--hmac-algo' ]]; then
            COMPREPLY=($(compgen -W "$(_qvm_digests)" -- $cur)) # Msg digests
            COMP_WORDBREAKS="$breaks"
            return 0
        fi
    fi
    COMP_WORDBREAKS="$breaks"

     if [[ $cmd == 'qvm-block' ]]; then
        if [[ $prev == '-d' || $prev == '--detach' ]]; then
            COMPREPLY=($(compgen -W "$(_qvm_known_devices attached)" -- $cur)) # Devices
            return 0
        elif [[ (( ${COMP_CWORD} > 1 )) && ($prev != -*) ]]; then
            COMPREPLY=($(compgen -W "$(_qvm_known_devices ' ')" -- $cur)) # Devices
            return 0
        fi
    fi

    if [[ $cmd == 'qvm-firewall' && \
          ($prev == '-P' || $prev == '--policy' || \
           $prev == '-i' || $prev == '--icmp' || \
           $prev == '-D' || $prev == '--dns' || \
           $prev == '-Y' || $prev == '--yum-proxy') ]]; then
        COMPREPLY=($(compgen -W "allow deny" -- $cur)) # Access (allow/deny)
        return 0
    fi

    COMPREPLY=($(compgen -f -- $cur)) # Filenames

    if [[ $cmd == 'qvm-create-default-dvm' || \
          $prev == '--attach-file' || $prev == '--conf' || $prev == '--path' || \
          $prev == '--root-copy-from' || $prev == '--root-move-from' || \
          ($cmd == 'qvm-add-appvm'    && ($prev == '-p' || $prev == '-c')) || \
          ($cmd == 'qvm-add-template' && ($prev == '-p' || $prev == '-c')) || \
          ($cmd == 'qvm-create' && ($prev == '-r' || $prev == '-R')) || \
          ($cmd == 'qvm-clone' && $prev == '-prev') ]]; then
        return 0; # Use filename instead of maybe VM below
    fi

    if [[ ($prev == -* && ! $prev == '--dispvm') || (( ${COMP_CWORD} == 1 )) || \
          ($cmd == 'qvm-add-appvm' || $cmd == 'qvm-clone' || $cmd == 'qvm-ls') ]]; then
        COMPREPLY=($(compgen -W "$(_qvm_known_vms)" -- $cur)) # VM name
        return 0
    fi
}

_qvm_add_appvm() { _qvm_cmd 'qvm-add-appvm' -p --path -c --conf --force-root; }

_qvm_add_template()
{
    _qvm_cmd 'qvm-add-template' -p --path -c --conf --rpm --force-root
}

_qvm_backup()
{
    _qvm_cmd 'qvm-backup' -x --exclude --force-root -d --dest-vm -e \
        --encrypt --no-encrypt -E --enc-algo -H --hmac-algo -z \
        --compress -Z --compress-filter --debug
}

_qvm_backup_restore()
{
    _qvm_cmd 'qvm-backup-restore' --verify-only --skip-broken \
        --ignore-missing --skip-conflicting --rename-conflicting \
        --force-root --replace-template -x --exclude --skip-dom0-home \
        --ignore-username-mismatch -d --dest-vm -e --encrypted -z \
        --compressed --debug
}

# FIXME: Using qvm-block to attach to dom0 gives an unhelpful error message
_qvm_block()
{
    _qvm_cmd 'qvm-block' -l --list -A --attach-file -a --attach -d --detach \
        -f --frontend --ro --no-auto-detach --show-system-disks --force-root
}

_qvm_check() { _qvm_cmd 'qvm-check' -q --quiet; }

_qvm_clone()
{
    _qvm_cmd 'qvm-clone' -q --quiet -p --path --force-root -P --pool
}

# FIXME: No -h arg in copy-to-vm
# FIXME: Should the dom0 version take and ignore --without-progress?
_qvm_copy_to_vm() { _qvm_cmd 'qvm-copy-to-vm'; }
_qvm_copy_to_vm_vm() { _qvm_cmd 'qvm-copy-to-vm' --without-progress; }

# FIXME: Could do better with this command.
# (Ideally it would take args in any order - see issue 940)
_qvm_create_default_dvm()
{
    _qvm_cmd 'qvm-create-default-dvm' --default-template --used-template \
        --default-script
}

_qvm_create()
{
    _qvm_cmd 'qvm-create' -q --quiet -t --template -l --label -p --proxy \
        -P --pool -H --hvm --hvm-template -n --net -s --standalone -R \
        --root-move-from -r --root-copy-from -m --mem -c --vcpus \
        --offline-mode -i --internal --force-root
}

_qvm_firewall()
{
    _qvm_cmd 'qvm-firewall' -l --list -a --add -d --del -P --policy -i \
        --icmp -D --dns -Y --yum-proxy -r --reload -n --numeric --force-root
}

_qvm_grow_private() { _qvm_cmd 'qvm-grow-private'; }

_qvm_grow_root() { _qvm_cmd 'qvm-grow-root' --allow-start; }

_qvm_kill() { _qvm_cmd 'qvm-kill'; }

_qvm_ls()
{
    _qvm_cmd 'qvm-ls' -n --network -c --cpu -m --mem -d --disk -k \
        --kernel -i --ids -b --last-backup --raw-list
}

# FIXME: As for qvm-copy-to-vm
_qvm_move_to_vm() { _qvm_cmd 'qvm-move-to-vm'; }
_qvm_move_to_vm_vm() { _qvm_cmd 'qvm-move-to-vm' --without-progress; }

_qvm_pci()
{
    _qvm_cmd 'qvm-pci' -l --list -a --add -d --delete -C --add-class \
        --offline-mode
}

# FIXME" Would be nice if we could list all prefs available (--names) for completion
_qvm_prefs()
{
    _qvm_cmd 'qvm-prefs' -l --list -s --set -g -get --force-root \
        --offline-mode
}

_qvm_remove() { _qvm_cmd 'qvm-remove' -q --quiet --just-db --force-root; }

_qvm_revert_template_changes()
{
    _qvm_cmd 'qvm-revert-template-changes' --force
}

_qvm_run()
{
    _qvm_cmd 'qvm-run' -q --quiet -a --auto -u --user --tray --all \
         --exclude --pause --unpause -p --pass-io --localcmd --nogui \
        --filter-escape-chars --no-filter-escape-chars --no-color-output \
        --color-output
}

# FIXME: non dom0 qvm run has no -h argument
_qvm_run_vm() { _qvm_cmd 'qvm-run' --help --dispvm; }

_qvm_shutdown()
{
    _qvm_cmd 'qvm-shutdown' -q --quiet --force --wait --wait-time --all \
        --exclude
}

# FIXME: Help is incorrect: no [action] argument is taken.
# Would be nice to be able to list all possible services
_qvm_service()
{
    _qvm_cmd 'qvm-service' -l --list -e --enable -d --disable -D --default
}

_qvm_start()
{
    _qvm_cmd 'qvm-start' -q --quiet --tray --no-guid --drive --hddisk \
        --cdrom --install-windows-tools --dvm --custom-config \
        --skip-if-running --debug
}

# FIXME: No -h/--help
_qvm_sync_clock() { _qvm_cmd 'qvm-sync-clock' --verbose; }

# FIXME: No -h/--help arg in script. Should limit VM list to templates
_qvm_template_commit() { _qvm_cmd 'qvm-template-commit' --offline-mode; }

# FIXME: No -h/--help arg in script. Should limit VM list to templates
_qvm_trim_template() { _qvm_cmd 'qvm-trim-template'; }

# FIXME: allows to be run without -l/-a/-d
_qvm_usb()
{
    _qvm_cmd 'qvm-usb' -l --list -a --attach -d --detach --no-auto-detach \
        --force-root
}

# FIXME: qvm-open-in-vm should be able to take --help and --dispvm
_qvm_open_in_vm() { _qvm_cmd 'qvm-open-in-vm'; }

# FIXME: qvm-open-in-dvm should be able to take --help
_qvm_open_in_dvm() { COMPREPLY=( $(compgen -f -- $cur) ); }

__qvm_init_completion()
{
    # Register completion functions for all command we have
    local f
    for f in add-appvm add-template backup backup-restore block check clone \
             copy-to-vm create create-default-dvm firewall grow-private \
             grow-root kill ls move-to-vm open-in-vm open-in-dvm pci prefs \
             remove revert-template-changes run shutdown service start \
             sync-clock template-commit trim-template usb; do
        if [[ -x /usr/bin/qvm-$f ]]; then
            complete -F $(echo "_qvm_$f" | tr '-' '_') qvm-$f
        fi
    done

    if [[ ! -x /usr/bin/qvm-ls ]]; then
        # Not dom0: some commands have different args (at least for now)
        complete -F _qvm_run_vm qvm-run
        complete -F _qvm_copy_to_vm_vm qvm-copy-to-vm
        complete -F _qvm_move_to_vm_vm qvm-move-to-vm
    fi
}
__qvm_init_completion
