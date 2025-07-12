#!/usr/bin/env bash

show_help() {
cat << "Description"
##########################################################################
Installing a remote configuration file on LineageOS.

Run this script:
./cpremote.sh [remote configuration file]

Options:
[1] Getcfg - Get preinstalled remote.tabX file from device
[2] Install - Push remote.tabX to the device and reload the new cfg
[3] Debug - Enables debug to check remote functionality (Exit with Ctrl+C)
[4] Reboot - Device reboot, activates the changes permanently
[5] Exit - Set adbd as non root and stops the execution of the script
[6] Help - Show help for this script
##########################################################################
Description
}

input_cfg() {
    printf "%s\n" "Usage: $0 [remote configuration file]"
    printf "%s\n" "Configuration file => remote.cfg | remote.tab1 | remote.tab2 | remote.tab3"
}

if [[ $# -lt 1 ]]; then
    input_cfg
    exit
fi

cfg=(
    remote.cfg
    remote.tab1
    remote.tab2
    remote.tab3
)

if ! [[ "$1" == "${cfg[0]}" || "$1" == "${cfg[1]}" || "$1" == "${cfg[2]}" || "$1" == "${cfg[3]}" ]]; then
    printf "%s\n" "Wrong argument: $1"
    exit 1
fi

adb_run=
adb="`adb devices | sed '2!d'`"
if [[ -n "$adb" &&  ! -n "$adb_run" ]]; then
    root="adb root"
    adb_run="1"
else
    printf "%s\n" "ADB: Adb is not connected"
    exit 1
fi

if [[ "$1" == "${cfg[0]}" ]]; then
    reload="adb shell '/vendor/bin/remotecfg -c /data/vendor/remotecfg/${cfg[0]} -d'"
else
    reload="adb shell '/vendor/bin/remotecfg -c /data/vendor/remotecfg/${cfg[0]} -t /data/vendor/remotecfg/$1 -d'"
fi

pull="adb pull /vendor/etc/$1"
push="adb push $1 /data/vendor/remotecfg/"
chmod="adb shell 'chmod 644 /data/vendor/remotecfg/$1'"
cfgload="adb shell 'cat /sys/class/remote/amremote/map_tables'"
debug="adb shell 'dmesg -W | grep meson-remote'"
prop="adb shell 'setprop persist.vendor.amlogic.remotecfg.path /data/vendor/remotecfg'"
reboot="adb reboot"
unroot="adb unroot"

set_prop() {
    eval "$root"
    eval "$prop"
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
    set_prop
    ret="$?"
fi

if [[ "$ret" == '0' ]]; then
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
                   eval "$reboot"
                   exit ;;
                5) eval "$unroot"
                   exit ;;
                6) show_help
                   continue ;;
                *) printf "Unknown option: %s\n" "$REPLY"
                   continue ;;
            esac
        done
fi
