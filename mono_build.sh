#!/bin/bash
#
# Version 0.2
# This script is to install a parallel mono environment with ease
# It checks out/installs mono 2.6, 2.8, 2.10, or master branch on Ubuntu 11.04 
#
# Copyright 2009-2011 (c) QMTech Ltd (http://www.qmtech.net)
# Authors: Patrick McEvoy (firegrass) patrick@qmtech.net
# Contributions from Dan Quirk, William F. Cook
# This is free script under GNU GPL version 3.

# LLVM is built but not loaded by default. Use "export MONO_USE_LLVM=1" to turn it on

#options
skipupdate=
skipbuild=
pauseflag=
inpvar=
cleangit=
prefix=/opt

ECHO_PREFIX="-- "

while getopts ‘abm:ituv:p:hc’ opt
do
case $opt in
a) GIT_MODULES="libgdiplus llvm mono gtk-sharp xsp mod_mono mono-basic mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
echo "$ECHO_PREFIX Building all"
;;
b) skipbuild=1
echo "$ECHO_PREFIX Skipping build"
;;
c) cleangit=1
echo "$ECHO_PREFIX Cleaning git repository before build"
;;
i) pauseflag=1
echo "$ECHO_PREFIX Pausing before configure/make/install steps"
;;
m) GIT_MODULES="$OPTARG"
echo "$ECHO_PREFIX Building $GIT_MODULES"
;;
p) prefix=$OPTARG
echo "$ECHO_PREFIX Using prefix $prefix"
;;
s) GIT_MODULES="libgdiplus llvm mono gtk-sharp xsp mod_mono"
echo "$ECHO_PREFIX Building mono"
;;
t) GIT_MODULES="libgdiplus mono gtk-sharp xsp mod_mono mono-basic mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
echo "$ECHO_PREFIX Building mono and development tools, without llvm, not required for asp.net development"
;;
u) skipupdate=1
echo "$ECHO_PREFIX Skipping source code update"
;;
v) VERSION=$OPTARG
if [[ $VERSION == "master" || $VERSION == "2.10" || $VERSION == "2.8" || $VERSION == "2.6" ]]; then
    echo "$ECHO_PREFIX Building version $VERSION"
else
    echo "$ECHO_PREFIX Error: Only master, 2.10, 2.8, 2.6 versions supported"
    exit 1
fi
;;
h) 
    echo "Usage: mono_build.sh [-v version] [-p prefix] [-m gitmodules] [-r] [-s] [-t] [-a] [-i] [-u] [-b] [-c]";
    echo
    echo "Command line options"
    echo
    echo "  -v   specify version of mono - master, 2.6, 2.8, 2.10"
    echo
    echo "  -p   specify prefix to install"
    echo
    echo "  -m   specify ONLY these git modules to build, choose from - libgdiplus llvm mono gtk-sharp xsp mod_mono mono-basic"
    echo "       mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp"
    echo "       mono-tools debugger monodevelop"
    echo
    echo "  -r   Just build mono, builds modules -libgdiplus llvm mono gtk-sharp xsp mod_mono"
    echo
    echo "  -s   Just build development modules, builds modules -mono-basic"
    echo "       mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
    echo
    echo "  -t   Build all modules but llvm (takes long time to compile) not required for asp.net development"
    echo
    echo "  -a   Build all modules"
    echo
    echo "  -i   Interactive mode, pause between each modules make and make install. Allows skipping of modules"
    echo
    echo "  -u   Do not update source code, just build"
    echo
    echo "  -b   Do not build, just update source code"
    echo
    echo "  -c   Clean git before building"
    echo
    echo "Examples"
    echo ""
    echo "  mono_build.sh -v 2.10 -p ~/mono -r"
    echo "  mono_build.sh -v 2.10 -p ~/mono -m mono-addins mono-tools"
    exit 0
;;
esac
done

if [[ -z "$VERSION" ]]; then
    echo "$ECHO_PREFIX Error: Please specify a mono version to build with -v; master, 2.10, 2.8, 2.6 versions are supported"
    exit 1
fi
if [[ -z "$GIT_MODULES" ]]; then
    echo "$ECHO_PREFIX Error: Please specify which modules to install -r, base mono install, -s, development modules, -t, all but llvm, -a, all"
    exit 1
fi

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
    elif [ $VERSION == "2.10" ]; then
        echo "$ECHO_PREFIX Configuring $mod for version 2.10"
        if [ $mod == "mono" ]; then
            git checkout mono-2-10
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
            git checkout master
        elif [ $mod == "monodevelop" ]; then
            git checkout 2.4
        elif [ $mod == "debugger" ]; then
            git checkout mono-2-6
        elif [ $mod == "xsp" ]; then
            git checkout master
        elif [ $mod == "mono-tools" ]; then
            git checkout mono-2-10
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
        elif [ $mod == "debugger" ]; then
            git checkout mono-2-8
        elif [ $mod == "xsp" ]; then
            git checkout mono-2-8
        elif [ $mod == "mono-tools" ]; then
            git checkout mono-2-8
        fi
    elif [ $VERSION == "2.6" ]; then
        echo "$ECHO_PREFIX Configuring $mod for version 2.6"
        if [ $mod == "mono" ]; then
            git checkout mono-2-6
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
        elif [ $mod == "debugger" ]; then
            git checkout mono-2-6
        elif [ $mod == "xsp" ]; then
            git checkout mono-2-6
        elif [ $mod == "mono-tools" ]; then
            git checkout mono-2-6
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
        if [ "$VERSION$mod" == "2.6llvm" ]; then
            echo "$ECHO_PREFIX skipping LLVM for this mono version [$VERSION]";
        elif [ -d $mod ]; then
            echo "$ECHO_PREFIX Updating $mod"
            cd ${mod}
            if [ "$cleangit" ]; then
                git reset --hard
                git clean -df
            fi
            checkout_correct_version
            git pull || { echo "$ECHO_PREFIX ERROR: Updating $mod failed, you will need to manually ‘git clean -df’"; exit 1; }
            cd ..
        else
            echo "$ECHO_PREFIX Cloning $mod ($SVN_BASE/$mod)"
            git clone ${GIT_BASE}/${mod}.git || { echo "$ECHO_PREFIX ERROR: Cloning $mod failed"; exit 1; }

            cd ${mod}

            if [ $mod == "mono" ]; then
                git checkout --track -b mono-2-8 origin/mono-2-8
                git checkout --track -b mono-2-6 origin/mono-2-6
                git checkout --track -b mono-2-6 origin/mono-2-10
            elif [ $mod == "gtk-sharp" ]; then
                git checkout --track origin/gtk-sharp-2-12-branch
            elif [ $mod == "gnome-desktop-sharp" ]; then
                git checkout --track -b gnome-desktop-sharp-2-24-branch origin/gnome-desktop-sharp-2-24-branch
            elif [ $mod == "mono-addins" ]; then
                git checkout --track -b 0.5 origin/0.5
            elif [ $mod == "monodevelop" ]; then
                git checkout --track -b 2.4 origin/2.4
            elif [ $mod == "debugger" ]; then
                git checkout --track -b mono-2-6 origin/mono-2-6
                git checkout --track -b mono-2-8 origin/mono-2-8
            elif [ $mod == "xsp" ]; then
                git checkout --track -b mono-2-6 origin/mono-2-6
                git checkout --track -b mono-2-8 origin/mono-2-8
            elif [ $mod == "mono-tools" ]; then
                git checkout --track -b mono-2-6 origin/mono-2-6
                git checkout --track -b mono-2-8 origin/mono-2-8
                git checkout --track -b mono-2-8 origin/mono-2-10
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

        if [ "$VERSION$mod" == "2.6llvm" ]; then
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
	    elif [[ $mod == "mono" && $GIT_MODULES == "*llvm*" ]]; then
	        ./autogen.sh --prefix=$MONO_PREFIX --enable-llvm
    	else
            ./autogen.sh --prefix=$MONO_PREFIX
        fi

        make || { read -p "$ECHO_PREFIX ERROR: $mod failed to compile, press enter to continue" inpVar; cd ..; continue; }

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
        
        sudo make install || { read -p "$ECHO_PREFIX ERROR: $mod failed, press enter to continue" inpVar; cd ..; continue; }
        
        cd ..
        
    done

fi

# Exit message
echo ""
echo "$ECHO_PREFIX Your parallel environment is installed in $MONO_PREFIX"
echo "$ECHO_PREFIX To start a mono-$VERSION environment, run: source mono-$VERSION-environment"
echo "$ECHO_PREFIX To use mono-$VERSION to run a cli app, run: mono-$VERSION (eg mono-$VERSION mono -V)"
echo ""

#read -p "Done." inpVar
echo "Done"
