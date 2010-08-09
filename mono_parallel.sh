#!/bin/bash
#
# Version 0.1
# This script is to install a parallel mono environment with ease
# It only checks out/installs mono 2.6 branch on Ubuntu 9.10 atm
#
# Copyright 2009 (c) QMTech Ltd (http://www.qmtech.net)
# Authors: Patrick McEvoy (firegrass) patrick@qmtech.net
# Contributions from Dan Quirk, 
# This is free script under GNU GPL version 3.

#
# Config
#

# TODO: webserver/server/workstation (+mod_mono,-gnome,-mono-tools/-gnome,-mono-tools/-mod_mono)
WORKING_DIR=~/mono-src
# LOGFILE=`pwd`/mono_installer_`date --date=now +%y%m%d_%H%M`.log
LOGFILE=`pwd`/mono_installer.log
touch $LOGFILE

ECHO_PREFIX="---- "

#
# WARNING: Don't change stuff after here unless you're sure....
#

echo "$ECHO_PREFIX Copyright 2009 (c) QMTech Ltd (http://www.qmtech.net)"
echo "$ECHO_PREFIX Authors: Patrick McEvoy (firegrass) patrick@qmtech.net"
echo "$ECHO_PREFIX Contributions from Dan Quirk,⋅Stefan Forster"
echo "$ECHO_PREFIX This is free script under GNU GPL version 3."

# Supported versions 2.6, 2.6.4 or trunk
if [ $1 == "trunk" ]; then
	VERSION=trunk
elif [ $1 == "2.6" ]; then
	VERSION=2.6
else
	echo "$ECHO_PREFIX Requries version, mono_parallel.sh version eg mono_parallel.sh trunk"
	exit
fi

MONO_PREFIX=/opt/mono-$VERSION
GNOME_PREFIX=/usr

echo "$ECHO_PREFIX This script will install dependencies and checkout mono and install in a parallel environment."
echo "$ECHO_PREFIX Report bugs to patrick@qmtech.net, firegrass on twitter, carrier pidgeon etc"

sudo apt-get install build-essential automake libtool gettext mono-devel mono-1.0-devel \
	subversion libpng-dev libtiff-dev libgif-dev libjpeg-dev libexif-dev autoconf automake \
	bison flex libcairo2-dev libpango1.0-dev git-core -y >> $LOGFILE

if [ "$(id -u)" = "0" ]; then
	read -p "$ECHO_PREFIX WARNING: You are root, this means your git clones will be owned by root. Enter to continue, Ctrl+C to exit" inpVar
fi

echo "$ECHO_PREFIX I am installing mono version $VERSION, building in $WORKING_DIR"
echo "$ECHO_PREFIX I need sudo access to install mono to /opt and mono-$VERSION in /usr/local/bin"
sudo echo "$ECHO_PREFIX If the sudo time limit is reached you will need to enter you password again."
# making a dir to work from
mkdir -p $WORKING_DIR
cd $WORKING_DIR

# git path
GIT_BASE=git://github.com/mono

# svn modules to get
GIT_MODULES="libgdiplus mono gtk-sharp gnome-sharp mod_mono xsp mono-addins"
# GIT_MODULES="gnome-sharp xsp mono-addins"

# check it all out or update
for mod in $GIT_MODULES; do
	if [ -d $mod ]; then
		echo "$ECHO_PREFIX Updating $mod"
		cd ${mod}
		git pull -q || { echo "$ECHO_PREFIX ERROR: Updating $mod failed, you will need to manually 'git clean -df'"; exit 1; }
		cd ..
	else
		echo "Cloning $mod ($SVN_BASE/$mod)"
		git clone -q ${GIT_BASE}/${mod}.git || { echo "$ECHO_PREFIX ERROR: Cloning $mod failed"; exit 1; }
	fi
done

# Configure version versions to use

# Use a sane gtk-sharp version
cd gtk-sharp
git checkout --track -b gtk-sharp-2-12-branch origin/gtk-sharp-2-12-branch
cd ..

if [ $VERSION == "trunk" ]; then
	cd mono
	git checkout master
	cd ..
elif [ $VERSION == "2.6" ]; then
	cd mono
	git checkout --track -b mono-2-6 origin/mono-2-6
	cd ..
fi

# create enviroment files
cat > "mono-$VERSION-environment" <<EOF
#!/bin/bash
export MONO_GAC_PREFIX=$MONO_PREFIX:/usr
export DYLD_LIBRARY_PATH=$MONO_PREFIX/lib:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=$MONO_PREFIX/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$MONO_PREFIX/include:$GNOME_PREFIX/include
export ACLOCAL_PATH=$MONO_PREFIX/share/aclocal
export PKG_CONFIG_PATH=$MONO_PREFIX/lib/pkgconfig:$GNOME_PREFIX/lib/pkgconfig
PATH=$MONO_PREFIX/bin:$PATH
PS1="[mono] \w @ "
EOF

cat > "mono-$VERSION" <<EOF
#!/bin/bash
export MONO_GAC_PREFIX=$MONO_PREFIX:/usr
export DYLD_LIBRARY_PATH=$MONO_PREFIX/lib:$DYLD_LIBRARY_PATH
export LD_LIBRARY_PATH=$MONO_PREFIX/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$MONO_PREFIX/include:$GNOME_PREFIX/include
export ACLOCAL_PATH=$MONO_PREFIX/share/aclocal
export PKG_CONFIG_PATH=$MONO_PREFIX/lib/pkgconfig:$GNOME_PREFIX/lib/pkgconfig
PATH=$MONO_PREFIX/bin:$PATH

exec "\$@"
EOF

# install environemnt
chmod +x mono-$VERSION-environment mono-$VERSION
sudo mv mono-$VERSION-environment /usr/local/bin/mono-$VERSION-environment
sudo mv mono-$VERSION /usr/local/bin/mono-$VERSION

# using new environment
. mono-$VERSION-environment

# configure, make, install
for mod in $GIT_MODULES; do
	echo "$ECHO_PREFIX Installing $mod"
	cd $mod
	if [ $mod == "gtk-sharp" ]; then
		./bootstrap-2.12 --prefix=$MONO_PREFIX
	elif [ $mod == "gnome-sharp" ]; then
		./bootstrap-2.24 --prefix=$MONO_PREFIX
	else
		./autogen.sh --prefix=$MONO_PREFIX
	fi

	make && \
	sudo make install || { echo "$ECHO_PREFIX ERROR: $mod failed"; exit 1; }
	cd ..
done

# Exit message
echo ""
echo "$ECHO_PREFIX Your parallel environment is installed"
echo "$ECHO_PREFIX To start a mono-$VERSION environment, run: source mono-$VERSION-environment"
echo "$ECHO_PREFIX To use mono-$VERSION to run a cli app, run: mono-$VERSION <your app> (eg mono-$VERSION mono -V)"
echo ""

read -p "Done." inpVar
