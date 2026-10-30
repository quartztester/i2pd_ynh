#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Pinned per-arch GitHub .deb: upstream apt repo unreliable, Debian's i2pd much older; all deb deps come from Debian main.
I2PD_DEB_VERSION="3.0.0-1bookworm1"
I2PD_DEB_TAG="3.0.0"
I2PD_DEB_URL_BASE="https://github.com/PurpleI2P/i2pd/releases/download/${I2PD_DEB_TAG}"

# sha256 of i2pd_${I2PD_DEB_VERSION}_<arch>.deb, per dpkg architecture
I2PD_DEB_SHA256_amd64="f314659ac70617a9cdf1424417b099c2be7022b800f364ef5699233f39b2929a"
I2PD_DEB_SHA256_arm64="63e1c085e97151ab0b5848807e4cc3bcedf85951b3e821652ea86801a5d82c65"
I2PD_DEB_SHA256_armhf="220a11d723e07d3293910e7ed76b3c292ecc3b961024f4f76ee9ddfa8918a812"
I2PD_DEB_SHA256_i386="214bed768f15391c9e4ed253598875931cebb9d0d32379d264e476725174c55d"

# AppArmor grants the i2pd user only these deb-native paths — do not relocate.
I2PD_CONFD="/etc/i2pd"
I2PD_DATA_DIR="/var/lib/i2pd"
I2PD_UNIT="i2pd"

#=================================================
# PERSONAL HELPERS
#=================================================

# dpkg --force-confold keeps locally modified conffiles, so /etc/i2pd survives upgrades.
install_i2pd_deb() {
    local arch
    arch=$(dpkg --print-architecture)

    local sha256_var="I2PD_DEB_SHA256_${arch}"
    local expected="${!sha256_var}"
    if [ -z "$expected" ]; then
        ynh_die "No pinned i2pd deb for architecture ${arch}."
    fi

    local deb="/tmp/i2pd_${I2PD_DEB_VERSION}_${arch}.deb"

    curl -fSL --retry 3 -o "$deb" \
        "${I2PD_DEB_URL_BASE}/i2pd_${I2PD_DEB_VERSION}_${arch}.deb" \
        || ynh_die "Unable to download the i2pd ${I2PD_DEB_VERSION} deb for ${arch}."

    echo "${expected}  ${deb}" | sha256sum --check --strict - \
        || ynh_die "i2pd deb checksum mismatch for ${arch} — refusing to install."

    DEBIAN_FRONTEND=noninteractive apt-get -y \
        -o Dpkg::Options::="--force-confold" \
        install --no-install-recommends "$deb" \
        || ynh_die "Failed to install the i2pd deb."

    rm -f "$deb"
}

# Fails fast on bound TCP ports: java_i2p coexistence — both routers share the upstream proxy/SAM defaults.
ynh_check_tcp_port_free() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        ynh_die "'$port' is not a valid port number."
    fi

    if ss -H -ltn "( sport = :$port )" | grep -q .; then
        ynh_die "TCP port $port is already in use on this server (for example by the java_i2p app) — pick another port."
    fi
}
