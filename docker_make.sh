#!/bin/bash -e
cd bin/web
    npm install
    npm run build
cd ../..
docker build -t rayhunter-devenv -f tools/devenv.dockerfile .
echo ' build!'
docker run --user $UID:$GID -v ./:/workdir -w /workdir -it rayhunter-devenv sh -c 'cargo build --profile firmware --target="armv7-unknown-linux-musleabihf" --bin rayhunter-daemon'
adb shell '/bin/rootshell -c "/etc/init.d/rayhunter_daemon stop"'
adb push target/armv7-unknown-linux-musleabihf/firmware/rayhunter-daemon /data/rayhunter/rayhunter-daemon
echo "rebooting the device..."
adb shell '/bin/rootshell -c "reboot"'
