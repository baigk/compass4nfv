
# Compass4nfv Build Guide

Compass4nfv is an installer project based on open source project COMPASS, which provides automated deployment and management of OpenStack and other distributed systems.

This is a prject for run compass4nfv in OPNFV, including build OPNFV imaged-base installation ISO, deployment for OPNFV distributed system.

There are two files in this directory:

* **build.sh**: build imaged-base installation ISO for OPNFV.
* **deploy**: deploy OPNFV distributed system base the above ISO.

## Directory Tree

***********************************************
.
├── build
│   ├── arch
│   │   ├── Debian
│   │   │   └── make_openvswitch-switch.sh
│   │   └── RedHat
│   ├── build.conf
│   ├── gen_ins_pkg_script.py
│   ├── make_repo.sh
│   ├── os
│   │   ├── centos
│   │   │   ├── centos6
│   │   │   │   ├── base.repo
│   │   │   │   └── compass
│   │   │   │       └── Dockerfile.tmpl
│   │   │   ├── centos7
│   │   │   │   └── juno
│   │   │   │       └── Dockerfile.tmpl
│   │   │   └── comps.xml
│   │   └── ubuntu
│   │       └── trusty
│   │           ├── juno
│   │           │   └── Dockerfile.tmpl
│   │           └── kilo
│   │               └── Dockerfile.tmpl
│   └── templates
│       ├── compass_core.tmpl
│       ├── Debian_juno.tmpl
│       ├── Debian_kilo.tmpl
│       └── RedHat_juno.tmpl
├── build.sh
├── ci.md
├── deploy
│   ├── deploy_parameter.sh
│   └── launch.sh
├── deploy.sh
└── util
    ├── ks.cfg
    └── log
***********************************************
