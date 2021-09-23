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


reactive_handler_main
