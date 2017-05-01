INSTALL=/opt/system-monitor/
SETTINGS=$(INSTALL)settings/
.PHONY: install

install:
	systemctl enable $(INSTALL)service/system-monitor.timer
	ln -s $(INSTALL)service/system-monitor.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl start system-monitor.timer
	touch $(SETTINGS)local
	touch $(SETTINGS)common
	chmod 666 $(SETTINGS)*
