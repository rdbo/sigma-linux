# Guide - Sigma Linux
Quick guide for using Sigma Linux. Read the `README.md` file for installation steps.

For more guidance, go to the [Alpine Linux Wiki](https://wiki.alpinelinux.org/wiki/Main_Page).

## Hotkeys
- Super + Space -> Open application menu
- Super + Enter -> Open terminal
- Super + {1..9} -> Switch between workspaces
- Super + {H,J,K,L} -> Switch window focus
- Super + {Left, Down, Up, Right} -> Move floating window
- Super + Ctrl + {C, X} -> Close/kill focused window
- Super + {T, S, F} -> Change window mode to tiled/floating/fullscreen
- Super + Shift + B -> Lock screen
- Super + PrintScreen -> Take screenshot (gets saved at `$HOME/<date_time>.png`
- Super + Alt + R -> Restart session
- Super + Alt + Q -> Quit session
- (Vim) Ctrl - T -> Toggle NERDTree
For more hotkeys, read: /etc/skel/.config/sxhkd/sxhkdrc

## Programs
- Terminal Emulator: alacritty
- Browser: firefox
- Text Editor: vim
- Window Manager: bspwm
- Status Bar: polybar
- App Launcher: rofi
- Image Viewer: feh
- Network Daemon: iwd
- Screenshot Tool: maim
- Audio Server: pipewire
- Audio Manager: pavucontrol
- Screen Locker: i3lock
- Appearance Changer: lxappearance

## Connecting to Ethernet
With your ethernet cable plugged in, just make sure the interface is up and start `udhcpc` (replace `<iface>` with your interface, generally `eth0`):
```
ifconfig <iface> up
udhcpc -i <iface>
```

## Connecting to Wi-Fi
For the following commands, replace `<iface>` with your interface, generally `wlan0`.

Make sure your interface is up by running the command:
```
ifconfig <iface> up
```

To connect to Wi-Fi, use `iwctl`:
```
iwctl
```

Turn on network scanning:
```
station <iface> scan
```

List available networks:
```
station <iface> get-networks
```

Connect to network (replace `<nwname>` with the name of the network; use backslash `\` if it has spaces, e.g `My\ Network\ With\ Spaces`; enter the password afterwards if asked):
```
station <iface> connect <nwname>
```

Start the dhcp client:
```
udhcpc -i <iface>
```
