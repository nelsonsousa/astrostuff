#!/bin/bash
# Install dist/*.deb if they exist
# /lib/firmware/meade-deepskyimager.hex has a conflict betwen
# indi-3rd party and indigo. Diverting so it won't stand in the way.
if [ -d "files/dist" ]; then
    cp -a files/dist "${ROOTFS_DIR}/home/${FIRST_USER_NAME}"
    on_chroot << EOF
      SUDO_USER="${FIRST_USER_NAME}" chown -R 1000:1000 /home/${FIRST_USER_NAME}/dist/
    	SUDO_USER="${FIRST_USER_NAME}" dpkg -i --force-overwrite /home/${FIRST_USER_NAME}/dist/*.deb
EOF
fi
