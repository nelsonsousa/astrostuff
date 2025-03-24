#!/bin/bash
# Add indigo repository to apt sources
on_chroot << EOF
  SUDO_USER="${FIRST_USER_NAME}" echo "deb [trusted=yes] https://indigo-astronomy.github.io/indigo_ppa/ppa indigo main" > /etc/apt/sources.list.d/indigo.list
  apt update
EOF
