#!/bin/bash
# Create symlinks for astrometry and logs

mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/indigo"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/indi"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/kstars"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/guide"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/focus"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/Logs/analyze"
mkdir -p "${ROOTFS_DIR}/home/${FIRST_USER_NAME}/astrometry"

rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.indi/logs
rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/logs
rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/guidelogs
rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/focuslogs
rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/analyze
rm -rf ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/astrometry

mkdir -p ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.indi
mkdir -p ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars

ln -s /home/${FIRST_USER_NAME}/Logs/indi ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.indi/logs
ln -s /home/${FIRST_USER_NAME}/Logs/kstars ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/logs
ln -s /home/${FIRST_USER_NAME}/Logs/guide ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/guidelogs
ln -s /home/${FIRST_USER_NAME}/Logs/focus ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/focuslogs
ln -s /home/${FIRST_USER_NAME}/Logs/analyze ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/analyze
ln -s /home/${FIRST_USER_NAME}/astrometry ${ROOTFS_DIR}/home/${FIRST_USER_NAME}/.local/share/kstars/astrometry
