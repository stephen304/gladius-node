#!/bin/sh

$PROJECT_NAME="gladius-node"
$INSTALL_BIN="/usr/bin/"

fail() {
  echo "$1"
  exit 1
}


# Architecture detection
initArch() {
  ARCH=$(uname -m)
  case $ARCH in
    armv5*) ARCH="armv5" ;;
    armv6*) ARCH="armv6" ;;
    armv7*) ARCH="armv7" ;;
    aarch64) ARCH="arm64" ;;
    x86) ARCH="386" ;;
    x86_64) ARCH="amd64" ;;
    i686) ARCH="386" ;;
    i386) ARCH="386" ;;
  esac
  echo "ARCH=$ARCH"
}

# OS Detection
initOS() {
  OS=$(echo `uname`|tr '[:upper:]' '[:lower:]')

  case "$OS" in
      # Minimalist GNU for Windows
    mingw*) OS='windows' ;;
    msys*) OS='windows' ;;
  esac
  echo "OS=$OS"
}

# Pick wget or curl
initDownloadTool() {
  if type "curl" > /dev/null; then
    DOWNLOAD_TOOL="curl"
  elif type "wget" > /dev/null; then
    DOWNLOAD_TOOL="wget"
  else
    fail "You need curl or wget as download tool. Please install it first before continue"
  fi
  echo "Using $DOWNLOAD_TOOL as download tool"
}

getLatest(){
  # Get the latest release of the gladius-node
  TAG=$(curl --silent "$RepoLink" | # Get latest release from GitHub api
    grep '"tag_name":' |               # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'       # Pluck JSON value
  )
}

getFile() {
  local url="$1"
  local filePath="$2"
  if [ "$DOWNLOAD_TOOL" = "curl" ]; then
    httpStatusCode=$(curl -s -w '%{http_code}' -L "$url" -o "$filePath")
  elif [ "$DOWNLOAD_TOOL" = "wget" ]; then
    body=$(wget --server-response --content-on-error -q -O "$filePath" "$url")
    httpStatusCode=$(cat $tmpFile | awk '/^  HTTP/{print $2}')
  fi
  echo "$httpStatusCode"
}

downloadFile() {
  # Build URL
  GLADIUS_DIST="gladius-$TAG-$OS-$ARCH.tar.gz"
  echo "GLADIUS_DIST=$GLADIUS_DIST"
  DOWNLOAD_URL="https://github.com/gladiusio/$PROJECT_NAME/releases/download/$TAG/$GLADIUS_DIST"

  # Create some temporary files
  GLADIUS_TMP_FILE="/tmp/$GLADIUS_DIST"
  echo "Downloading $DOWNLOAD_URL"
  httpStatusCode=$(getFile "$DOWNLOAD_URL" "$GLADIUS_TMP_FILE")
  if [ "$httpStatusCode" -ne 200 ]; then
    echo "Did not find a release for your system: $OS $ARCH"
    fail "You can build one for your system with the instructions here: https://github.com/gladiusio/gladius-node"
  else
    echo "Downloading $DOWNLOAD_URL"
    getFile "$DOWNLOAD_URL" "$GLIDE_TMP_FILE"
  fi
}

installFile() {
	GLADIUS_TEMP="/tmp/$PROJECT_NAME"
	mkdir -p "$GLADIUS_TEMP"
	tar xf "$GLADIUS_TMP_FILE" -C "$GLADIUS_TEMP"
	GLADIUS_TMP_BIN="$GLADIUS_TEMP/$OS-$ARCH/$PROJECT_NAME"
	sudo cp "$GLIDE_TMP_BIN" "$INSTALL_BIN"
	rm -rf $GLADIUS_TEMP
	rm -f $GLADIUS_TMP_FILE
}


initArch
initOS
getLatest
initDownloadTool
downloadFile
installFile