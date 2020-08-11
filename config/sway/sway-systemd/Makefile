PREFIX ?= /usr/local

install:
	test 0 -eq `id -u`
	install -m 755 sway-service.sh $(PREFIX)/bin/
	install -m 655 sway-systemd.desktop /usr/share/wayland-sessions/
