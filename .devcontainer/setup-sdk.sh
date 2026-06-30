#!/usr/bin/env bash
# Runs once after container creation (devcontainer postCreateCommand).
#
# Prerequisites — set these as devcontainer secrets or environment variables
# before opening the container for the first time:
#
#   GARMIN_USERNAME      your Garmin account e-mail
#   GARMIN_PASSWORD      your Garmin account password
#   CIQ_AGREEMENT_HASH   acceptance hash — obtain it once on your host machine:
#                          connect-iq-sdk-manager agreement view
#                        then copy the hash from the output.
#   CIQ_SDK_VERSION      (optional) SDK version to install, e.g. "6.4.2"
#                        Leave unset to install the latest SDK >= 6.2.2.
#
# The SDK is stored in the named volume garmin-ciq-sdk (~/.Garmin inside the
# container), so this script only re-runs if you delete that volume.

set -euo pipefail

# Semver-range; picks the newest STABLE SDK that satisfies it.
# ">=4.2.0" is broad on purpose so it always matches the current Garmin feed
# (which no longer lists old 6.x SDKs). Our app's minApiLevel is 3.4.0, so a
# newer SDK builds it fine. Pin an exact version here once you know what installs.
SDK_VERSION="${CIQ_SDK_VERSION:->=4.2.0}"

if [ -L /opt/connectiq-current ]; then
    echo "==> SDK already installed, skipping setup."
    echo "    Delete the 'garmin-ciq-sdk' volume to force re-installation."
    exit 0
fi

echo "==> Accepting Garmin license agreement (hash: ${CIQ_AGREEMENT_HASH:0:8}...)"
connect-iq-sdk-manager agreement accept --agreement-hash="${CIQ_AGREEMENT_HASH}"

# login reads GARMIN_USERNAME / GARMIN_PASSWORD from the environment
# (passed in via --env-file in devcontainer.json). No flags here, so the
# password never appears in the container's process list.
echo "==> Logging in to Garmin Connect..."
if ! connect-iq-sdk-manager login; then
    echo ""
    echo "!! Automated login FAILED."
    echo "!! Most likely cause: two-factor authentication (2FA) on your Garmin account,"
    echo "!! or wrong credentials in .devcontainer/devcontainer.env."
    echo ""
    echo "!! What to do:"
    echo "!!   - Wrong credentials? Fix devcontainer.env, then re-run: bash .devcontainer/setup-sdk.sh"
    echo "!!   - 2FA enabled?       Either temporarily disable 2FA in your Garmin"
    echo "!!                        account security settings and re-run, or download"
    echo "!!                        the SDK manually (ask for the manual-download steps)."
    exit 1
fi

echo "==> Installing CIQ SDK (${SDK_VERSION})..."
connect-iq-sdk-manager sdk set "${SDK_VERSION}"

echo "==> Downloading device definitions from manifest.xml..."
connect-iq-sdk-manager device download --manifest=/workspace/manifest.xml

SDK_PATH="$(connect-iq-sdk-manager sdk current-path)"
ln -sfn "${SDK_PATH}" /opt/connectiq-current

echo ""
echo "==> Setup complete."
echo "    SDK: ${SDK_PATH}"
echo "    Symlink: /opt/connectiq-current"
echo ""
echo "    To build: bash scripts/build.sh"
echo "    To generate developer key (first time): bash scripts/gen-key.sh"
