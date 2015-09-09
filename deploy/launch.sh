#set -x
WORK_DIR=$COMPASS_DIR/work/deploy

mkdir -p $WORK_DIR/script

source ${COMPASS_DIR}/util/log.sh
source ${COMPASS_DIR}/deploy/deploy_parameter.sh
source $(process_default_para $*) || exit 1
source $(process_input_para $*) || exit 1
source ${COMPASS_DIR}/deploy/conf/${FLAVOR}.conf
source ${COMPASS_DIR}/deploy/conf/${TYPE}.conf
source ${COMPASS_DIR}/deploy/conf/base.conf
source ${COMPASS_DIR}/deploy/prepare.sh
source ${COMPASS_DIR}/deploy/network.sh
source ${COMPASS_DIR}/deploy/host_${TYPE}.sh
source ${COMPASS_DIR}/deploy/compass_vm.sh
source ${COMPASS_DIR}/deploy/deploy_host.sh

######################### main process
if false
then
if ! prepare_env;then
    echo "prepare_env failed"
    exit 1
fi

log_info "########## get host mac begin #############"
machines=`get_host_macs`
if [[ -z $machines ]];then
    log_error "get_host_macs failed"
    exit 1
fi

log_info "deploy host macs: $machines"
export machines

log_info "########## set up network begin #############"
if ! create_nets;then
    log_error "create_nets failed"
    exit 1
fi

if ! launch_compass;then
    log_error "launch_compass failed"
    exit 1
fi
else
# test code
export machines="'00:00:53:a3:c6:54','00:00:13:05:b3:55','00:00:80:eb:c8:8c','00:00:45:0d:ed:ac','00:00:11:2e:56:43'"
fi
if [[ ! -z $VIRT_NUMBER ]];then
    if ! launch_host_vms;then
        log_error "launch_host_vms failed"
        exit 1
    fi
fi
if ! deploy_host;then
    #tear_down_machines
    #tear_down_compass
    exit 1
else
    #tear_down_machines
    #tear_down_compass
    exit 0
fi
