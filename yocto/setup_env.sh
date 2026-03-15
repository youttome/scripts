#!/usr/bin/env bash

# global build directory
YO_DIR=""

oe() {

    sudo apparmor_parser -R /etc/apparmor.d/unprivileged_userns

    source ../oe-init-* "$(pwd)"
    if [ $? -ne 0 ]; then
        echo "can't find oe-init script, make sure you are in the build directory and that the script exists."
        return 1
    else
        YO_DIR=$(pwd)
        echo "Yocto environment initialized at $YO_DIR"
        return 0
    fi
}

local.conf() {
    if [ -z "$YO_DIR" ]; then
        echo "Error: Yocto environment not initialized. Please run 'oe' first."
        return 1
    else
        code "$YO_DIR/conf/local.conf"
    fi
}

layer.bb() {
    if [ -z "$YO_DIR" ]; then
        echo "Error: Yocto environment not initialized. Please run 'oe' first."
        return 1
    else
        code "$YO_DIR/conf/bblayers.conf"
    fi
}

or() {

    if [ -z "$YO_DIR" ]; then
        echo "Error: Yocto environment not initialized. Please run 'oe' first."
        return 1
    fi

    if [ -z "$1" ]; then
        echo "Usage: or <recipe_name | show>"
        return 1
    elif [ "$1" = "show" ]; then

        code $(ls "$YO_DIR"/../meta*/recipes-*/*/*.bb \
                 "$YO_DIR"/../meta*/recipes-*/*/*.bbappend 2>/dev/null | fzf)

    else

        code $(ls "$YO_DIR"/../meta*/recipes-*/*/*.bb \
                 "$YO_DIR"/../meta*/recipes-*/*/*.bbappend 2>/dev/null \
                 | grep -i "$1" \
                 | rofi -dmenu -p "Select recipe to open:")

    fi
}

addmeta() {

    local layer
    layer=$(ls "$YO_DIR/.." | grep meta | rofi -dmenu -p "Add layer:")

    [ -n "$layer" ] && bitbake-layers add-layer "$YO_DIR/../$layer"
}

rmmeta() {

    local layer
    layer=$(bitbake-layers show-layers | awk '{print $1}' | grep meta | rofi -dmenu -p "Remove layer:")

    [ -n "$layer" ] && bitbake-layers remove-layer "$layer"
}