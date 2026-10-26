# i2pd — post-install

## The first minutes

On first start i2pd generates a fresh router identity, reseeds from the network and warms up its exploratory tunnels — expect **2–10 minutes** before eepsites resolve. Progress:

```
grep -iE 'reseed|network status|tunnels' /var/log/i2pd/i2pd.log | tail
```

…or just open the webconsole (link below) and watch the status line go from *Testing* to *OK*.

## Where things are

- **Webconsole**: `https://<domain>/` — behind the YunoHost SSO portal. Adjust who can see it with `yunohost user permission update i2pd.main --add/--remove ...`.
- **HTTP proxy** (eepsites): `curl -x http://127.0.0.1:<port_http> http://identiguy.i2p/`
- **SOCKS proxy**: `curl --socks5-hostname 127.0.0.1:<port_socks> http://identiguy.i2p/`
- **SAM bridge** for SAMv3-speaking apps: `127.0.0.1:<port_sam>` (TCP; datagrams on `<port_sam>-1`).
- **Extra tunnels**: drop files into `/etc/i2pd/tunnels.conf.d/` (see the examples in `/etc/i2pd/tunnels.conf`) and `systemctl restart i2pd`.

Replace `<port_http>` etc. with the values you chose at install: `yunohost app setting i2pd list`.

## Connectivity

Forward the peer port (default **4567**) as **TCP and UDP** on your internet router so the router reaches "OK" instead of "Firewalled" — the YunoHost firewall side is already opened by the app. i2pd also works firewalled (SSU2 hole punching), just less effectively as a relay.

## Local apps and containers needing I2P

Point them at the loopback HTTP/SOCKS proxies or the SAM bridge. They bind `127.0.0.1` on purpose; to serve a Docker network, forward from its bridge gateway (e.g. `socat`) or rebind the section's `address` in `/etc/i2pd/i2pd.conf` — see `doc/ADMIN.md`.

## Running next to the Java router (`java_i2p`)?

Nothing to fix after the fact: the install questions already steered i2pd off the Java router's ports (its HTTP proxy 4444, HTTPS proxy 4445, SAM 7656, console 7657, eepsite 7658, IRC/SMTP/POP 6668/7659/7660 — all loopback). The two routers use separate service names, users, data directories, vhosts and peer ports (java 51427, i2pd 4567). The full table lives in the app README.
