#!/bin/bash -e
pushd bin/web
    npm install
    npm run build
popd
cargo build --profile firmware --bin rayhunter-daemon --target="armv7-unknown-linux-musleabihf" #--features debug
adb shell '/bin/rootshell -c "/etc/init.d/rayhunter_daemon stop"'
adb shell '/bin/rootshell -c "mkdir -p /data/rayhunter/gps-data"'
adb push target/armv7-unknown-linux-musleabihf/firmware/rayhunter-daemon /data/rayhunter/rayhunter-daemon
adb shell '/bin/rootshell -c "chmod +x /data/rayhunter/rayhunter-daemon"'
echo "rebooting the device..."
adb shell '/bin/rootshell -c "reboot"'
