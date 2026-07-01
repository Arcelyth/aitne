#!/bin/bash
set -e

REPO="Arcelyth/aitne"
BINARY_NAME="aitne"
INSTALL_DIR="/usr/local/bin"

OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS_TYPE" in
  darwin) OS="macos" ;;
  linux)  OS="linux" ;;
  *)
    echo "Error: Not support: $OS_TYPE"
    exit 1
    ;;
esac

ARCH_TYPE=$(uname -m)
case "$ARCH_TYPE" in
  x86_64|amd64) ARCH="x64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)
    echo "Error: Not support: $ARCH_TYPE"
    exit 1
    ;;
esac

ASSET_NAME="${BINARY_NAME}-${OS}-${ARCH}"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"

echo "==> Downloading from github..."

TMP_FILE=$(mktemp)

if ! curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"; then
  echo "Error: Failed to Download"
  echo "$DOWNLOAD_URL"
  rm -f "$TMP_FILE"
  exit 1
fi

echo "==> Install to ${INSTALL_DIR}/${BINARY_NAME}..."

if [ -w "$INSTALL_DIR" ]; then
  mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
else
  echo "🔒 ${INSTALL_DIR} Need permission password:"
  sudo mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
  sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
fi

if [ -n "$BASH_VERSION" ]; then
  hash -r
elif [ -n "$ZSH_VERSION" ]; then
  rehash
fi

echo "Done."

