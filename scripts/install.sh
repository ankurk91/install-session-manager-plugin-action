#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Keep this in sync with the `path:` of the cache step in action.yaml.
CACHE_ROOT="$HOME/.cache/aws-ssm"
# Scoped per version so a persistent HOME on a self-hosted runner cannot serve
# the installer for a different version than the one that was asked for.
CACHE_PATH="$CACHE_ROOT/$VERSION"

echo "::debug::CACHE_ENABLED=$CACHE_ENABLED"
echo "::debug::CACHE_HIT=$CACHE_HIT"
echo "::debug::CACHE_PATH=$CACHE_PATH"
echo "::debug::OS=$OS"
echo "::debug::ARCH=$ARCH"
echo "::debug::VERSION=$VERSION"
echo "::debug::URL_SEGMENT=$URL_SEGMENT"

# Drop installers for other versions so the saved cache holds exactly one.
if [ -d "$CACHE_ROOT" ]; then
  find "$CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name "$VERSION" -exec rm -rf {} +
fi

mkdir -p "$CACHE_PATH"
cd "$CACHE_PATH"

REMOTE_URL_BASE="https://s3.amazonaws.com/session-manager-downloads/plugin"

if [ "$OS" = "ubuntu" ]; then
  INSTALLER="session-manager-plugin.deb"
  URL="${REMOTE_URL_BASE}/${URL_SEGMENT}/ubuntu_${ARCH}/${INSTALLER}"
else
  INSTALLER="session-manager-plugin.rpm"
  URL="${REMOTE_URL_BASE}/${URL_SEGMENT}/linux_${ARCH}/${INSTALLER}"
fi

download_plugin() {
  echo "Downloading $OS/$ARCH version $VERSION..."

  # S3 answers 403 rather than 404 for a missing key, so a typo in the version
  # looks like a permissions error. Say what was actually requested.
  if ! curl -sfL \
    --retry 3 \
    --retry-delay 5 \
    --connect-timeout 15 \
    --max-time 60 \
    -O "$URL"; then
    echo "::error::Failed to download $URL"
    echo "::error::If you pinned a version, check that $VERSION exists upstream."
    exit 1
  fi
}

install_plugin() {
  echo "Installing plugin..."
  if [ "$OS" = "ubuntu" ]; then
    sudo apt-get install -qq -y --no-install-recommends "./${INSTALLER}"
  else
    sudo dnf install -y -q "./${INSTALLER}"
  fi
}

if [ "$CACHE_ENABLED" != "true" ]; then
  # Caching is off, so never reuse a leftover file from a previous run on a
  # self-hosted runner with a persistent HOME.
  rm -f "$INSTALLER"
  download_plugin
elif [ ! -f "$INSTALLER" ]; then
  # Trust the file, not the cache-hit flag: a restored cache can be stale or
  # hold the installer for a different distro family.
  if [ "$CACHE_HIT" = "true" ]; then
    echo "::warning::Cache hit but ${INSTALLER} is missing, downloading it again."
  fi
  download_plugin
fi

install_plugin

session-manager-plugin --version
