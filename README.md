Astrostuff 
=====


Create your own customised, pre-cooked Raspberry Pi images with astronomy software already installed.

Version 1.0.0, 2025-03-24


# Legalstuff

Copyright (C) 2025 Nelson Sousa (nsousa@gmail.com)

Astrostuff is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Astrostuff is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Astrostuff.  If not, see <https://www.gnu.org/licenses/>.


# What is Astrostuff?

Astrostuff is yet another Astronomy oriented Raspberry Pi image



# Why Astrostuff?

I started my astrophotography journey a few years ago and from the start I used
a Raspberry Pi as the brains of the operation.

At first I used Astroberry. It worked ok, but was only 32 bits, so I wasn't taking
full advantage of the 8Gb of RAM my Raspberry Pi came with. And after a while
I began experiencing a lot of crashes and trouble getting everything to work,
so I wanted to switch to something that could offer me some level of support
beyond community forums.

So I moved to Stellarmate. 64 bits, took full advantage of my Raspberry Pi's RAM,
but at the time both indi drivers for my mount (iOptron iEQ45) and my camera
(Altair CCD) had lots of bugs that caused crashes or erratic operation. And Stellarmate was based on Ubuntu, must heavier than Raspberry Pi OS, which at the time only existed in 32 bits.

So I switched to Indigo. I like Indigo a lot, it's much lighter than Indi, and the client
handles very little. All the heavy lifting is done by agents running in the server, so
if the client crashes the telescope will continue to work. The server is rock solid and
the client is Mac native which works great for me. But the client is not as feature
rich as Ekos. Less control over the autofocus algorithms, no automated meridian flips,
no scheduling and planner. A lot of Ekos's bells and whistles have to be coded in
using scripts.

I went back to Kstars/Ekos. Especially because it now had an aberration analysis feature
and I was dealing with issues with tilt on my camera sensor. But this time I decided
to bake my own image. Started with plain Raspberry Pi OS desktop, and began installing
stuff myself. Unfortunately, Indi and Kstars's apt repositories only include precompiled
arm64 binaries for the most recent version of Ubuntu, and Raspberry Pi OS is based on Debian/Bookworm. So the packages don't install, they have to be built from source.

I built them using (astro-soft-build)[https://gitea.nouspiro.space/nou/astro-soft-build]'s scripts. And it worked. Great, I'm settle now. Or am I?

A few things kept nagging me:

- Every time I want to bake a new image I have to redo all customisations again. Installing
packages, creating symlinks, moving folders, etc. Which was time consuming. And required me
to take impeccable notes regarding every action I did;
- I had to switch from Wayland to X11 (kstars and phd2 don't run on Wayland) and enable VNC
- I also had to re-set all device defaults to match how I wanted them to run;
- And I had to re-download all astrometry index files
- Etc, etc, etc.

But, most importantly, at about this time I discovered a couple of bugs (well, more than a
couple) in my mount's driver. Which I fixed. But to test the fixes, the source code needs
to be compiled and installed.

Which brings me to the main pain point of using a Raspberry Pi when you want to start modifying
the source code: writing on the Pi is very slow, even with ultra fast SD cards; and SD cards
shouldn't be written, and re-written many times if that can be avoided.

So, the ideal would be building the software in my laptop (Intel Macbook), packaging it as
.deb files and copying them over. And, while I'm at it, might as well write a script to
backup/restore all of my customisations so I could get up to speed more quickly. Finally,
why not just build the entire Pi image from scratch?

And so, Astrostuff was born.

# What's included in Astrostuff

Astrostuff consists of a few components, but all user interaction is manager by a single script, ```astrostuff```. And all configuration is done in one single environment file, ```astrostuff.env```. Customisations are kept in a backup folder and new images will use
those customisations in the newly written .img file. And the source code can be modified,
compiled, packaged and deployed to the Pi much more quickly that it would take building
directly in the Pi.

All the work is done within one docker container, astrostuff-builder. Within, two scripts
handle all the heavy lifting:

- one builds the astronomy software (Kstars, Ekos, Phd2, Indi):
it clones the code from git, updates to the latest stable release, builds the binaries for
arm64, and packages them as .deb files.
- the second takes pi-gen's standard Raspberry Pi OS
image scripts, adds all the necessary customisations (either from the included samples or
from a backup), and writes the .img file.

Once finished all that's left is burn the image into an SD card (using Balena etcher),
installing it in the Pi and boot it up.

The following customisations are applied to the image, out of the box:

- creates or uses a predefined SSH key and adds it to the Pi's authorized_keys file
- disables password authentication
- sets first user's account name and password
- sets locale, keyboard layout, timezone
- install all necessary packages to run indi, kstars, ekos, phd2 and indigo;
- switches from Wayland back to X11
- enables VNC server
- sets up predefined Wifi connections (one for home wifi, another for a wifi hotspot)
- enables NTP sync
- installs a python script to snif and redirect USB communications with devices (useful
for driver development or debug)
- installs Indigo server, Ain imager and Indigo control panel
- installs indi core, indi 3rd party drivers, kstars, stellarsolver and phd2
- creates symlinks to keep all log files in a central location
- adds desktop icons to the installed applications

# Using Astrostuff

## TL;DR: I'm in a hurry 

Ok, here's how to use Astrostuff with minimal changes. **But do read the caveat below**.

1. Install Docker on your computer.

2. Copy file ```astrostuff.env``` from the samples folder to the root of the project. 
	Modify, these two variables:

	```
	ASTROSTUFF_DEFAULT_WIFI_SSID="home-wifi-ssid"
	ASTROSTUFF_DEFAULT_WIFI_PASSWORD="home-wifi-password"
	```
	
	For security reasons it's also strongly recommended to modify this one:
	
	```
	ASTROSTUFF_HOTSPOT_PASSWORD="astrostuff-password"
	```
	
	This process will take several hours to complete, depending on the speed of 
	your computer.
	
3. Run ```astrostuff full``` from the terminal. The scripts will take care of the rest.

4. Burn the .img file to an SD card and boot the Raspberry Pi. It should automatically
connect to your home wifi (although a wired connection is recommended as the Pi's wifi 
is a bit flaky), and if you have an additional Wifi antenna installed the hotspot should
also be available. Both SSH and VNC connections should work and all necessary software
should now be installed and ready to use: Indi, select 3rd party drivers, Kstars and PHD2.

### **Caveat emptor**:

Only 1 library and two Indi 3rd party drivers are built:

  - libplayerone
  - indi-playerone
  - indi-sx

The reason for that is that building the code for arm64 in docker running on a Mac runs
into all sorts of complications. Most notably, Cmake seems unable to find the correct
paths for all required packages, libraries, etc., which then have to be set manually
via ```-D``` flags.

For example, to build the indi-playerone driver, the following flags have to be
set explicitly for Cmake:

```
-DPLAYERONE_LIBRARIES=/usr/lib/aarch64-linux-gnu/libPlayerOneCamera.so \
-DINDI_LIBRARIES=/usr/lib/aarch64-linux-gnu/libindidriver.so \
-DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so"
```

The only way to find out which flags must be used for each driver is through trial
and error. After quite some time battling the various Cmake errors caused by all
sorts of drivers I don't need or use, I decided to focus only on those drivers I
actually need, which also speeds up the build process.

To add/change the list of 3rd party drivers, edit the script ```bin/astrostuff-build.sh```:

- Add/change 3rd party drivers to the ```$REPOSITORIES``` variable on line 47;
- Add the necessary flags to build that driver in the case statement that begins on line 177


## I'm not in a rush. Tell me the details

The Astrostuff script takes 3 arguments:

- a topic
- a command
- a repository/driver

### ```astrostuff full```

This is the "all-in-one" process. It deletes all previous docker data (images, containers,
volumes), rebuilds the image, starts the container, clones, builds and packages
all repositories (latest stable version), and creates the Raspberry Pi image with all
customisations.

If you're interested in just building Astrostuff, this is the recommended approach. However,
if you're customising the image, or experimenting, you may need to run the manual process,
described below.


### Astrostuff docker

The topic docker handles the creation and operation of the docker container:

* ```astrostuff docker build```: builds or updates the astrostuff Docker image;
* ```astrostuff docker start```: starts or restarts the container;
* ```astrostuff docker attach```: opens a bash shell in the container (useful for manual runs or debugging);
* ```astrostuff docker stop```: stops the container, without removing it (so it can later be restarted
without losing any changes);
* ```astrostuff docker remove```: removes the container (any modifications done to the container will be lost);
* ```astrostuff docker clean```: deletes all Docker data: images, containers, volumes.

### Astrostuff astro

All astro commands take an optional 3rd argument, a specific repository or driver. 
If ommitted, the script will run through every repository.

* ```astrostuff astro clone```: Clones the repositories to the src folder if they don't yet exist;
* ```astrostuff astro update```: Updates the repositories to the latest stable release ;
* ```astrostuff astro clean```: Clears the build target, so a new, clean build can be done;
* ```astrostuff astro build```: Compiles and builds the binaries from the source code;
* ```astrostuff astro install```: Installs the built binaries into their default locations
(required due to dependencies);
* ```astrostuff astro package```: Packages the binaries as a .deb file;
* ```astrostuff astro all```: Runs the entire build process from clone to package.

## Astrostuff image

Creates the Raspberry Pi .img file, ready for flashing to an SD card.

## Astrostuff deploy

Copies the packaged .deb files to the Astrostuff host and installs or re-installs them.

## Astrostuff backup

Copies all personalisation files from the Astrostuff host to the local machine.
The files/folders to backup are set in the ```astrostuff``` script, in two variables:

* ```$BACKUP_USER_ITEMS```: any files under the user's home folder you wish to backup.
The paths are relative to the user's ```$HOME``` folder.
* ```$BACKUP_SYSTEM_ITEMS```: system files/folders to backup. The paths are absolute.

These variables are set in lines 160 and 170 of ```astrostuff```. Edit as needed.

## Astrostuff restore

Copies the backup files to the Astrostuff host.

## Astrostuff help

Running astrostuff without arguments, or ```astrostuff help``` shows the usage information.


# Requirements

## Supported hardware/software

Astrostuff is a personal project. As such, it has only been tested on my personal setup:

* Apple Intel Macbook Pro (2019), macOS Sonoma
* Docker Desktop 4.39.0 (Docker engine 28.0.1)
* Raspberry Pi 4b 8Gb
* Raspberry Pi OS 64 bits based on Debian/bookworm

It may work on other systems, but there are no guarantees. It may require a lot of trial
and error.

## Supported drivers

Indi 3rd party is a large collection of drivers for all kinds of devices (cameras,
filter wheels, weather stations, domes, etc).

Each driver has its own quirks and there's no universal solution to have them build
in Docker under macOS (it'll probably be much easier in Linux). As such, only these
three drivers and libraries are currently implemented:

- libplayerone (required by indi-playerone)
- indi-playerone (driver for Player One cameras and filter wheels)
- indi-sx (driver for Starlight Xpress cameras)

For each driver Cmake needs some "guidance" to find the appropriate libraries. It
should be able to find them correctly, but all attempts at implementing a universal
fix failed. As such, each driver will have its own specific settings that must be
passed to Cmake as ```-D``` parameters. There's no way to find out which ones are
needed, other than trying to build each driver individually and finding the path
to the program, package or library that causes the first error, adding the corresponding
flag to the Cmake command and try again.

## Hard drive requirements

Out of the box, Astrostuff will use approximately 45 Gb of disk space. Docker must be
configured to allow at least that much space (64Gb recommended).

The used disk usage is more or less as such:

- Docker image: 3Gb;
- Docker container: 1Gb;
- Docker volume: 37Gb, of which:
  - build targets: 4Gb
  - built binaries: 1Gb
  - image intermediate stages and files: 30Gb

By far the biggest usage of disk space is the intermediate files of the image generator.
This is due to the way pi-gen works. The image is defined in stages, from stage0 to stage5, 
and each stage builds upon the previous one. For each stage a full copy of the file system is kept
in the work folder. As you can see below, the space required for each stage keeps growing, totalling
around 30Gb.

- stage0: 1.2Gb
- stage1: 1.3Gb
- stage2: 2.2Gb
- stage3: 4.3Gb
- stage4: 4.8Gb
- stage4-astrostuff: 8.0Gb
- export-image: 8.0Gb

These intermediate stages can be safely deleted once the image is created. They will be recreated
when the script is executed again.

# Known issues

* Astrostuff takes quite a while to run to completion (up to several hours, depending on the speed of 
the host computer). Building the software is a time consuming process, especially for kstars, 
the biggest of the tools to be built. And creating the img file also takes a long time.
* Because of the way Docker works internally, the process is quite sensitive to the version of Docker
being used. This is because different versions of Docker will use different Linux buildkits, which 
may impact the container's ability to compile the code against the correct arm64 architecture.
* Moreover, Macbooks with Intel CPUs and Macbooks running Apple silicon are very different. Apple
silicon is itself an ARM architecture, but Intel is not.
* Due to the Cmake quirks described above the build may file occasionally. The ```-D``` flags passed to 
each Cmake command may need to be adjusted in your system.
* If you rebuild the image, even if nothing changed, and flash the SD card with it Astrostuff's 
signature will have changed. This will trigger security warnings when you connect to Astrostuff,
whether via VNC or SSH.

# Updates, support, etc.

There may be occasional updates as I change the settings on my own Raspberry Pi and add functionality
to the tool. Or if I buy new equipment that requires me to build a different Indi 3rd party driver. 

But overall this project is not meant to be updated very often or to keep some release schedule.

It's a personal project, after all, and new features are mostly motivated by my own needs.

If you have trouble using the tool you can try and reach out via email, or open an issue in Github.

Clear skies!
