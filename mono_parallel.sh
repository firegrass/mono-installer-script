#!/bin/bash
#
# Version 0.1
# This script is to install a parallel mono environment with ease
# It only checks out/installs mono 2.6 branch on Ubuntu 9.10 atm
#
# Copyright 2009 (c) QMTech Ltd (http://www.qmtech.net)
# Authors: Patrick McEvoy (firegrass) patrick@qmtech.net
# This is free script under GNU GPL version 3.

# config
# TODO: Allow opt or home install option (hence sudo/no sudo)
# TODO: Allow have 2.6 or trunk
VERSION=2.6
MONO_PREFIX=/opt/mono-$VERSION
#GNOME_PREFIX=/opt/gnome-2.6
WORKING_DIR=~/mono-src/mono-$VERSION
# TODO: webserver/server/workstation (+mod_mono,-gnome,-mono-tools/-gnome,-mono-tools/-mod_mono)
MODE=server
# TODO: Option to hide all output
DEBUG=
#1>&2

echo "MI: This script will download/checkout mono and install in a parallel environment."
echo "MI: Report bugs to patrick@qmtech.net, firegrass on twitter, carrier pidgeon etc"

# 
if [ $MODE = "workstation" ] && [ "$(id -u)" = "0" ]; then
	echo "MI ERROR: This script should not be run as root" 1>&2
	exit 1
fi

echo "MI: Installing mono version $VERSION, building in $WORKING_DIR"
echo "MI: I need sudo access to install mono to /opt and mono-$VERSION in /usr/local/bin"
sudo echo "MI: If the sudo time limit is reached you will need to enter you password again."
# making a dir to work from
mkdir -p $WORKING_DIR
cd $WORKING_DIR

# svn checkouts
SVN_BASE=http://anonsvn.mono-project.com/source/branches/mono-2-6
# modules - hardcoded to branch 2.6

SVN_MODULES="libgdiplus mono mcs mono-tools mod_mono xsp"

for mod in $SVN_MODULES; do
	if [ -d $mod ]; then
		echo "MI: Updating $mod"
		svn up -q $mod || { echo "MI ERROR: Updating $mod failed"; exit 1; } 
	else
		echo "MI: Checking out $mod ($SVN_BASE/$mod)"
		svn co -q $SVN_BASE/$mod || { echo "MI ERROR: Checking out $mod failed"; exit 1; }
	fi
done

# create enviroment files
cat > "mono-$VERSION-environment" <<EOF
#!/bin/bash
MONO_PREFIX=$MONO_PREFIX
GNOME_PREFIX=/opt/gnome
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
MONO_PREFIX=$MONO_PREFIX
GNOME_PREFIX=/opt/gnome
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
for mod in $SVN_MODULES; do
	if [ $mod = "mcs" ]; then
		# Ignore mcs as built from mono
		echo "MI: Skiping mcs module"
	elif [ $MODE = "server" ] && [ $mod = "mono-tools" ]; then
		echo "MI: Skipping mono-tools (server install)"
	elif [ $MODE = "server" ] && [ $mod = "mod_mono" ]; then
		echo "MI: Skipping mono-tools (server install)"
	else
		echo "MI: Installing $mod"
		cd $mod
		./autogen.sh --prefix=$MONO_PREFIX $DEBUG && \
		make $DEBUG && \
		sudo make install $DEBUG || { echo "MI ERROR: $mod failed"; exit 1; }
		cd ..
	fi
done

# Exit message
echo "Your parallel environment is installed"
echo "To start a mono-$VERSION environment, run: source mono-$VERSION-environment"
echo "To use mono-$VERSION to run a cli app, run: mono-$VERSION <your app> (eg mono-$VERSION mono -V)"
