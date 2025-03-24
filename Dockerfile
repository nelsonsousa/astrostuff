FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Packages required to add Raspberry Pi apt repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends gnupg curl ca-certificates lsb-release

# Raspberry Pi repository
RUN echo "deb http://archive.raspberrypi.org/debian $(lsb_release -cs) main" > /etc/apt/sources.list.d/raspi.list && \
    curl -fsSL https://archive.raspberrypi.org/debian/raspberrypi.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/raspberrypi.gpg

# Install all necessary dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends\
            arch-test bc breeze-icon-theme build-essential cmake debootstrap\
            dosfstools extra-cmake-modules ffmpeg file gettext git kinit-dev\
            kmod less libarchive-tools libavcodec-dev libavdevice-dev libavformat-dev\
            libavutil-dev libboost-dev libboost-regex-dev libcfitsio-dev \
            libcurl4-gnutls-dev libczmq-dev libdc1394-dev libeigen3-dev libev-dev \
            libfftw3-dev libftdi-dev libftdi1-dev libgphoto2-dev libgps-dev \
            libgsl-dev libgtest-dev libjpeg-dev libkf5crash-dev libkf5doctools-dev \
            libkf5kio-dev libkf5newstuff-dev libkf5notifications-dev \
            libkf5notifyconfig-dev libkf5plotting-dev libkf5xmlgui-dev liblimesuite-dev \
            libnova-dev libopencv-dev libopencv-highgui-dev libopencv-imgproc-dev \
            libqt5datavisualization5-dev libqt5svg5-dev libqt5websockets5-dev libraw-dev \
            librtlsdr-dev libsecret-1-dev libswscale-dev libtiff-dev libupsclient-dev \
            libusb-1.0-0-dev libwxgtk3.2-dev libx11-dev libzmq3-dev nano parted pigz \
            pkg-config qemu-user-static qml-module-qtquick-controls qt5keychain-dev \
            qtdeclarative5-dev quilt rsync udev wcslib-dev wx-common wx3.2-i18n \
            xplanet xplanet-images xxd zerofree zip zlib1g-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /astrostuff /astrostuff-work
ENV PATH="$PATH:/astrostuff/bin"
VOLUME /astrostuff /astrostuff-work
WORKDIR /astrostuff

ENTRYPOINT ["/bin/bash"]
