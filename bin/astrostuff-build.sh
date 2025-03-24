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


# File paths
PROJECT_DIR="/astrostuff"
WORK_DIR="/astrostuff-work"
SOURCE_DIR="${PROJECT_DIR}/src"
BUILD_DIR="${WORK_DIR}/build"
DEPLOY_DIR="${WORK_DIR}/deploy"
DIST_DIR="${PROJECT_DIR}/dist"

# Repositories: add other 3rd party drivers/libs here
REPOSITORIES=("indi"
              "indi-3rdparty/libplayerone"
              "indi-3rdparty/indi-playerone"
              "indi-3rdparty/indi-sx"
              "stellarsolver"
              "kstars"
              "phd2")

# Git URLs
GIT_URL_INDI="https://github.com/indilib/indi.git"
GIT_URL_INDI_3RDPARTY="https://github.com/indilib/indi-3rdparty.git"
GIT_URL_STELLARSOLVER="https://github.com/rlancaste/stellarsolver.git"
GIT_URL_KSTARS="https://invent.kde.org/education/kstars.git"
GIT_URL_PHD2="https://github.com/OpenPHDGuiding/phd2.git"

# Filters for relevant tags/branches
FILTER_INDI="grep -o 'v.*'"
FILTER_INDI_3RDPARTY="grep -o 'v.*'"
FILTER_STELLARSOLVER="grep -o '[0-9]*\.[0-9]*'"
FILTER_KSTARS="grep -o 'stable-.*' | grep -v 'stable-fake-success'"
FILTER_PHD2="grep -o 'v.*' | grep -v 'dev'"

JOBS=$(grep -c ^processor /proc/cpuinfo)

usage () {
  cat <<'EOF' | less -R
Usage: $(basename $0) [-CUXBIPH] <repositories>

  Options:
    -C (clone): shallow clone repositories
    -U (update): checkout most recent tag/branch, if different from local
    -X (clean): remove build target folder
    -B (build): build code from source
    -I (install): install binaries in system (required for dependencies)
    -P (package): build .deb package with compiled binaries
    -H (help): show this message

  Repositories/Drivers:
    indi
    indi-3rdparty/libplayerone
    indi-3rdparty/indi-playerone
    indi-3rdparty/indi-sx
    stellarsolver
    kstars
    phd2

  If no repository is provided the script will cycle through all repositories, in this order.
EOF
}

parse_repo_driver() {
  IFS="/" read -r repo driver <<< "$1"
}

git_setup() {
  parse_repo_driver $1

  HEADS_OR_TAGS="tags"
  # kstars uses branches instead of tags
  if [ "$repo" == "kstars" ]; then
    HEADS_OR_TAGS="heads"
  fi

  REPO=$(echo "$repo" | sed 's/-/_/g' | tr '[:lower:]' '[:upper:]')""
  GIT_URL="GIT_URL_$REPO"
  FILTER="FILTER_$REPO"

  # Get most recent tag/branch according to filter
  GIT_BRANCH=$(eval "git ls-remote --$HEADS_OR_TAGS --refs --sort='-v:refname' ${!GIT_URL} | ${!FILTER} | head -1")
}

git_branch () {
  # Create branch from tag
  if [ "$HEADS_OR_TAGS" == "tags" ]; then
    git fetch --depth 1 origin tag $GIT_BRANCH
    git switch -c $GIT_BRANCH $GIT_BRANCH
  fi
  # Checkout remote branch
  if [ "$HEADS_OR_TAGS" == "heads" ]; then
    git remote set-branches origin '*'
    git fetch --depth 1 origin $GIT_BRANCH
    git checkout $GIT_BRANCH
  fi
}

# Shallow clone repository
git_clone() {
  cd $SOURCE_DIR
  git_setup $1
  if [ ! -d "$repo" ]; then
    # Repo folder doesn't exist; clone.
    git clone --depth 1 --single-branch ${!GIT_URL} $repo
  else
    echo "Repository $repo already exists. Skipping clone."
  fi

}

git_update() {
  cd $SOURCE_DIR
  git_setup $1

  cd $repo
  LOCAL_BRANCH=$(eval "git for-each-ref --format='%(refname:short)' --sort='-v:refname'   refs/heads | ${!FILTER} | head -1")

  if [ "$LOCAL_BRANCH" != "$GIT_BRANCH" ]; then
    git_branch $repo
  fi
}

# Clear build folders
astro_clean () {
  rm -rf ${BUILD_DIR}/$1
}

# Build from source
astro_build () {
  export CFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
  export CXXFLAGS="-march=native -w -Wno-psabi -D_FILE_OFFSET_BITS=64"
  export CMAKE_INCLUDE_PATH="/usr/include;/usr/include/aarch64-linux-gnu"
  export CMAKE_LIBRARY_PATH="/usr/lib;/usr/lib/aarch64-linux-gnu"
  export CMAKE_PREFIX_PATH="/usr;/usr/lib/aarch64-linux-gnu;/usr/include/aarch64-linux-gnu"

  cd ${WORK_DIR}
  target="$1"

  mkdir -p ${BUILD_DIR}/${target}
  BUILD_CMD="cmake -B ${BUILD_DIR}/${target} ${SOURCE_DIR}/${target} -DCMAKE_BUILD_TYPE=Release"

# Modify Cmake and CXX flags as required.
  case "${target}" in
    "indi")
      BUILD_CMD="${BUILD_CMD} -DCMAKE_INSTALL_PREFIX=/usr"
      ;;
    "indi-3rdparty/libplayerone")
      BUILD_CMD="${BUILD_CMD} -DCMAKE_INSTALL_PREFIX=/usr"
      ;;
    "indi-3rdparty/indi-playerone")
      BUILD_CMD="${BUILD_CMD} \
                -DPLAYERONE_LIBRARIES=/usr/lib/aarch64-linux-gnu/libPlayerOneCamera.so \
                -DINDI_LIBRARIES=/usr/lib/aarch64-linux-gnu/libindidriver.so \
                -DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so"
      ;;
    "indi-3rdparty/indi-sx")
      BUILD_CMD="${BUILD_CMD} \
                -DUSB1_LIBRARY=/usr/lib/aarch64-linux-gnu/libusb-1.0.so \
                -DINDI_LIBRARIES=/usr/lib/aarch64-linux-gnu/libindidriver.so"
      ;;
    "stellarsolver")
      CXXFLAGS="$CXXFLAGS -I/usr/include/wcslib"
      BUILD_CMD="${BUILD_CMD} \
              -DGSL_LIBRARY=/usr/lib/aarch64-linux-gnu/libgsl.so \
              -DGSL_CBLAS_LIBRARY=/usr/lib/aarch64-linux-gnu/libgslcblas.so \
              -DWCSLIB_LIBRARIES=/usr/lib/aarch64-linux-gnu/libwcs.so \
              -DWCSLIB_INCLUDE_DIR=/usr/include"
      ;;
    "kstars")
      BUILD_CMD="${BUILD_CMD} \
                -DBUILD_TESTING=Off \
                -DX11_X11_LIB=/usr/lib/aarch64-linux-gnu/libX11.so \
                -DX11_INCLUDE_DIR=/usr/include/X11 \
                -DKF5KIO_LIBRARY=/usr/lib/aarch64-linux-gnu/libKF5KIO.so \
                -DKF5KIO_INCLUDE_DIR=/usr/include/KF5/KIO \
                -DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so"
      ;;
    "phd2")
      BUILD_CMD="${BUILD_CMD} \
                -DCURL_LIBRARY_RELEASE=/usr/lib/aarch64-linux-gnu/libcurl.so \
                -DCURL_INCLUDE_DIR=/usr/include \
                -DwxWidgets_ROOT_DIR=/usr \
                -DwxWidgets_LIB_DIR=/usr/lib/aarch64-linux-gnu \
                -DwxWidgets_INCLUDE_DIR=/usr/include/wx-3.2 \
                -DwxWidgets_CONFIG_EXECUTABLE=/usr/bin/wx-config \
                -DwxWidgets_CONFIGURATION_OPTIONS=\"--unicode\""
      ;;
  esac

  if [ ! -d "${SOURCE_DIR}/${repo}" ]; then
    git_clone $repo
    git_update $repo
  fi
    eval "$BUILD_CMD"
    cd ${BUILD_DIR}/${target}
    make -j $JOBS
    cd $PROJECT_DIR
}

# Install in default location (necessary because of dependencies)
astro_install () {
  parse_repo_driver $1
  if [ "${driver}" == "" ]; then
    package="${repo}"
  else
    package="${driver}"
  fi
  if [ -d "${BUILD_DIR}/$1" ]; then
    cd ${BUILD_DIR}/$1
    make install
    make install DESTDIR=${DEPLOY_DIR}/${package}
  fi
}

# Build .deb file
astro_package () {
  parse_repo_driver $1
  if [ "${driver}" == "" ]; then
    package="${repo}"
  else
    package="${driver}"
  fi

  if [ ! -d "${DEPLOY_DIR}/${package}" ]; then
    echo "No $package binaries available to package. Run astrostuff-build.sh -i first" && \
    exit 1
  fi

  git_setup $1
  version=$(echo "$GIT_BRANCH" | sed 's/[^0-9\.]//g')

  cd ${DEPLOY_DIR}/${package}

  if [ ! -d "${DEPLOY_DIR}/${package}/DEBIAN" ]; then
    mkdir ${DEPLOY_DIR}/${package}/DEBIAN
  fi

  cat <<EOF > ${DEPLOY_DIR}/${package}/DEBIAN/control
Package: astrostuff-${package}
Version: ${version}
Section: base
Priority: optional
Architecture: arm64
Maintainer: Nelson Sousa <nsousa@gmail.com>
Description: $package installation package for Raspberry Pi 64 bits running Debian Bookworm.
EOF

  cat <<EOF > ${DEPLOY_DIR}/${package}/DEBIAN/postinst
#!/bin/bash
if command -v ldconfig >/dev/null 2>&1; then
  ldconfig
fi
EOF

  chmod 755 ${DEPLOY_DIR}/${package}/DEBIAN/postinst
  dpkg-deb --build ${DEPLOY_DIR}/${package} ${DIST_DIR}/${package}_${version}_arm64.deb

}

while getopts 'CUBIPXH' opt; do
  case "$opt" in
    C) CLONE=1    ;;
    U) UPDATE=1   ;;
    X) CLEAN=1    ;;
    B) BUILD=1    ;;
    I) INSTALL=1  ;;
    P) PACKAGE=1  ;;
    H) usage      ;;
    *) echo "Unknown command." ;;
  esac
done
shift "$(($OPTIND -1))"

# Repositories were passed as arguments
if [ ! "$#" -eq 0 ]; then
  REPOSITORIES=("$@")
fi

for r in ${REPOSITORIES[@]}
do
  echo "Repository/Driver: $r"
  if [ ! -z $CLONE ]; then
    git_clone "$r"
  fi
  if [ ! -z $UPDATE ]; then
    git_update "$r"
  fi
  if [ ! -z $CLEAN ]; then
    astro_clean "$r"
  fi
  if [ ! -z $BUILD ]; then
    astro_build "$r"
  fi
  if [ ! -z $INSTALL ]; then
    astro_install "$r"
  fi
  if [ ! -z $PACKAGE ]; then
    astro_package "$r"
  fi
done

cd ${PROJECT_DIR}
