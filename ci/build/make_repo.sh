#!/bin/bash
set -ex

WORK_PATH=$(cd "$(dirname "$0")"; pwd)

function process_env()
{
    mkdir -p ${WORK_PATH}/work/repo/ ${WORK_PATH}/work/repo/pip

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
cp /*.tar.gz /result
EOF

    sudo apt-get install python-yaml -y
    sudo apt-get install python-cheetah -y
}

function make_repo()
{
    rm -f ${WORK_PATH}/work/repo/install_packages.sh
    rm -f ${WORK_PATH}/work/repo/Dockerfile

    TEMP=`getopt -o h -l os-tag:,package-tag:,tmpl:,default-package:,special-package:,ansible-dir: -n 'make_repo.sh' -- "$@"`

    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

    eval set -- "$TEMP"

    os_tag=""
    package_tag=""
    tmpl=""
    default_package=""
    special_package=""
    special_package_dir=""
    ansible_dir=""
    while :; do
        case "$1" in
            --os-tag) os_tag=$2; shift 2;;
            --package-tag) package_tag=$2; shift 2;;
            --tmpl) tmpl=$2; shift 2;;
            --default-package) default_package=$2; shift 2;;
            --special-package) special_package=$2; shift 2;;
            --special-package-dir) special_package_dir=$2; shift 2;;
            --ansible-dir) ansible_dir=$2; shift 2;;
            --) shift; break;;
            *) echo "Internal error!" ; exit 1 ;;
        esac
    done

    if [[ ! -z ${package_tag} && ${package_tag} == "pip" ]]; then
        make_pip_repo
        return
    fi

    if [[ -z ${os_tag} || -z ${tmpl} || -z ${package_tag} ]]; then
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
    docker_tmpl=${WORK_PATH}/${os_tag}/${package_tag}/${dockerfile}".tmpl"
    docker_tag="${os_tag}/${package_tag}"

    python gen_ins_pkg_script.py "${ansible_dir}" "${arch}" "${WORK_PATH}/templates/${tmpl}" \
               "${docker_tmpl}" "${default_package}" "${special_package}" "${special_package_dir}"

    if [[ -n $arch && -d ${WORK_PATH}/$arch ]]; then
        rm -rf ${WORK_PATH}/work/repo/$arch
        cp -rf ${WORK_PATH}/$arch ${WORK_PATH}/work/repo/
    fi

    if [[ -n $os_tag && -d ${WORK_PATH}/$os_tag ]]; then
        rm -rf ${WORK_PATH}/work/repo/$os_tag
        cp -rf ${WORK_PATH}/$os_tag ${WORK_PATH}/work/repo
    fi

    if [[ -f ${WORK_PATH}/$os_tag/base.repo ]]; then
        cp ${WORK_PATH}/$os_tag/base.repo ${WORK_PATH}/work/repo/
    fi

    sudo docker build -t ${docker_tag} -f ${WORK_PATH}/work/repo/${dockerfile} ${WORK_PATH}/work/repo/

    sudo docker run -t -v ${WORK_PATH}/work/repo:/result ${docker_tag}

    image_id=$(sudo docker images|grep ${docker_tag}|awk '{print $3}')

    sudo docker rmi -f ${image_id}
}

function make_pip_repo()
{
    source $WORK_PATH/build.conf

    if [[ $PIP_CONF == "" ]]; then
        return
    fi

    for i in $PIP_CONF; do
        curl --connect-timeout 10 -o $WORK_PATH/work/repo/pip/`basename $i` $i
    done

    cd $WORK_PATH/work/repo; tar -zcvf pip.tar.gz ./pip; cd -
}

function make_all_repo()
{
    make_pip_repo

    make_repo --os-tag centos6 --package-tag compass \
              --tmpl compass_core.tmpl \
              --default-package "epel-release python-yaml python-jinja2 python-paramiko"

    make_repo --os-tag trusty --package-tag juno \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl Debian_juno.tmpl \
              --default-package "openssh-server" \
              --special-package "openvswitch-datapath-dkms openvswitch-switch"

    make_repo --os-tag trusty --package-tag kilo \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl Debian_kilo.tmpl \
              --default-package "openssh-server" \
              --special-package "openvswitch-datapath-dkms openvswitch-switch"

    make_repo --os-tag centos7 --package-tag juno \
              --ansible-dir $WORK_PATH/../deploy/adapters/ansible \
              --tmpl RedHat_juno.tmpl \
              --default-package "strace net-tools wget vim openssh-server dracut-config-rescue dracut-network" \
              --special-package ""
}

function main()
{
    process_env

    if [[ $# -eq 0 ]]; then
        make_all_repo
    else
        make_repo $*
    fi
}

main $*
