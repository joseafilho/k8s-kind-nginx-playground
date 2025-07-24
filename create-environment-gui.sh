#!/bin/bash
vagrant halt
vagrant destroy -f
sleep 2
WITH_GUI=1 INSTALL_BROWSER=1 vagrant up
sleep 2
vagrant halt
sleep 2
VM_NAME=$(VBoxManage list vms | grep "kind-nginx" | awk -F\" '{print $2}')
VBoxManage modifyvm $VM_NAME --memory 4096 --cpus 4
SETUP_KIND_K8S=1 vagrant reload --provision