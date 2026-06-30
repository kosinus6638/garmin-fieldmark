#!/usr/bin/env bash
# Generates the RSA developer signing key required for sideloading to Garmin devices.
# Run ONCE on your local machine (not inside the container).
# The keys/ directory is gitignored — back it up securely.
#
# Losing your developer key means you cannot update your sideloaded app.
# If you lose it, uninstall the app from the device and sideload fresh with a new key.

set -euo pipefail

mkdir -p keys

if [ -f keys/developer_key.der ]; then
    echo "Key already exists at keys/developer_key.der — nothing to do."
    exit 0
fi

echo "==> Generating 4096-bit RSA developer key..."
openssl genrsa -out keys/developer_key 4096

echo "==> Converting to DER format (required by monkeyc)..."
openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in keys/developer_key -out keys/developer_key.der -nocrypt

echo ""
echo "==> Keys created:"
echo "    keys/developer_key     (PEM — backup copy)"
echo "    keys/developer_key.der (DER — used for signing builds)"
echo ""
echo "    Back these up somewhere safe. They are gitignored."
