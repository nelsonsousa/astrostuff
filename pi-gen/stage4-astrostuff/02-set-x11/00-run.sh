#!/bin/bash -e
# Switch back from Wayland to X11.
on_chroot << EOF
  	SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_wayland W1
    SUDO_USER="${FIRST_USER_NAME}" apt remove labwc-prompt
EOF

#
# rm labwc-prompt.desktop
