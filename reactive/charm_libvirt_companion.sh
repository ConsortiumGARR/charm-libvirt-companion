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
    UUIDS="$( echo "$ALLDOMAINS" | | while read instance; do echo -n $instance " "; virsh dumpxml $instance | grep '<uuid>' | sed 's_<uuid>\(.*\)</uuid>_\1_g' | tr -d ' '; done )"
    EXCLUDED_DOMAINS_GREP="$( config-get excluded_instances | sed -e 's/^/grep -v -e /g' -e 's/\ / -e /g')"
    DOMAINS="$( echo "$UUIDS" | $EXCLUDED_DOMAINS_GREP | awk '{print $1}' )"
    echo "$DOMAINS" | while read instance; do
        juju-log "instance: $instance"
        DEVICES="$( virsh domblklist $instance | tail -n+3 | grep -v '^$' | awk '{print $1}')"
	echo "$DEVICES" | while read device; do
	    echo virsh blkdeviotune $instance $device --read-iops-sec $(config-get read_iops_sec) --write-iops-sec $(config-get write_iops_sec)
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
