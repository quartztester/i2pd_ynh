# i2pd — admin runbook (YunoHost app `i2pd`)

## What runs where

- Binary, systemd unit (`i2pd.service`), user `i2pd` and AppArmor profile all come from upstream's pinned release deb. The pin (version + per-architecture sha256) lives in `scripts/_common.sh` of the app repository — to upgrade, bump it and the manifest version, then `yunohost app upgrade i2pd`.
- Managed configuration: `/etc/i2pd/i2pd.conf` and `/etc/i2pd/tunnels.conf` (checksum-tracked: local edits are detected and preserved at upgrade). Drop-in tunnel definitions: `/etc/i2pd/tunnels.conf.d/*.conf` (picked up via the unit's `--tunnelsdir`).
- Data: `/var/lib/i2pd` — router identity, netDb, addressbook, reseed certificates. It survives a plain `yunohost app remove i2pd`, so a reinstall resumes as the same router; it is only deleted with `yunohost app remove i2pd --purge`.
- Logs: `/var/log/i2pd/i2pd.log` (logrotate comes from the deb). Also visible in `yunohost service log i2pd`.

## Ports and settings

Settings readable with `yunohost app setting i2pd get -k <key>`:

| setting | default | meaning |
|---|---|---|
| `port` | 7070 | webconsole — loopback, proxied by nginx behind the SSO |
| `port_ext` | 4567 | I2NP peer port (NTCP2 TCP + SSU2 UDP), opened in nftables |
| `port_http` | 4444 | built-in eepsite HTTP proxy — loopback |
| `port_socks` | 4447 | built-in eepsite SOCKS proxy — loopback |
| `port_sam` | 7656 | SAMv3 bridge TCP — loopback (`port_sam_udp` = TCP−1) |

To change one: edit `/etc/i2pd/i2pd.conf`, then `systemctl restart i2pd`. The loopback services are not availability-checked again afterwards, so pick free ports yourself (`ss -H -ltn | grep :PORT`).

## Coexistence with `java_i2p`

Both router apps can run on the same server at the same time. The only inherited overlaps are upstream defaults:

- Both apps enable their SAM bridge by default, on the upstream default 7656. Whichever router is installed first keeps 7656; the one installed second detects the conflict and automatically falls back to 7666 (`port_sam` records the actual port — query it with `yunohost app setting i2pd port_sam`). Downstream apps should read that setting rather than hardcoding. The remaining overlap is the HTTP proxy, which both routers default to 4444 (java's HTTPS proxy is 4445 and i2pd's SOCKS is 4447 — neither clashes with the other); the install questions `port_http` / `port_socks` cover it, and the install fails fast (`ynh_check_tcp_port_free`) if a chosen port is already bound.
- Peer ports never clash: java 51427, i2pd 4567. Forward both, TCP **and** UDP, on the internet router for best connectivity.
- Keep i2pd's `[i2cp]` section disabled (upstream default): the Java router serves I2CP on 7654.
- Service names, system users, data directories and nginx vhosts are fully separate (`i2pd` service/user/`/var/lib/i2pd` vs the Java app's own service under `/home/yunohost.app/java_i2p`).

## Common operations

- Restart: `systemctl restart i2pd`
- Reseeds / floodfill status: `grep -iE 'reseed|floodfill|network status' /var/log/i2pd/i2pd.log | tail`
- Proxy smoke test: `curl -x http://127.0.0.1:$(yunohost app setting i2pd get -k port_http) http://identiguy.i2p/`
- App-level: `yunohost app upgrade i2pd` — backups include `/etc/i2pd` and `/var/lib/i2pd`; restore re-downloads the pinned deb and puts both back.

## Containers and local apps

The proxies and SAM bridge bind `127.0.0.1` by design. For containers that need I2P access, either forward a port into their network (e.g. `socat` from the docker bridge gateway to the loopback proxy) or rebind the relevant section's `address` in `/etc/i2pd/i2pd.conf` to a bridge gateway IP and restart — the deb's AppArmor profile does not restrict binding, only file access.
