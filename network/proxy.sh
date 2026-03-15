#!/usr/bin/env bash
#
# -----------------------------------------------------------------------------
# Proxy Management Utility
# -----------------------------------------------------------------------------
# Description:
#   This script manages system-wide proxy configuration for development
#   environments. It configures proxy settings for multiple tools commonly
#   used in software development and embedded Linux workflows.
#
#   Supported tools:
#       - Environment variables (http_proxy, https_proxy)
#       - APT package manager
#       - Snap package manager
#       - Git
#       - Docker
#       - GNOME system proxy
#
# Usage:
#       proxy set <ip>    -> Configure proxy
#       proxy unset       -> Remove proxy configuration
#       proxy show        -> Display current proxy settings
#
# Example:
#       proxy set 10.0.0.5
#       proxy unset
#       proxy show
#
# Notes:
#   - Default port is set to 44355
#   - Docker service will be restarted after proxy configuration changes
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Configuration Files
# -----------------------------------------------------------------------------

# APT proxy configuration file
PROXY_FILE="/etc/apt/apt.conf.d/95proxiesC"

# Docker proxy configuration directory
DOCKER_DIR="/etc/systemd/system/docker.service.d"

# Docker proxy configuration file
DOCKER_FILE="$DOCKER_DIR/http-proxy.conf"


# -----------------------------------------------------------------------------
# Proxy management function
# -----------------------------------------------------------------------------

proxy() {

case "$1" in

# -----------------------------------------------------------------------------
# SET PROXY
# -----------------------------------------------------------------------------

set|s)

    ip="$2"
    port="44355"

    # If IP not provided, read it from GNOME proxy settings
    if [ -z "$ip" ]; then
        ip=$(gsettings get org.gnome.system.proxy.http host | tr -d \')
    fi

    echo "Configuring proxy: http://$ip:$port"

    # -------------------------------------------------------------------------
    # Configure GNOME system proxy
    # -------------------------------------------------------------------------

    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings set org.gnome.system.proxy.http host "$ip"
    gsettings set org.gnome.system.proxy.https host "$ip"

    # -------------------------------------------------------------------------
    # Export environment variables (current shell session)
    # -------------------------------------------------------------------------

    export http_proxy="http://$ip:$port"
    export https_proxy="http://$ip:$port"
    export no_proxy="127.0.0.1,localhost"

    # -------------------------------------------------------------------------
    # Configure APT proxy
    # -------------------------------------------------------------------------

    sudo bash -c "cat > $PROXY_FILE" <<EOF
Acquire {
  HTTP::proxy  "http://$ip:$port/";
  HTTPS::proxy "http://$ip:$port/";
}
EOF

    # -------------------------------------------------------------------------
    # Configure Snap proxy
    # -------------------------------------------------------------------------

    sudo snap set system proxy.http="http://$ip:$port/"
    sudo snap set system proxy.https="http://$ip:$port/"

    # -------------------------------------------------------------------------
    # Configure Git proxy
    # -------------------------------------------------------------------------

    git config --global http.proxy "http://$ip:$port/"
    git config --global https.proxy "http://$ip:$port/"

    # -------------------------------------------------------------------------
    # Configure Docker proxy
    # -------------------------------------------------------------------------

    sudo mkdir -p "$DOCKER_DIR"

    sudo bash -c "cat > $DOCKER_FILE" <<EOF
[Service]
Environment="HTTP_PROXY=http://$ip:$port"
Environment="HTTPS_PROXY=http://$ip:$port"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

    # Reload systemd and restart Docker to apply new proxy configuration
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo "Proxy configured successfully"

;;

# -----------------------------------------------------------------------------
# UNSET PROXY
# -----------------------------------------------------------------------------

unset|un)

    echo "Removing proxy configuration..."

    # Remove environment variables
    unset http_proxy https_proxy

    # Remove APT proxy file
    sudo rm -f "$PROXY_FILE"

    # Remove Docker proxy configuration
    sudo rm -f "$DOCKER_FILE"

    # Remove Snap proxy settings
    sudo snap unset system proxy.http
    sudo snap unset system proxy.https

    # Remove Git proxy configuration
    git config --global --unset http.proxy
    git config --global --unset https.proxy

    # Reload systemd and restart Docker
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo "Proxy configuration removed"

;;

# -----------------------------------------------------------------------------
# SHOW CURRENT PROXY SETTINGS
# -----------------------------------------------------------------------------

show)

    echo "------------------------------"
    echo "Environment Proxy Variables"
    echo "------------------------------"
    env | grep -i proxy

    echo
    echo "------------------------------"
    echo "APT Proxy Configuration"
    echo "------------------------------"
    cat "$PROXY_FILE" 2>/dev/null || echo "No APT proxy configured"

    echo
    echo "------------------------------"
    echo "Snap Proxy Configuration"
    echo "------------------------------"
    snap get system proxy

;;

# -----------------------------------------------------------------------------
# INVALID COMMAND
# -----------------------------------------------------------------------------

*)

    echo "Usage:"
    echo "  proxy set <ip>   Configure proxy"
    echo "  proxy unset      Remove proxy"
    echo "  proxy show       Display proxy settings"

;;

esac
}

# -----------------------------------------------------------------------------
# Script entry point
# -----------------------------------------------------------------------------

proxy "$@"