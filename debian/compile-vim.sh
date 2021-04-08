#!/usr/bin/env bash
set -e

VIM_CONENSED_VER="82"
BUILD_BY="David Ding"

# Gather command line options.
for i in "$@"; do
    case $i in
        -d=*|--build-dir=*)  # Specify the directory to use for the build
            BUILDDIR="${i#*=}"
            shift
            ;;
        -t=*|--tarball=*)  # Specify the source tarball to use for the build
            TARBALL="${i#*=}"
            shift
            ;;
        -skipinstall|--skip-install)  # Skip dpkg install
            SKIPINSTALL=YES
            ;;
        *)
            ;;
    esac
done

# Use the specified build directory, or create a unique temporary directory.
BUILDDIR=${BUILDDIR:-$(mktemp -d)}
echo "BUILD DIRECTORY USED: ${BUILDDIR}"
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

if [ -z ${TARBALL+x} ]; then
	# Download the source tarball from Github
	echo "tarball file path must be specified."
	exit 1
else
	echo "COPY TARBALL FROM: ${TARBALL}"
	cp "${TARBALL}" "vim-source.tar.gz"
fi

tar -zxf "vim-source.tar.gz" --strip 1

# Source dependencies
sudo apt update
sudo apt upgrade -y
sudo apt install libncurses5-dev -y
sudo apt install libgtk2.0-dev libatk1.0-dev libcairo2-dev -y
sudo apt install libx11-dev libxt-dev libxpm-dev -y
sudo apt install python2-dev python3-dev -y
sudo apt install ruby-dev -y
sudo apt install lua5.3 liblua5.3-dev -y
sudo apt install libperl-dev -y
sudo apt install libtcl8.6 tcl -y

# Build it!
# --prefix=/usr/local

# Make sure the directory is clean.
make distclean

./configure --prefix=/usr/local \
	--with-features=huge \
	--enable-multibyte \
	--enable-cscope=yes \
	--enable-perlinterp=yes \
	--enable-rubyinterp=yes \
	--enable-luainterp=yes \
	--enable-pythoninterp=yes \
	--with-python-config-dir=$(python-config --configdir) \
	--enable-python3interp=yes \
	--with-python3-config-dir=$(python3-config --configdir) \
	--enable-tclinterp=yes \
	--enable-gui=gtk2 \
	--enable-xim \
	--enable-fontset \
	--with-compiledby="${BUILD_BY}"
make VIMRUNTIMEDIR=/usr/local/share/vim/vim${VIM_CONENSED_VER}

if [[ "${SKIPTESTS}" != "YES" ]]; then
    make test
fi

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
    # If you have an apt managed version of git, remove it.
    if sudo apt remove --purge vim vim-runtime gvim vim-tiny vim-gui-common vim-nox -y; then
        sudo apt-get autoremove -y
        sudo apt-get autoclean
    fi
    # Install the version we just built.
    sudo make install

    sudo update-alternatives --install    /usr/bin/editor editor /usr/local/bin/vim 1
    sudo update-alternatives --set editor /usr/local/bin/vim
    sudo update-alternatives --install    /usr/bin/vi vi /usr/local/bin/vim 1
    sudo update-alternatives --set vi     /usr/local/bin/vim
    echo "Make sure to refresh your shell!"
    bash -c 'echo "$(which vim) ($(vim --version | head -1))"'
fi
