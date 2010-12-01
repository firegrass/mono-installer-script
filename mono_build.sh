#!/bin/bash
#
# Version 0.2
# This script is to install a parallel mono environment with ease
# It only checks out/installs mono 2.6 branch on Ubuntu 9.10 atm
#
# Copyright 2009 (c) QMTech Ltd (http://www.qmtech.net)
# Authors: Patrick McEvoy (firegrass) patrick@qmtech.net
# Contributions from Dan Quirk, William F. Cook
# This is free script under GNU GPL version 3.

# Modified by William F. Cook for use at DRS AMTC to build full monodevelop environment
# DRS Notes:
# * LLVM is built but not loaded by default. Modify mono-2.8 & mono-2.8-env
# with the "export MONO_USE_LLVM=1" in order to turn it on by defalut
# * mono is built mostly default options. You may want to add
# --enable-big-arrays or other options
#
#
# To get XSP to build, you may first have to modifi ./mono-src-$VERSION/xsp/docs/makefile.am
# to change:
#
# INSTALLATION_DIR=$(shell pkg-config monodoc --variable=sourcesdir)
#
# to:
#
# INSTALLATION_DIR=/opt/mono-2.8/lib/monodoc/sources
#
# I’m working on that…

#
# Config
#

#default version is master. Also supported is "2.8"
VERSION=master

#option -s skips updating files from github
skipupdate=
skipbuild=
pauseflag=
inpvar=
prefix=/opt

ECHO_PREFIX="-- "

GIT_MODULES="libgdiplus llvm mono gtk-sharp xsp mod_mono"

while getopts ‘abm:ituv:p:h’ opt
do
case $opt in
a) GIT_MODULES="libgdiplus llvm mono gtk-sharp xsp mod_mono mono-basic mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
echo "$ECHO_PREFIX Building all"
;;
b) skipbuild=1
echo "$ECHO_PREFIX Skipping build"
;;
m) GIT_MODULES="$OPTARG"
echo "$ECHO_PREFIX Building $GIT_MODULES"
;;
i) pauseflag=1
echo "$ECHO_PREFIX Pausing before configure/make/install steps"
;;
t) GIT_MODULES="mono-basic mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
echo "$ECHO_PREFIX Building mono development tools"
;;
u) skipupdate=1
echo "$ECHO_PREFIX Skipping source code update"
;;
v) VERSION=$OPTARG
if [[ $VERSION == "master" || $VERSION == "2.8" || $VERSION == "2.6.7" ]]; then
    echo "$ECHO_PREFIX Building version $VERSION"
else
    echo "$ECHO_PREFIX Error: Only master, 2.8, 2.6.7 versions supported"
    exit 1
fi
;;
p) prefix=$OPTARG
echo "$ECHO_PREFIX Using prefix $prefix"
;;
h) 
    echo "Usage: build_mono_parallel [-v version] [-p prefix] [-s] [-t]"; 
    exit 0
;;
esac
done

WORKING_DIR=~/mono-src

#
# WARNING: Don’t change stuff after here unless you’re sure….
#

checkout_correct_version ()
{
    # Configure version to use
    if [ $VERSION == "master" ]; then
        echo "$ECHO_PREFIX Configuring $mod for master"
        # gtk-sharp always requires 2.12 branch
        if [ $mod == "gtk-sharp" ]; then
            git checkout gtk-sharp-2-12-branch
        else
            git checkout master
        fi
    elif [ $VERSION == "2.8" ]; then
        echo "$ECHO_PREFIX Configuring $mod for version 2.8"
                
        if [ $mod == "mono" ]; then
            git checkout mono-2-8
        elif [ $mod == "gtk-sharp" ]; then
            git checkout gtk-sharp-2-12-branch
        elif [ $mod == "gnome-sharp" ]; then
            git checkout master
        elif [ $mod == "webkit-sharp" ]; then
            git checkout master
        elif [ $mod == "gtkmozembed-sharp" ]; then
            git checkout master
        elif [ $mod == "gnome-desktop-sharp" ]; then
            git checkout gnome-desktop-sharp-2-24-branch
        elif [ $mod == "mono-addins" ]; then
            git checkout 0.5
        elif [ $mod == "monodevelop" ]; then
            git checkout 2.4
        fi
    elif [ $VERSION == "2.6.7" ]; then
        echo "$ECHO_PREFIX Configuring $mod for version 2.6.7"
        if [ $mod == "mono" ]; then
            git checkout mono-2-6-7
        elif [ $mod == "gtk-sharp" ]; then
            git checkout gtk-sharp-2-12-branch
        elif [ $mod == "gnome-sharp" ]; then
            git checkout master
        elif [ $mod == "webkit-sharp" ]; then
            git checkout master
        elif [ $mod == "gtkmozembed-sharp" ]; then
            git checkout master
        elif [ $mod == "gnome-desktop-sharp" ]; then
            git checkout gnome-desktop-sharp-2-24-branch
        elif [ $mod == "mono-addins" ]; then
            git checkout 0.5
        elif [ $mod == "monodevelop" ]; then
            git checkout 2.4
        fi
    fi
}


echo "$ECHO_PREFIX Copyright 2009 (c) QMTech Ltd (http://www.qmtech.net)"
echo "$ECHO_PREFIX Authors: Patrick McEvoy (firegrass) patrick@qmtech.net"
echo "$ECHO_PREFIX Contributions from Dan Quirk,⋅Stefan Forster"
echo "$ECHO_PREFIX This is free script under GNU GPL version 3."

MONO_PREFIX=$prefix/mono-$VERSION
GNOME_PREFIX=/usr

echo "$ECHO_PREFIX I will install dependencies, checkout mono and install in a parallel environment."
echo "$ECHO_PREFIX I am installing mono version $VERSION, building in $WORKING_DIR"
echo "$ECHO_PREFIX I need sudo access to install mono to /opt and mono-$VERSION in /usr/local/bin"
sudo echo "$ECHO_PREFIX If the sudo time limit is reached you will need to enter you password again."
echo "$ECHO_PREFIX Report bugs to patrick@qmtech.net, firegrass on twitter, carrier pidgeon etc"

# install dependencies
sudo apt-get install build-essential automake libtool gettext gawk intltool \
libpng-dev libtiff-dev libgif-dev libjpeg-dev libexif-dev autoconf automake \
bison flex libcairo2-dev libpango1.0-dev git-core libatk1.0-dev libgtk2.0-dev \
libglade2-dev libgnomecanvas2-dev libgnome2-dev libgnomeui-dev \
libpanel-applet2-dev libgnomeprint2.2-dev libgnomeprintui2.2-dev libgtkhtml3.14-dev libgtksourceview2.0-dev libnautilus-burn-dev librsvg2-dev libvte-dev libwncksync-dev \
libnspr4-dev libnss3-dev libwebkit-dev xulrunner-dev \
apache2-threaded-dev \
-y

# you really shouldn’t be doing this as root, you know…
if [ "$(id -u)" = "0" ]; then
    read -p "$ECHO_PREFIX WARNING: You are root, this means your git clones will be owned by root. Enter to continue, Ctrl+C to exit" inpVar
fi

echo "$ECHO_PREFIX I am installing mono version $VERSION, building in $WORKING_DIR"
echo "$ECHO_PREFIX I need sudo access to install mono to /opt and mono-$VERSION in /usr/local/bin"
sudo echo "$ECHO_PREFIX If the sudo time limit is reached you will need to enter you password again."
# making a dir to work from
mkdir -p $WORKING_DIR
cd $WORKING_DIR

# git path for mono sources
GIT_BASE=http://github.com/mono

if [ "$skipupdate" ]; then
    echo "$ECHO_PREFIX Skipping source update"
else
    # check it all out or update
    for mod in $GIT_MODULES; do
        if [ "$VERSION$mod" == "2.6.7llvm" ]; then
            echo "$ECHO_PREFIX skipping LLVM for this version";
        elif [ -d $mod ]; then
            echo "$ECHO_PREFIX Updating $mod"
            cd ${mod}
            checkout_correct_version
            git pull || { echo "$ECHO_PREFIX ERROR: Updating $mod failed, you will need to manually ‘git clean -df’"; exit 1; }
            cd ..
        else
            echo "$ECHO_PREFIX Cloning $mod ($SVN_BASE/$mod)"
            git clone ${GIT_BASE}/${mod}.git || { echo "$ECHO_PREFIX ERROR: Cloning $mod failed"; exit 1; }

            cd ${mod}
            
            if [ $mod == "mono" ]; then
                git checkout --track origin/mono-2-8
                git checkout --track origin/mono-2-6-7
            elif [ $mod == "gtk-sharp" ]; then
                git checkout --track origin/gtk-sharp-2-12-branch
            elif [ $mod == "gnome-desktop-sharp" ]; then
                git checkout --track origin/gnome-desktop-sharp-2-24-branch
            elif [ $mod == "mono-addins" ]; then
                git checkout --track origin/0.5
            elif [ $mod == "monodevelop" ]; then
                git checkout --track origin/2.4
            fi
            
            checkout_correct_version
            
            cd ..
        fi
    done
fi

# create enviroment files
cat > "mono-$VERSION-environment" <<EOF
#!/bin/bash
MONO_PREFIX=$MONO_PREFIX
GNOME_PREFIX=/usr
export DYLD_LIBRARY_FALLBACK_PATH=$MONO_PREFIX/lib:$DYLD_LIBRARY_FALLBACK_PATH
export LD_LIBRARY_PATH=$MONO_PREFIX/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$MONO_PREFIX/include:$GNOME_PREFIX/include
export ACLOCAL_PATH=$MONO_PREFIX/share/aclocal
export PKG_CONFIG_PATH=$MONO_PREFIX/lib/pkgconfig:$GNOME_PREFIX/lib/pkgconfig
export PATH=$MONO_PREFIX/bin:$PATH
PS1="[mono-$VERSION] \w @ "
EOF

cat > "mono-$VERSION" <<EOF
#!/bin/bash
MONO_PREFIX=$MONO_PREFIX
GNOME_PREFIX=/usr
export DYLD_LIBRARY_FALLBACK_PATH=$MONO_PREFIX/lib:$DYLD_LIBRARY_FALLBACK_PATH
export LD_LIBRARY_PATH=$MONO_PREFIX/lib:$LD_LIBRARY_PATH
export C_INCLUDE_PATH=$MONO_PREFIX/include:$GNOME_PREFIX/include
export ACLOCAL_PATH=$MONO_PREFIX/share/aclocal
export PKG_CONFIG_PATH=$MONO_PREFIX/lib/pkgconfig:$GNOME_PREFIX/lib/pkgconfig
export PATH=$MONO_PREFIX/bin:$PATH

exec "\$@"
EOF

# install environemnt
chmod +x mono-$VERSION-environment mono-$VERSION
sudo mv mono-$VERSION-environment /usr/local/bin/mono-$VERSION-environment
sudo mv mono-$VERSION /usr/local/bin/mono-$VERSION

# using new environment
. mono-$VERSION-environment

if [ "$skipbuild" ]; then
    echo "$ECHO_PREFIX Skipping build"
else
    for mod in $GIT_MODULES; do

        if [ "$VERSION$mod" == "2.6.7llvm" ]; then
            echo "$ECHO_PREFIX Skipping LLVM for this 2.6.7";
            continue
        fi

        if [ $pauseflag ]; then
            read -p "Configure and make $mod, 'x' to exit, 's' to skip, enter to continue: " inpVar
            if [ "$inpVar" == "x" ]; then
                exit 1;
            elif [ "$inpVar" == "s" ]; then
                continue
            fi
        else
            echo "$ECHO_PREFIX Making $mod"
        fi

        cd $mod

	    if [ $mod == "gtk-sharp" ]; then
	    	./bootstrap-2.12 --prefix=$MONO_PREFIX
	    elif [ $mod == "gnome-sharp" ]; then
	    	./bootstrap-2.24 --prefix=$MONO_PREFIX
	    elif [ $mod == "llvm" ]; then
	        ./configure --enable-optimized
	    elif [ $mod == "mono" ]  && [ && $GIT_MODULES == "*llvm*" ]; then
	        ./autogen.sh --prefix=$MONO_PREFIX --enable-llvm
    	else
            ./autogen.sh --prefix=$MONO_PREFIX
        fi

        make || { read -p "$ECHO_PREFIX ERROR: $mod failed to compile, press enter to continue" inpVar; cd ..; }

        if [ $pauseflag ]; then
            read -p "Install $mod, 'x' to exit, 's' to skip, enter to continue: " inpVar
            if [ "$inpVar" == "x" ]; then
                exit 1;
            elif [ "$inpVar" == "s" ]; then
                continue
            fi
        else
            echo "$ECHO_PREFIX Installing $mod"
        fi
        
        sudo make install || { read -p "$ECHO_PREFIX ERROR: $mod failed, press enter to continue" inpVar; cd ..; }
        
        cd ..
        
    done

fi

# Exit message
echo ""
echo "$ECHO_PREFIX Your parallel environment is installed"
echo "$ECHO_PREFIX To start a mono-$VERSION environment, run: source mono-$VERSION-env"
echo "$ECHO_PREFIX To use mono-$VERSION to run a cli app, run: mono-$VERSION (eg mono-$VERSION mono -V)"
echo ""

#read -p "Done." inpVar
echo "Done"
