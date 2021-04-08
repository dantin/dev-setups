#!/usr/bin/env bash
set -e

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
	cp "${TARBALL}" "srt-source.tar.gz"
fi

tar -zxf "srt-source.tar.gz" --strip 1

# Source dependencies
sudo apt update
sudo apt upgrade -y
sudo apt install tcl -y
sudo apt install pkg-config -y
sudo apt install cmake -y
sudo apt install libssl-dev -y
sudo apt install build-essential -y

# Build it!
# --prefix=/usr/local

./configure --prefix=/usr/local
make

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
    # Install the version we just built.
    sudo make install
    echo "Hivision SRT has been installed!"
fi
