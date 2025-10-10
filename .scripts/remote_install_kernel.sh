#!/bin/bash

# $1 - how far to format patches from?
# $2 - remote user...
# $3 - and IP
# $4 - kernel local version name to use
# $5 - where to reset the tree?
# $6 - if there is no auto password input, one needs to be provided here
# example:
# 	./remote_install_kernel.sh v6.17..HEAD~10 user 10.10.10.10 _test_kernel v6.17 [password]
#
# Required file structure is like this:
# One local kernel directory, two remote ones - 
# 	1. /home/<user>/linux_kernel : 	that's where the source is
# 	2. /home/<user>/kernel_build : 	that's where the build and .config file
# 					are
# and one patch folder on each machine.
# TODO: Will have to automate setting this up later.

# variables to configure:
LLVM="" # set to 'LLVM=1' if you want to compile with clang and lld

# need to have the same kernel repo in the _SOURCE directories
# need to have some config file in the REMOTE_BUILD_DIR
LOCAL_SOURCE="<local dir>"
REMOTE_SOURCE="/home/$2/linux_kernel"
REMOTE_BUILD_DIR="/home/$2/kernel_build"

# only need these two directories below to exist
LOCAL_PATCHES="<local dir>"
REMOTE_PATCHES="/home/$2/patches/remote_patches"

# other variables
LAST_DIR=$(pwd)
dq=\"
PASS=$(~/.scripts/parse_ssh.sh pass $2@$3)
if [[ -z $PASS || $PASS == "# pass" ]]; then
	PASSWORD=$(printf '%q' $6)
else
	PASSWORD=$(printf '%q' $PASS)
fi

# go to linux source code and extract patches, then copy them to remote server
cd $LOCAL_SOURCE
rm $LOCAL_PATCHES/*
git format-patch -o $LOCAL_PATCHES $1
ssh $2@$3 "rm $REMOTE_PATCHES/*"
scp $LOCAL_PATCHES/* $2@$3:${REMOTE_PATCHES}/

# reset the kernel tree to $5, then apply new patches and call nconfig
ssh $2@$3 "cd $REMOTE_SOURCE &&\
	git reset --hard $5 &&\
	git am $REMOTE_PATCHES/*;"
ssh $2@$3 -t "cd $REMOTE_SOURCE; make nconfig $LLVM O=$REMOTE_BUILD_DIR"

# Build kernel on the remote server.
# Then install it and change the local version so it's
# easy to tell which one was just installed.
# Afterwards grab the boot number to set a one time reboot
# in case of a failure - then after rebooting it will be back to the default
# stable entry.
# For now it only grabs things from ubuntu, TODO: may have to generalize it later
ssh $2@$3 "cd $REMOTE_SOURCE &&\
	scripts/config --file $REMOTE_BUILD_DIR/.config --set-str CONFIG_LOCALVERSION $4 &&\
	make $LLVM O=$REMOTE_BUILD_DIR -j$(nproc) bzImage modules &&\
	echo $PASSWORD | sudo -S make $LLVM O=$REMOTE_BUILD_DIR -j$(nproc) modules_install &&\
	echo $PASSWORD | sudo -S make $LLVM O=$REMOTE_BUILD_DIR -j$(nproc) install" && \
BOOT_NR=$(ssh $2@$3 "echo $PASSWORD | sudo -S grub-mkconfig | grep -i \
	${dq}menuentry 'Ubuntu, with Linux${dq} | awk '{print i++ ${dq} : ${dq}\$1, \$2, \
	\$3, \$4, \$5, \$6, \$7}' | grep '$4' | head -1 | awk '{print \$1}'") &&\
echo "Setting grub-reboot to number $BOOT_NR" &&\
ssh $2@$3 "cd $REMOTE_SOURCE &&\
	echo $PASSWORD | sudo -S grub-reboot $BOOT_NR &&\
	echo $PASSWORD | sudo -S reboot"

# go back to initial directory
cd $LAST_DIR
