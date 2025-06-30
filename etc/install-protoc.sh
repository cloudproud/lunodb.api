#!/usr/bin/env bash
set -e

VERSION=30.1
OS=$(uname | awk '{print tolower($0)}')

case "$OS" in
  darwin*)  OS="osx-universal_binary" ;; 
  linux*)   OS="linux-x86_64" ;;
  msys*)    OS="win64" ;;
  cygwin*)  OS="win64" ;;
  *)        echo "unknown operating system: $OS"; exit 1 ;;
esac

RELEASE=protoc-$VERSION-$OS.zip
DOWNLOAD=https://github.com/protocolbuffers/protobuf/releases/download/v$VERSION/$RELEASE

curl -LOs $DOWNLOAD
unzip -qq $RELEASE -d protobuf
mv protobuf/bin/protoc $1/
rm -rf protobuf $RELEASE