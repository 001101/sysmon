system-monitor
===

system monitoring assistant to get notified of system issues without manual intervention

# install

running as root
```
cd /opt
git clone https://github.com/epiphyte/system-monitor
cd system-monitor
make install
```

# updating

due to the bootstrap.sh script firing first, new rules will be automatically deployed, only settings need to be pushed

# configuration

## conf.d

each shell script (".sh") in this folder will be run, to add a new rule

```
vim conf.d/newrule.sh
---
#!/bin/bash
source $1
# do stuff, sourcing ^ will load core, common, and local configs
```

```
chmod u+x conf.d/newrule.sh
```

## settings

machine and deployment specific configurations can be set using

```
# shared
vim settings/common
# local to machine
vim settings/local
```

review the [readme](settings/README.md) for more information on the values within these files

## disabling configurations

all scripts in `conf.d` that end in `*.sh` are executed unless the local config sets
```
monitor_disabled="name|name2"
```

will grep match the basename of the conf.d file name
