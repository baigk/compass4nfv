#!/bin/bash
set -ex

SCRIPT_DIR=`cd ${BASH_SOURCE[0]%/*};pwd`
COMPASS_DIR=${SCRIPT_DIR}
WORK_DIR=$SCRIPT_DIR/work/building

source $SCRIPT_DIR/build/build.conf

mkdir -p $WORK_DIR $WORK_DIR/cache

cd $WORK_DIR

function prepare_env()
{
    set +e
    for i in createrepo genisoimage curl; do
        sudo $i --version
        if [[ $? -ne 0 ]]; then
            sudo apt-get install $i -y
        fi
    done
    set -e
}

function download_git()
{
    if [[ -d $WORK_DIR/cache/${1%.*} ]]; then
       if [[  -d $WORK_DIR/cache/${1%.*}/.git ]]; then

            cd $WORK_DIR/cache/${1%.*}

            git fetch origin master
            git checkout origin/master

            cd -

            return
        fi

        sudo rm -rf $WORK_DIR/cache/${1%.*}
    fi

    git clone $2 $WORK_DIR/cache/`basename $i | sed 's/.git//g'`
}

function download_url()
{
    sudo rm -f $WORK_DIR/cache/$1.md5
    curl --connect-timeout 10 -o $WORK_DIR/cache/$1.md5 $2.md5
    if [[ -f $WORK_DIR/cache/$1 ]]; then
        local_md5=`md5sum $WORK_DIR/cache/$1 | cut -d ' ' -f 1`
        repo_md5=`cat $WORK_DIR/cache/$1.md5 | cut -d ' ' -f 1`
        if [[ $local_md5 == $repo_md5 ]]; then
            return
        fi
    fi

    curl --connect-timeout 10 -o $WORK_DIR/cache/$1 $2
}

function download_local()
{
    cp $2 $WORK_DIR/cache/ -rf
}

function download_packages()
{
     for i in $CENTOS_BASE $COMPASS_CORE $COMPASS_WEB $COMPASS_INSTALL $TRUSTY_JUNO_PPA $UBUNTU_ISO \
              $CENTOS_ISO $CENTOS7_JUNO_PPA $LOADERS $CIRROS $APP_PACKAGE $COMPASS_PKG $PIP_REPO; do
         name=`basename $i`
         if [[ ${name##*.} == "git" ]]; then
             download_git  $name $i
         elif [[ "https?" =~ ${i%%:*} ]]; then
             download_url  $name $i
         else
             download_local $name $i
         fi
     done

     git fetch
     git checkout origin/master -- $COMPASS_DIR/deploy/adapters
}

function copy_file()
{
    new=$1

    # main process
    sudo mkdir -p $new/repos $new/compass $new/bootstrap $new/pip $new/guestimg $new/app_packages

    sudo cp -rf $SCRIPT_DIR/util/ks.cfg $new/isolinux/ks.cfg

    sudo rm -rf $new/.rr_moved

    for i in $TRUSTY_JUNO_PPA $UBUNTU_ISO $CENTOS_ISO $CENTOS7_JUNO_PPA; do
        sudo cp $WORK_DIR/cache/`basename $i` $new/repos/ -rf
    done

    sudo cp $WORK_DIR/cache/`basename $LOADERS` $new/ -rf || exit 1
    sudo cp $WORK_DIR/cache/`basename $CIRROS` $new/guestimg/ -rf || exit 1
    sudo cp $WORK_DIR/cache/`basename $APP_PACKAGE` $new/app_packages/ -rf || exit 1

    for i in $COMPASS_CORE $COMPASS_INSTALL $COMPASS_WEB; do
        sudo cp $WORK_DIR/cache/`basename $i | sed 's/.git//g'` $new/compass/ -rf
    done

    sudo cp $COMPASS_DIR/deploy/adapters $new/compass/compass-adapters -rf

    sudo tar -zxvf $WORK_DIR/cache/pip.tar.gz -C $new/

    find $new/compass -name ".git" |xargs sudo rm -rf
}

function rebuild_ppa()
{
    name=`basename $COMPASS_PKG`
    sudo rm -rf ${name%%.*} $name
    sudo cp $WORK_DIR/cache/$name $WORK_DIR
    sudo cp $SCRIPT_DIR/build/os/centos/comps.xml $WORK_DIR
    sudo tar -zxvf $name
    sudo cp ${name%%.*}/*.rpm $1/Packages -f
    sudo rm -rf $1/repodata/*
    sudo createrepo -g $WORK_DIR/comps.xml $1
}

function make_iso()
{
    download_packages
    name=`basename $CENTOS_BASE`
    sudo cp  $WORK_DIR/cache/$name ./ -f
    # mount base iso
    sudo mkdir -p base new
    sudo mount -o loop $name base
    cd base;find .|sudo cpio -pd ../new ;cd -
    sudo umount base
    sudo chmod 755 ./new -R

    copy_file new
    rebuild_ppa new

    sudo mkisofs -quiet -r -J -R -b isolinux/isolinux.bin \
                 -no-emul-boot -boot-load-size 4 \
                 -boot-info-table -hide-rr-moved \
                 -x "lost+found:" \
                 -o compass.iso new/

    md5sum compass.iso > compass.iso.md5

    # delete tmp file
    sudo rm -rf new base $name
}

function copy_iso()
{
   if [[ $# -eq 0 ]]; then
       return
   fi

   TEMP=`getopt -o d:f: --long iso-dir:,iso-name: -n 'build.sh' -- "$@"`

   if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

   eval set -- "$TEMP"

   dir=""
   file=""

   while :; do
       case "$1" in
           -d|--iso-dir) dir=$2; shift 2;;
           -f|--iso-name) file=$2; shift 2;;
           --) shift; break;;
           *) echo "Internal error!" ; exit 1 ;;
       esac
   done

   if [[ $dir == "" ]]; then
       dir=$WORK_DIR
   fi

   if [[ $file == "" ]]; then
       file="compass.iso"
   fi

   if [[ "$dir/$file" == "$WORK_DIR/compass.iso" ]]; then
      return
   fi

   cp $WORK_DIR/compass.iso $dir/$file -f
}

prepare_env
make_iso
copy_iso $*
