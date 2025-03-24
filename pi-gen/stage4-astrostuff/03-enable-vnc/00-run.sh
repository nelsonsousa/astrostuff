#!/bin/bash -e
# Enable VNC server

if ! [ -L "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/vncserver-x11-serviced.service" ]; then
	chroot  ${ROOTFS_DIR} ln -s /lib/systemd/system/vncserver-x11-serviced.service /etc/systemd/system/multi-user.target.wants/vncserver-x11-serviced.service
fi
