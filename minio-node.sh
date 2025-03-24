#!/bin/bash

#################
### VARIABLES ###
#################

VIRTUAL_MACHINES_NAMES="minio1 minio2 minio3 minio4"
BASE_VM_DIR="/Users/akalaj/Virtual Machines.localized"

#################
### FUNCTIONS ###
#################

# Function to check if a VM is running.
function check_vm_status {
    local vm_name="$1"
    local vmx_path="${BASE_VM_DIR}/${vm_name}.vmwarevm/${vm_name}.vmx"
    
    if vmrun list | grep -q "$vmx_path"; then
        echo "on"
    else
        echo "off"
    fi
}

# Function to start the VM if it's not running.
function start_vm {
    for vm in $VIRTUAL_MACHINES_NAMES; do
        local vmx_path="${BASE_VM_DIR}/${vm}.vmwarevm/${vm}.vmx"
        
        # Check the VM status
        VM_STATUS=$(check_vm_status "$vm")
        
        if [ "$VM_STATUS" == "off" ]; then
            echo "Starting $vm..."
            vmrun -T fusion start "$vmx_path" nogui
        elif [ "$VM_STATUS" == "on" ]; then
            echo "$vm is already powered on..."
        fi
    done
}

#################
### MAIN CODE ###
#################

function main {

    action=$1

    case $action in
      start)
        start_vm
        ;;
      restore)
        restore_vm
        ;;
      backup)
        backup_vm
        ;;
      *)
        echo '''
        Usage: minio-node.sh [start|restore|backup]
        '''
        ;;
    esac
}