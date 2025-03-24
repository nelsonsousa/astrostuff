#!/bin/bash
# This file is part of project Astrostuff.
#
# Copyright (C) 2025 Nelson Sousa (nsousa@gmail.com)
#
# Astrostuff is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Astrostuff is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with Astrostuff.  If not, see <https://www.gnu.org/licenses/>.
set -e

source /astrostuff/astrostuff.env

PROJECT_DIR="/astrostuff"
WORK_DIR="/astrostuff-work"
DEB_DIR="${PROJECT_DIR}/dist"
IMG_DIR="${PROJECT_DIR}/image"
CFG_DIR="${PROJECT_DIR}/pi-gen"
BACKUP_DIR="${PROJECT_DIR}/backup"
PIGEN_DIR="${WORK_DIR}/pi-gen"
PIGEN_CUSTOM_STAGE="${PIGEN_DIR}/stage4-astrostuff"


# Clone or update pi-gen repository
if [ "${ASTROSTUFF_ARCH}" = "arm64" ]; then
  PIGEN_GIT_BRANCH="arm64"
else
  PIGEN_GIT_BRANCH="master"
fi

if [ ! -d "${PIGEN_DIR}" ]; then
  cd $WORK_DIR
  git clone --depth=1 --branch ${PIGEN_GIT_BRANCH} https://github.com/RPi-Distro/pi-gen.git
else
  cd $PIGEN_DIR
  git switch --discard-changes ${PIGEN_GIT_BRANCH}
fi

# Copy pi-gen files
cp -a ${CFG_DIR}/* ${PIGEN_DIR}


# Copy existing backup files (if no backup exists, copy from samples)
mkdir -p ${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/system
if [ -d "${BACKUP_DIR}/system" ]; then
  cp -a ${BACKUP_DIR}/system ${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/
elif [ -d "${SAMPLES_DIR}/system" ]; then
  find "${SAMPLES_DIR}/system" -type f | while read -r file; do
    path="${file#${SAMPLES_DIR}/system}"
    target="${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/system/$path"
    mkdir -p "$(dirname "$target")"
    envsubst < "$file" > "$target"
  done
fi

mkdir -p ${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/user
if [ -d "${BACKUP_DIR}/user" ]; then
  cp -a ${BACKUP_DIR}/user ${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/
elif [ -d "${SAMPLES_DIR}/user" ]; then
  find "${SAMPLES_DIR}/user" -type f | while read -r file; do
    path="${file#${SAMPLES_DIR}/system}"
    target="${PIGEN_CUSTOM_STAGE}/04-add-astrostuff-files/files/user/$path"
    mkdir -p "$(dirname "$target")"
    envsubst < "$file" > "$target"
  done
fi

# Copy .deb files
mkdir -p ${PIGEN_CUSTOM_STAGE}/06-install-deb-files/files/dist && \
if [ -d "${DEB_DIR}" ]; then
  cp -a ${DEB_DIR}/*.deb ${PIGEN_CUSTOM_STAGE}/06-install-deb-files/files/dist
fi

# pi-gen config file
cat > ${PIGEN_DIR}/config <<EOF
IMG_NAME="${ASTROSTUFF_IMAGE_NAME}"
BASEOS_RELEASE="${ASTROSTUFF_RELEASE}"
ARCH="${ASTROSTUFF_ARCH}"
DEPLOY_DIR="${ASTROSTUFF_IMAGE_DEPLOY_DIR}"

TARGET_HOSTNAME="${ASTROSTUFF_HOSTNAME}"
FIRST_USER_NAME="${ASTROSTUFF_USER}"
FIRST_USER_PASS="${ASTROSTUFF_PASSWORD}"
PUBKEY_SSH_FIRST_USER="${ASTROSTUFF_SSH_PUB_KEY}"
ENABLE_SSH=1
PUBKEY_ONLY_SSH=1
WPA_COUNTRY="${ASTROSTUFF_WPA_COUNTRY}"

LOCALE_DEFAULT="${ASTROSTUFF_LOCALE}"
KEYBOARD_KEYMAP="${ASTROSTUFF_KEYBOARD_KEYMAP}"
KEYBOARD_LAYOUT="${ASTROSTUFF_KEYBOARD_LAYOUT}"
TIMEZONE_DEFAULT="${ASTROSTUFF_TIMEZONE}"

DISABLE_FIRST_BOOT_USER_RENAME=1
EOF


# Run pi-gen.
cd ${PIGEN_DIR}
./build.sh
