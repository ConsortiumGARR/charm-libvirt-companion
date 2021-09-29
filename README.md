# Overview

This charm is intended as a subordinate charm to the nova-compute charm and its
purpose is to set/override libvirt specific parameters such as IOPS per second.

To achieve this goal, the charm relies on libvirt specific commands such as
```
virsh blkdeviotune
```

# Usage

Example usage:

```
juju deploy libvirt-companion
juju config libvirt-companion read-iops-sec=200 write-iops-sec=100
juju config libvirt-companion excluded-instances "ae52af9a-5799-24fe-0501-f6ec802ee889 bcb8f4ec-6337-4b69-a408-2498578e78bf"
juju add-relation libvirt-companion nova-compute
```

To remove it:

```
juju config libvirt-companion read-iops-sec=0 write-iops-sec=0
juju remove-application libvirt-companion
```


# Contact Information

Distributed Computing and Storage department at GARR, the Italian National Research and Education Network.

E-mail address: cloud-support@garr.it
Website: https://cloud.garr.it

