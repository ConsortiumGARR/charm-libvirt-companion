#!/bin/bash
set -ex

source charms.reactive.sh


@when_not 'charm-libvirt-companion.installed'
function install_charm-libvirt-companion() {
    # Do your setup here.
    #
    # If your charm has other dependencies before it can install,
    # add those as @when clauses above, or as additional @when
    # decorated handlers below.
    #
    # See the following for information about reactive charms:
    #
    #  * https://jujucharms.com/docs/devel/developer-getting-started
    #  * https://github.com/juju-solutions/layer-basic#overview
    #
    charms.reactive set_state 'charm-libvirt-companion.installed'
}

do_blkdeviotuning() {
    # tune the block devices of all domains except the ones to be excluded, specified in the configuration option
    ALLDOMAINS="$( virsh list | tail -n+3 | awk '{print $2}' | grep -v '^$' )"
    UUIDS="$( echo "$ALLDOMAINS" | while read instance; do echo -n $instance " "; virsh dumpxml $instance | grep '<uuid>' | sed 's_<uuid>\(.*\)</uuid>_\1_g' | tr -d ' '; done )"
    EXCLUDED_INSTANCES="$( config-get excluded-instances )"
    if [ -n "$EXCLUDED_INSTANCES" ]; then
        EXCLUDED_DOMAINS_GREP="$( config-get excluded-instances | sed -e 's/^/grep -v -e /g' -e 's/\ / -e /g' )"
        DOMAINS="$( echo "$UUIDS" | $EXCLUDED_DOMAINS_GREP | awk '{print $1}' )"
    else
        DOMAINS="$( echo "$UUIDS" | awk '{print $1}' )"
    fi
    echo "$DOMAINS" | while read instance; do
        juju-log "instance: $instance"
        DEVICES="$( virsh domblklist $instance | tail -n+3 | grep -v '^$' | awk '{print $1}')"
        echo "$DEVICES" | while read device; do
            CURRENT_READ_IOPS="$(  virsh blkdeviotune $instance $device | grep 'read_iops_sec\>'  | awk -F: '{print $2}' | sed s'/ //g' )"
            CURRENT_WRITE_IOPS="$( virsh blkdeviotune $instance $device | grep 'write_iops_sec\>' | awk -F: '{print $2}' | sed s'/ //g' )"
            DESIRED_READ_IOPS="$( config-get read-iops-sec )"
            DESIRED_WRITE_IOPS="$( config-get write-iops-sec )"
            juju-log "cr: $CURRENT_READ_IOPS cw: $CURRENT_WRITE_IOPS dr: $DESIRED_READ_IOPS dw: $DESIRED_WRITE_IOPS"
            if [ "$CURRENT_READ_IOPS" != "$DESIRED_READ_IOPS" ] || [ "$CURRENT_WRITE_IOPS" != "$DESIRED_WRITE_IOPS" ]; then
                juju-log "virsh blkdeviotune $instance $device --read-iops-sec $DESIRED_READ_IOPS --write-iops-sec $DESIRED_WRITE_IOPS"
                virsh blkdeviotune $instance $device --read-iops-sec $DESIRED_READ_IOPS --write-iops-sec $DESIRED_WRITE_IOPS
            fi
        done
    done
}

@hook 'start' 
do_start() {
    status-set maintenance "IOPS tuning"
    do_blkdeviotuning
    status-set active
}

@hook 'update-status'
do_update() {
    status-set maintenance "IOPS tuning"
    do_blkdeviotuning
    status-set active
}

@hook 'config-changed'
do_config_changed() {
    status-set maintenance "IOPS tuning"
    do_blkdeviotuning
    status-set active
}

reactive_handler_main
