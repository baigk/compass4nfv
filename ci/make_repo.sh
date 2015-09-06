#!/bin/bash
set -ex

WORK_PATH=$(cd "$(dirname "$0")"; pwd)

function process_env()
{
    mkdir -p ${WORK_PATH}/work/repo/

    set +e
    sudo docker info
    if [[ $? != 0 ]]; then
        wget -qO- https://get.docker.com/ | sh
    else
        echo "docker is already installed!"
    fi
    set -e

cat <<EOF >${WORK_PATH}/work/repo/cp_repo.sh
#!/bin/bash
set -ex
cp /*ppa.tar.gz /result
EOF

    sudo apt-get install python-yaml -y
    sudo apt-get install python-cheetah -y
}

function make_repo()
{
    rm -f ${WORK_PATH}/work/repo/install_packages.sh
    rm -f ${WORK_PATH}/work/repo/Dockerfile

    TEMP=`getopt -o h -l os-tag:,openstack-tag:,tmpl:,default-package:,special-package:,ansible-dir: -n 'make_repo.sh' -- "$@"`

    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

    eval set -- "$TEMP"

    os_tag=""
    openstack_tag=""
    tmpl=""
    default_package=""
    special_package=""
    special_package_dir=""
    ansible_dir=""
    while :; do
        case "$1" in
            --os-tag) os_tag=$2; shift 2;;
            --openstack-tag) openstack_tag=$2; shift 2;;
            --tmpl) tmpl=$2; shift 2;;
            --default-package) default_package=$2; shift 2;;
            --special-package) special_package=$2; shift 2;;
            --special-package-dir) special_package_dir=$2; shift 2;;
            --ansible-dir) ansible_dir=$2; shift 2;;
            --) shift; break;;
            *) echo "Internal error!" ; exit 1 ;;
        esac
    done

    if [[ -z ${os_tag} || -z ${openstack_tag} || -z ${tmpl} || -z ${ansible_dir} ]]; then
        echo "parameter is wrong"
        exit 1
    fi

    if [[ ${os_tag} == "trusty" ]]; then
        arch=Debian
    fi

    if [[ ${os_tag} == "centos7" ]]; then
        arch=RedHat
    fi

    dockerfile=Dockerfile
    docker_tmpl=${WORK_PATH}/${os_tag}/${openstack_tag}/${dockerfile}".tmpl"
    docker_tag="${os_tag}/openstack-${openstack_tag}"

    python gen_ins_pkg_script.py ${ansible_dir} ${arch} ${tmpl} \
               ${docker_tmpl} "${default_package}" "${special_package}" "${special_package_dir}"

    if [[ -d ${WORK_PATH}/$arch ]]; then
        rm -rf ${WORK_PATH}/work/repo/$arch
        cp -rf ${WORK_PATH}/$arch ${WORK_PATH}/work/repo/
    fi

    if [[ -d ${WORK_PATH}/$os_tag ]]; then
        rm -rf ${WORK_PATH}/work/repo/$os_tag
        cp -rf ${WORK_PATH}/$os_tag ${WORK_PATH}/work/repo/centos7
    fi

    sudo docker build -t ${docker_tag} -f ${WORK_PATH}/work/repo/${dockerfile} ${WORK_PATH}/work/repo/

    sudo docker run -t -v ${WORK_PATH}/work/repo:/result ${docker_tag}

    image_id=$(sudo docker images|grep ${docker_tag}|awk '{print $3}')

    sudo docker rmi -f ${image_id}
}

function make_all_repo()
{
    make_repo --os-tag trusty --openstack-tag juno \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl Debian_juno.tmpl \
              --default-package "openssh-server" \
              --special-package "openvswitch-datapath-dkms openvswitch-switch"

    make_repo --os-tag trusty --openstack-tag kilo \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl Debian_kilo.tmpl \
              --default-package "openssh-server" \
              --special-package "openvswitch-datapath-dkms openvswitch-switch"

    make_repo --os-tag centos7 --openstack-tag juno \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl RedHat_juno.tmpl \
              --default-package "strace net-tools wget vim openssh-server dracut-config-rescue dracut-network" \
              --special-package ""

}

process_env

if [[ $# -eq 0 ]]; then
    make_all_repo
else
    make_repo $*
fi
