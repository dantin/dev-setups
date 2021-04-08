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
	cp "${TARBALL}" "ffmpeg-source.tar.gz"
fi

tar -zxf "ffmpeg-source.tar.gz" --strip 1

# Source dependencies
sudo apt update
sudo apt install autoconf -y
sudo apt install automake -y
sudo apt install build-essential -y
sudo apt install cmake -y
sudo apt install libass-dev -y
sudo apt install libfreetype6-dev -y
sudo apt install libgnutls28-dev -y
sudo apt install libsdl2-dev -y
sudo apt install libtool -y
sudo apt install libva-dev -y
sudo apt install libvdpau-dev -y
sudo apt install libvorbis-dev -y
sudo apt install libxcb1-dev -y
sudo apt install libxcb-shm0-dev -y
sudo apt install libxcb-xfixes0-dev -y
sudo apt install zlib1g-dev -y
sudo apt install meson -y
sudo apt install ninja-build -y
sudo apt install pkg-config -y
sudo apt install texinfo -y
sudo apt install wget -y
sudo apt install yasm -y

# assembler used by some libraries.
sudo apt install nasm -y
# H.264 encoder, --enable-gpl --enable-libx264
sudo apt install libx264-dev -y
# H.265 encoder, --enable-gpl --enable-libx265
sudo apt install libx265-dev -y
sudo apt install libnuma-dev -y
# VP8/VP9 video codec, --enable-libvpx
sudo apt install libvpx-dev -y
# AAC audio encoder, --enable-libfdk-aac (and --enable-nonfree if you also include --enable-gpl)
sudo apt install libfdk-aac-dev -y
# MP3 audio encoder, --enable-libmp3lame
sudo apt install libmp3lame-dev -y
# Opus audio codec, --enable-libopus
sudo apt install libopus-dev -y
# AV1 decoder, --enable-libdav1d. NOT FOUND
#sudo apt install libdav1d-dev


# Build it!
# --prefix=/usr/local

./configure --prefix=/usr/local \
	--pkg-config-flags="--static" \
	--extra-cflags="-I$BUILDDIR/include" \
	--extra-ldflags="-L$BUILDDIR/lib" \
	--extra-libs="-lpthread -lm" \
	--ld="g++" \
	--enable-gpl \
	--enable-libass \
	--enable-libfdk-aac \
	--enable-libfreetype \
	--enable-libmp3lame \
	--enable-libopus \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libx265 \
    --enable-libsrt \
	--enable-nonfree
make

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
    # Install the version we just built.
    sudo make install
    echo "FFmpeg has been installed!"
fi
