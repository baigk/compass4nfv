
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
*********************************************************
