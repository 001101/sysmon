system-monitor
===

system monitoring assistant to get notified of system issues without manual intervention

make sure to enable the epiphyte [repository](https://github.com/epiphyte/servers) package to get all required dependencies before proceeding

```
pacman -S sysmon
```

* make sure smirc is configure

enable the service
```
systemctl enable sysmon
systemctl start sysmon
```
