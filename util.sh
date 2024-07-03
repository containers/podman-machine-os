#!/bin/bash

CPU_ARCH=`lscpu --json | jq .lscpu.[0].data | tr -d '"'`

DISK_FLAVORS_W_SUFFIX=("applehv.raw" "hyperv.vhdx" "qemu.qcow2")
