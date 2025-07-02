#!/usr/bin/env bash

show_help() {
cat << "Description"
##########################################################################
Installing a remote configuration file on LineageOS.

Run this script:
./cpremote.sh remote.tabX

Options:
[1] Getcfg - Get preinstalled remote.tabX file from TV-BOX
[2] Install - Copy remote.tabX to the device and reload the new cfg
[3] Debug - Enables debug to check remote functionality (Exit with Ctrl+C)
[4] Reboot - TV-BOX reboot, activates the changes permanently
[5] Exit - Stops the execution of this script
[6] Help - Show help for this script
##########################################################################
Description
}

check_file() {
    printf "%s\n" "Usage: $0 [remote configuration file]"
    printf "%s\n" "Configuration file => remote.tab1 | remote.tab2 | remote.tab3"
}

if [[ $# -lt 1 ]]; then
    check_file
    exit
fi

cfg=(
    remote.tab1
    remote.tab2
    remote.tab3
)

if ! [[ "$1" == "${cfg[0]}" || "$1" == "${cfg[1]}" || "$1" == "${cfg[2]}" ]]; then
    printf "%s\n" "Wrong argument: $1"
    exit 1
fi

adb_run=
adb="`adb devices | sed '2!d'`"
if [[ -n "$adb" &&  ! -n "$adb_run" ]]; then
    root="adb root"
    remount="adb remount"
    overlay_fs="adb remount -R"
    wait_for_dev="adb wait-for-device"
    adb_run="1"
else
    printf "%s\n" "ADB: Adb is not connected"
    exit 1
fi

pull="adb pull /vendor/etc/$1"
push="adb push $1 /vendor/etc/"
chmod="adb shell 'chmod 00644 /vendor/etc/$1'"
cfgload="adb shell 'cat /sys/class/remote/amremote/map_tables'"
reload="adb shell '/vendor/bin/remotecfg -c /vendor/etc/remote.cfg -t /vendor/etc/$1 -d'"
debug="adb shell 'dmesg -W | grep meson-remote'"
reboot="adb reboot"

set_overlay_fs() {
    eval "$root"
    eval "$overlay_fs"
    eval "$wait_for_dev"
}

get_access() {
    eval "$root"
    eval "$remount"
}

cp_cfg() {
    eval "$push"
    eval "$chmod"
}

trap 'func_ctrl_c' SIGINT

func_ctrl_c() {
    printf "%s\n" "pressed Ctrl+C"
    set_abort
}

debug() {
    eval "$debug"
}

set_abort() {
    abort="1"
}

if [[ -n "$adb_run" ]]; then
    set_overlay_fs
    ret="$?"
fi

if [[ "$ret" == '0' ]]; then
    get_access
    fs_overlays="true"
    printf "%s\n" "OverlayFS_is_set=$fs_overlays"
fi

if [[ -n "$fs_overlays" ]]; then
    printf "\n%s\n" "Selection menu:"
    printf "===============\n"
    printf "%s\n" "[1] getcfg"
    printf "%s\n" "[2] install"
    printf "%s\n" "[3] debug"
    printf "%s\n" "[4] reboot"
    printf "%s\n" "[5] exit"
    printf "%s\n" "[6] help"
    printf "\n"
    while true; do
        read -r -p "Choose opt: "
            case "$REPLY" in
                1) if [[ -f "$1" ]]; then
                       printf "%s\n" "$1 already exists"
                   else
                       eval "$pull"
                   fi
                   continue ;;
                2) cp_cfg
                   eval "$reload"
                   printf "\n"
                   continue ;;
                3) printf "%s\n" "Loadet cfgs:"
                   eval "$cfgload"
                   printf "\n%s\n" "DEBUG: Press any key on yor remote control"
                   debug; [[ "$abort" == '1' ]] && continue ;;
                4) printf "\n%s\n" "Rebooting device.."
                   eval "$reboot" ;;
                5) exit ;;
                6) show_help
                   continue ;;
                *) printf "Unknown option: %s\n" "$REPLY"
                   continue ;;
            esac
        break
    done
fi
