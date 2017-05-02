settings
===

# common

settings that would be deployed across multiple systems
```
vim common
---
# matrix server for api access
MATRIX_API="https://domain.url"
# access token for the api
MATRIX_TOKEN="apitokenformatrix"
# room to report errors to
MATRIX_ROOM="!matrix:domain.url"
```

# local

machine settings will be loaded from a `settings/local` file

```
vim local
---
```

## conf.d

to disable rules for the system
```
monitor_disabled="iptables|journal"
```

## rules

| rule | var | description |
| ---- | --- | ----------- |
| journal | journal_ignore | ignore journal lines matching these values |
| procs | proc_names | process names to check for as running |
