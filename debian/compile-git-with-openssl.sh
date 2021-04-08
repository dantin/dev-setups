#!/usr/bin/env bash
set -e

# Gather command line options.
for i in "$@"; do
    case $i in
        -skiptests|--skip-tests)  # Skip test portion of the build
            SKIPTESTS=YES
            ;;
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
	sudo apt update
	sudo apt install curl -y
	git_tarball_url="https://www.github.com$(curl 'https://github.com/git/git/tags' | grep -o "/git/git/archive/v2\..*\.tar\.gz" | sort -r | head -1 | tr -d '\n')"
	echo "DOWNLOADING FROM: ${git_tarball_url}"
	curl -L --retry 5 "${git_tarball_url}" --output "git-source.tar.gz"
else
	echo "COPY TARBALL FROM: ${TARBALL}"
	cp "${TARBALL}" "git-source.tar.gz"
fi

tar -zxf "git-source.tar.gz" --strip 1

# Source dependencies
# Don't use gnutls, this is the problem package.
sudo apt remove --purge libcurl4-gnutls-dev -y || true
sudo apt-get autoremove -y
sudo apt-get autoclean

sudo apt install build-essential autoconf dh-autoreconf -y
sudo apt install libcurl4-openssl-dev tcl-dev gettext asciidoc -y
sudo apt install libexpat1-dev zlib1g-dev -y

# Build it!
make configure
# --prefix=/usr/local
# --with-openssl
./configure --prefix=/usr/local --with-openssl
make
if [[ "${SKIPTESTS}" != "YES" ]]; then
    make test
fi

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
    # If you have an apt managed version of git, remove it.
    if sudo apt remove --purge git -y; then
        sudo apt-get autoremove -y
        sudo apt-get autoclean
    fi
    # Install the version we just built.
    sudo make install
    echo "Make sure to refresh your shell!"
    bash -c 'echo "$(which git) ($(git --version))"'
fi
