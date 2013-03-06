#!/bin/bash
#
# Version 0.2
# This script is to install a parallel mono environment with ease
# It checks out/installs mono 2.6, 2.8, 2.10, or master branch on Ubuntu 11.04 
#
# Copyright 2009-2011 (c) QMTech Ltd (http://www.qmtech.net)
# Authors: Patrick McEvoy (firegrass) patrick@qmtech.net
# Contributions from Dan Quirk, William F. Cook, Vsevolod Kukol
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

# git path for mono sources
GIT_BASE=http://github.com/mono

while getopts ‘abd:lm:irstuv:p:hc’ opt
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
l) missingdep=
[ "$(which xmlstarlet)" == "" ] && missingdep="$missingdep xmlstarlet"
if [ ! -z $missingdep ]; then
    echo "$ECHO_PREFIX The following packages are required to fetch the module list from GitHub:"
    echo "$ECHO_PREFIX -> $missingdep"
    echo "$ECHO_PREFIX I need sudo access to install missing dependecies."
    sudo apt-get install $missingdep -y
fi
wget --timeout=30 --quiet -O - http://github.com/api/v2/xml/repos/show/mono |  xmlstarlet sel -T -t -m '//repository' -v name -o "§" -v description -n | column -t -s '§' | cut -c 1-$(tput cols)
exit
;;
m) GIT_MODULES="$OPTARG"
echo "$ECHO_PREFIX Building $GIT_MODULES"
;;
p) prefix=$OPTARG
echo "$ECHO_PREFIX Using prefix $prefix"
;;
r) GIT_MODULES="libgdiplus llvm mono gtk-sharp xsp mod_mono"
echo "$ECHO_PREFIX Building mono"
;;
s) GIT_MODULES="mono-basic mono-addins gtkmozembed-sharp webkit-sharp gluezilla gnome-sharp gnome-desktop-sharp mono-tools debugger monodevelop"
echo "$ECHO_PREFIX Building mono development tools"
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
d) MDVERSION=$OPTARG
echo "$ECHO_PREFIX Building custom Monodevelop version $MDVERSION"
;;
h) 
    echo "Usage: mono_build.sh [-v version] [-d mdversion]"
    echo "                     [-p prefix] [-m gitmodules]"
    echo "                     [-r] [-s] [-t] [-a] [-i] [-u] [-b] [-c]"
    echo
    echo "Command line options"
    echo
    echo "  -v   specify version of mono - master, 2.6, 2.8, 2.10"
    echo
    echo "  -d   specify different version of monodevelop - master, 2.6, 2.8,"
    echo "       2.9, or any other monodevelop branch."
    echo "       If the specific version does not exist, the script will"
    echo "       fallback to the default for the selected mono version."
    echo
    echo "  -p   specify prefix to install (DEFAULT: $prefix)"
    echo
    echo "  -m   specify ONLY these git modules to build. (see also -l)"
    echo
    echo "  -l   Fetch and display the list with all available modules"
    echo "       from $GIT_BASE"
    echo
    echo "  -r   Just build mono, builds modules:"
    echo "           libgdiplus llvm mono gtk-sharp xsp mod_mono"
    echo
    echo "  -s   Just build development modules, builds modules:"
    echo "           mono-basic mono-addins gtkmozembed-sharp webkit-sharp"
    echo "           gluezilla gnome-sharp gnome-desktop-sharp mono-tools"
    echo "           debugger monodevelop"
    echo
    echo "  -a   Build mono and development modules (-s -r together)"
    echo
    echo "  -t   Build mono and development modules without llvm"
    echo "       (only for asp.net development!)"
    echo
    echo "  -i   Interactive mode, pause between each modules make and"
    echo "       make install. Allows skipping of modules"
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

if [ $VERSION == "master" ]; then
    DEFAULT_MDVERSION="master"
elif [ $VERSION == "2.10" ]; then
    DEFAULT_MDVERSION="2.8.6"
elif [ $VERSION == "2.8" ]; then
    DEFAULT_MDVERSION="2.4"
elif [ $VERSION == "2.6" ]; then
    DEFAULT_MDVERSION="2.4"
fi

if [[ -z "$MDVERSION" ]]; then
    MDVERSION=$DEFAULT_MDVERSION
    echo "$ECHO_PREFIX Building default Monodevelop version $MDVERSION"
fi

WORKING_DIR=~/mono-src

#
# WARNING: Don’t change stuff after here unless you’re sure….
#

checkout_correct_version ()
{
    # Configure version to use
    if [ $mod == "monodevelop" ]; then
        echo "$ECHO_PREFIX Configuring monodevelop for version $MDVERSION"
        git checkout $MDVERSION
        if [ $? -ne 0 ]; then
            echo "$ECHO_PREFIX monodevelop version $MDVERSION not found! Falling back to default!"
            MDVERSION=$DEFAULT_MDVERSION
            git checkout $MDVERSION
        fi
        return
    fi

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
            git checkout 0.6.2
        elif [ $mod == "debugger" ]; then
            git checkout master
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
echo "$ECHO_PREFIX Contributions from Dan Quirk,⋅Stefan Forster, Vsevolod Kukol"
echo "$ECHO_PREFIX This is free script under GNU GPL version 3."

MONO_PREFIX=$prefix/mono-$VERSION
GNOME_PREFIX=/usr

echo "$ECHO_PREFIX I will install dependencies, checkout mono and install in a parallel environment."
echo "$ECHO_PREFIX I am installing mono version $VERSION, building in $WORKING_DIR"
echo "$ECHO_PREFIX I need sudo access to install mono to /opt and mono-$VERSION in /usr/local/bin"
sudo echo "$ECHO_PREFIX If the sudo time limit is reached you will need to enter you password again."
echo "$ECHO_PREFIX Report bugs to patrick@qmtech.net, firegrass on twitter, carrier pidgeon etc"

# install dependencies

. /etc/lsb-release

UBUNTU_VERSION=$(echo $DISTRIB_RELEASE |tr -d '.')

if [ $UBUNTU_VERSION -le 1104 ]; then

	sudo apt-get install build-essential automake libtool gettext gawk intltool \
	libpng-dev libtiff-dev libgif-dev libjpeg-dev libexif-dev autoconf automake \
	bison flex libcairo2-dev libpango1.0-dev git-core libatk1.0-dev libgtk2.0-dev \
	libglade2-dev libgnomecanvas2-dev libgnome2-dev libgnomeui-dev \
	libpanel-applet2-dev libgnomeprint2.2-dev libgnomeprintui2.2-dev libgtkhtml3.14-dev \
	libgtksourceview2.0-dev libnautilus-burn-dev librsvg2-dev libvte-dev libwncksync-dev \
	libnspr4-dev libnss3-dev libwebkit-dev xulrunner-dev \
	apache2-threaded-dev \
	-y

else

	sudo apt-get install build-essential automake libtool gettext gawk intltool \
	libpng-dev libtiff-dev libgif-dev libjpeg-dev libexif-dev autoconf automake \
	bison flex libcairo2-dev libpango1.0-dev git-core libatk1.0-dev libgtk2.0-dev \
	libglade2-dev libgnomecanvas2-dev libgnome2-dev libgnomeui-dev \
	libgnome-desktop-dev libgnome-desktop-3-dev libgnomeprint2.2-dev libgnomeprintui2.2-dev \
	libgtkhtml3.14-dev libgtksourceview2.0-dev librsvg2-dev libvte-dev \
	libnspr4-dev libnss3-dev libwebkit-dev \
	apache2-threaded-dev \
	-y

fi

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
                git checkout --track -b mono-2-10 origin/mono-2-10
            elif [ $mod == "gtk-sharp" ]; then
                git checkout --track origin/gtk-sharp-2-12-branch
            elif [ $mod == "gnome-desktop-sharp" ]; then
                git checkout --track -b gnome-desktop-sharp-2-24-branch origin/gnome-desktop-sharp-2-24-branch
            elif [ $mod == "mono-addins" ]; then
                git checkout --track -b 0.5 origin/0.5
                git checkout --track -b 0.6.2 origin/0.6.2
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
export MONO_GAC_PREFIX=$MONO_PREFIX:$MONO_GAC_PREFIX
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
export MONO_GAC_PREFIX=$MONO_PREFIX:$MONO_GAC_PREFIX
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
	    elif [ $mod == "monodevelop" ]; then	
        	./configure --prefix=$MONO_PREFIX
	    elif [[ $mod == "mono" && $GIT_MODULES == "*llvm*" ]]; then
	        ./autogen.sh --prefix=$MONO_PREFIX --enable-llvm
    	else
            if [ -f ./autogen.sh ]; then
                ./autogen.sh --prefix=$MONO_PREFIX
            elif [ -f ./configure ]; then
                ./configure --prefix=$MONO_PREFIX
            else
                read -p "$ECHO_PREFIX ERROR: $mod configuration script not found, press enter to continue" inpVar; cd ..; continue;
            fi
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
        
        if [ $mod == "monodevelop" ]; then
            sudo cp $MONO_PREFIX/share/applications/monodevelop.desktop /usr/share/applications/monodevelop-$MDVERSION.desktop
            sudo sed -e "s#^Exec=monodevelop#Exec=mono-$VERSION monodevelop#g" \
                     -e "s#^TryExec=MonoDevelop#TryExec=mono-$VERSION#g" \
                     -e "s#^Name=MonoDevelop#Name=MonoDevelop $MDVERSION#g" \
                     -i /usr/share/applications/monodevelop-$MDVERSION.desktop
        fi
        cd ..
        
    done

    if [ ! -z "$(which monodoc)" ]; then
        echo "$ECHO_PREFIX Generating monodoc search index..."
        monodoc --make-index > /dev/null
        monodoc --make-search-index > /dev/null
    fi
fi

# Exit message
echo ""
echo "$ECHO_PREFIX Your parallel environment is installed in $MONO_PREFIX"
echo "$ECHO_PREFIX To start a mono-$VERSION environment, run: source mono-$VERSION-environment"
echo "$ECHO_PREFIX To use mono-$VERSION to run a cli app, run: mono-$VERSION (eg mono-$VERSION mono -V)"
echo ""

#read -p "Done." inpVar
echo "Done"
