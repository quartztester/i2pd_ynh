#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# i2pd ships as one plain .deb per architecture on its upstream GitHub
# releases (the upstream apt repository is not reliably reachable and
# Debian's own i2pd is much older on trixie+). All library dependencies
# of the deb come from Debian main, so no extra repository is needed.
# CAVEAT (verified 2026-11-01): upstream's 3.0.0 "bookworm" deb is
# mislabeled — it links trixie's libboost (1.81), unmet on bookworm
# (1.74), so on bookworm we install Debian's own i2pd instead.
I2PD_DEB_VERSION="3.0.0-1trixie1"
I2PD_DEB_TAG="3.0.0"
I2PD_DEB_URL_BASE="https://github.com/PurpleI2P/i2pd/releases/download/${I2PD_DEB_TAG}"

# sha256 of i2pd_${I2PD_DEB_VERSION}_<arch>.deb, per dpkg architecture
I2PD_DEB_SHA256_amd64="c48c9e2e44fb67e9c650b01225ccf816d8b2cecf3246a5112ccdcf5a6e4fbe70"
I2PD_DEB_SHA256_arm64="8ea84cab7928602fcaa722e761cc4b51d7e5f826d92b4e2ee384baa63a43f173"
I2PD_DEB_SHA256_armhf="3f6345e80e3ad4752f7579d506eb85fe2270e4dd0d8b908c0c47283d9f5cf723"
I2PD_DEB_SHA256_i386="73d57f330e16c0c84ec3c36869cb5c4f1f2a29fd85fe3efb01c783c6eb3512a6"

# Native paths of the deb: the i2pd AppArmor profile only grants the
# i2pd user access to these, so the app must not relocate them.
I2PD_CONFD="/etc/i2pd"
I2PD_DATA_DIR="/var/lib/i2pd"
I2PD_UNIT="i2pd"

#=================================================
# PERSONAL HELPERS
#=================================================

# Install i2pd: Debian's own package on bookworm (see the caveat above),
# otherwise the pinned upstream deb for this machine's architecture,
# verifying its sha256 first. dpkg keeps any locally modified conffile
# (--force-confold), so /etc/i2pd survives upgrades.
install_i2pd_deb() {
    local codename
    codename=$(. /etc/os-release && echo "${VERSION_CODENAME:-}")

    # package_check base images ship pruned apt lists; refresh before
    # either path (also resolves the deb's deps on trixie)
    apt-get update

    if [ "$codename" = "bookworm" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get -y \
            -o Dpkg::Options::="--force-confold" \
            install --no-install-recommends i2pd \
            || ynh_die "Failed to install Debian's i2pd package."
        return 0
    fi

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

# Fail fast when a TCP port is already bound on this server — most
# relevant when the Java I2P router (java_i2p app) runs side by side,
# since both routers share the same upstream proxy/SAM defaults.
ynh_check_tcp_port_free() {
    local port="$1"

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        ynh_die "'$port' is not a valid port number."
    fi

    if ss -H -ltn "( sport = :$port )" | grep -q .; then
        ynh_die "TCP port $port is already in use on this server (for example by the java_i2p app) — pick another port."
    fi
}

# The webconsole only binds after router-key generation, which can take
# minutes on a loaded box — CI (and impatient admins) curl the URL the
# moment install finishes, so wait for the socket before returning.
ynh_wait_webconsole() {
    local port="${1:-$port}"
    for _ in $(seq 1 60); do
        ss -H -ltn "( sport = :$port )" | grep -q . && return 0
        sleep 2
    done
    ynh_die "i2pd's webconsole did not come up on port $port within 120s."
}
