#!/bin/bash
# Copy backup or sample files into the image.
if [ -d "files/system" ]; then
    cp -a files/system/* "${ROOTFS_DIR}/"
fi

if [ -d "files/user" ]; then
    cp -a files/user/* "${ROOTFS_DIR}/home/${FIRST_USER_NAME}"
    cp -a files/user/.* "${ROOTFS_DIR}/home/${FIRST_USER_NAME}"
fi

chroot ${ROOTFS_DIR} chown -R 1000:1000 /home/${FIRST_USER_NAME}
