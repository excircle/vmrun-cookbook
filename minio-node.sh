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

function stop_vm {
    local vm_name="$1"
    local vmx_path="${BASE_VM_DIR}/${vm_name}.vmwarevm/${vm_name}.vmx"

    vmrun -T fusion stop "$vmx_path" soft
    if [ $? -eq 0 ]; then
        echo "Stopped $vm successfully..."
    else
        echo "$vm halt has failed!"
        exit 1
    fi
    
}

function boot_vm {
    local vm_name="$1"
    local vmx_path="${BASE_VM_DIR}/${vm_name}.vmwarevm/${vm_name}.vmx"

    vmrun -T fusion start "$vmx_path"
    if [ $? -eq 0 ]; then
        echo "Started $vm successfully..."
    else
        echo "$vm start has failed!"
        exit 1
    fi
}

function backup_vm {
    for vm in $VIRTUAL_MACHINES_NAMES; do
        local vmx_path="${BASE_VM_DIR}/${vm}.vmwarevm/${vm}.vmx"
        local snapshot_name="$1"
        local timestamp=$(date '+%Y-%m-%d')
        local snapshot="${snapshot_name}-${timestamp}"

        # Stop Machine
        echo "Stopping virtual machine: $vm"
        stop_vm $vm

        # Snapshot Machine        
        vmrun -T fusion snapshot "$vmx_path" $snapshot
        if [ $? -eq 0 ]; then
            echo "$vm snapshot '$snapshot' taken successfully..."
        else
            echo "$vm snapshot '$snapshot' has failed!"
            exit 1
        fi

        # Start Machine
        start_vm $vm
    done   
}

function format_vm {
    for vm in $VIRTUAL_MACHINES_NAMES; do
        local vmx_path="${BASE_VM_DIR}/${vm}.vmwarevm/${vm}.vmx"
        local snapshot_name="$1"

        # Snapshot Machine        
        vmrun -T fusion deleteSnapshot "$vmx_path" $snapshot_name
        if [ $? -eq 0 ]; then
            echo "$vm snapshot '$snapshot_name' deleted successfully..."
        else
            echo "$vm snapshot deletion of '$snapshot_name' has failed!"
            exit 1
        fi
    done   
}

function restore_vm {
    for vm in $VIRTUAL_MACHINES_NAMES; do
        local vmx_path="${BASE_VM_DIR}/${vm}.vmwarevm/${vm}.vmx"
        local snapshot_name="$1"

        # Stop Machine
        echo "Stopping virtual machine: $vm"
        stop_vm $vm

        # Snapshot Machine        
        vmrun -T fusion revertToSnapshot "$vmx_path" $snapshot_name
        if [ $? -eq 0 ]; then
            echo "$vm had snapshot '$snapshot_name' restored succesfully..."
        else
            echo "$vm failed to restore '$snapshot_name'!"
            exit 1
        fi

        # Start Machine
        start_vm $vm
    done   
}

function list_snapshots {
    echo -e "[ Status: $(date) ]\n";
    for vm in $VIRTUAL_MACHINES_NAMES; do
        local vmx_path="${BASE_VM_DIR}/${vm}.vmwarevm/${vm}.vmx"
        
        # List VM snapshots
        echo "Listing snapshots for: $vm"
        vmrun -T fusion listSnapshots "$vmx_path"
    done   
}

#################
### MAIN CODE ###
#################

function main {

    local action=$1
    local arg=$2

    case $action in
      start)
        start_vm
        ;;
      status)
        start_vm
        ;;
      restore)
        restore_vm $2
        ;;
      stop)
        stop_vm
        ;;
      format)
        format_vm $2
        ;;
      list)
        list_snapshots
        ;;
      backup)
        backup_vm $2
        ;;
      *)
        echo '''
        Usage: minio-node.sh [start|status|restore|stop|format|list|backup]
        '''
        ;;
    esac
}

main $1 $2