FROM semaphoreui/semaphore:v2.16.45-powershell7.5.0

# Based on https://github.com/semaphoreui/semaphore/issues/2682#issuecomment-2605627575

USER root

# packer requried xorriso for building cloudinit images
RUN apk add --no-cache -U xorriso

# we need packer for running packer builds
RUN set -eux; \
    PACKER_VERSION="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer \
      | jq -r '.current_version')"; \
    echo "Latest Packer version: ${PACKER_VERSION}"; \
    mkdir -p /opt/packer; \
    cd /tmp; \
    curl -sSLo packer.zip \
      "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip"; \
    unzip packer.zip; \
    rm packer.zip; \
    # Put the binary under /opt/packer/<version>
    mkdir -p "/opt/packer/${PACKER_VERSION}"; \
    mv packer "/opt/packer/${PACKER_VERSION}/packer"; \
    chmod +x "/opt/packer/${PACKER_VERSION}/packer"; \
    # Link it into /usr/local/bin
    ln -s "/opt/packer/${PACKER_VERSION}/packer" /usr/local/bin/packer

USER 1001
