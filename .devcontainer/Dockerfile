FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    curl \
    ca-certificates \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# connect-iq-sdk-manager-cli: manages SDK downloads (github.com/lindell/connect-iq-sdk-manager-cli)
ARG CIQMGR_VERSION=0.8.4
RUN curl -fsSL \
    "https://github.com/lindell/connect-iq-sdk-manager-cli/releases/download/v${CIQMGR_VERSION}/connect-iq-sdk-manager-cli_${CIQMGR_VERSION}_Linux_x86_64.tar.gz" \
    -o /tmp/ciqmgr.tar.gz \
    && tar -xzf /tmp/ciqmgr.tar.gz -C /usr/local/bin connect-iq-sdk-manager \
    && rm /tmp/ciqmgr.tar.gz

# SDK itself is NOT baked into the image — it requires Garmin login credentials.
# It is downloaded once via postCreateCommand and stored in a named volume.
# See .devcontainer/setup-sdk.sh

WORKDIR /workspace
