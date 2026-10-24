# Container Monitor

A Plasma 6 widget that shows your **Podman** and **Docker** containers and their logs, right on the desktop or in a panel popup. It can watch this computer and any number of servers over SSH.

- CPU and memory per container; start and stop button
- Logs with colored levels, one timestamp per multi-line entry (stack traces stay together), time zone and format options
- Several sources in one widget, each with its own refresh rates
- Resizable panel popup that remembers its size

## Requirements

- KDE Plasma 6
- `podman` or `docker` on this computer and/or on each server
- For servers: `ssh` with key-based login (see [Servers](#servers))

## Install

**From the KDE Store:** right-click the desktop or a panel, *Add Widgets…* → *Get New Widgets…* → search for "Container Monitor" ([store page](https://www.opendesktop.org/p/2380230/)).

**From a file** (download the `.plasmoid` from the [Releases](../../releases) page):

```sh
kpackagetool6 -t Plasma/Applet -i container-monitor-<version>.plasmoid    # install
kpackagetool6 -t Plasma/Applet -u container-monitor-<version>.plasmoid    # update
kpackagetool6 -t Plasma/Applet -r io.github.uladzislautsimankou.containermonitor   # remove
```

If the widget looks outdated after an update, restart the shell: `systemctl --user restart plasma-plasmashell`

Then right-click the desktop or a panel → *Add Widgets…* → **Container Monitor**.

## Use

Containers on this computer show up right away (Podman by default; pick Docker in *General*). Click a container to see its logs below the list.

### Servers

Open the widget settings → **Servers** → *Add server*.

- **SSH host:** an alias from `~/.ssh/config` (for example `vps`) or `user@host`.
- The widget never asks for a password. Use a key that is loaded in `ssh-agent` or has no passphrase.
- Connect to the server once from a terminal to accept its host key.
- Check that this works without any prompt: `ssh -o BatchMode=yes vps true`
- Podman or Docker must be installed on the server. For Docker, the user needs to be in the `docker` group.

The widget reuses one SSH connection per server, so polling does not flood the server with logins.

## License

[MIT](LICENSE)

## Credits

Panel icon: Uicons by [Flaticon](https://www.flaticon.com/uicons).
