# i2pd — post-installation

## Les premières minutes

Au premier démarrage, i2pd génère une identité de routeur, se reseed depuis le réseau et prépare ses tunnels exploratoires — comptez **2 à 10 minutes** avant que les eepsites répondent. Suivi :

```
grep -iE 'reseed|network status|tunnels' /var/log/i2pd/i2pd.log | tail
```

…ou ouvrez la console web et regardez le statut passer de *Testing* à *OK*.

## Où trouver quoi

- **Console web** : `https://<domaine>/` — derrière le portail SSO de YunoHost. Ajustez les accès avec `yunohost user permission update i2pd.main --add/--remove ...`.
- **Proxy HTTP** (eepsites) : `curl -x http://127.0.0.1:<port_http> http://identiguy.i2p/`
- **Proxy SOCKS** : `curl --socks5-hostname 127.0.0.1:<port_socks> http://identiguy.i2p/`
- **Pont SAM** (SAMv3) : `127.0.0.1:<port_sam>` (TCP ; datagrammes sur `<port_sam>-1`).
- **Tunnels supplémentaires** : déposez des fichiers dans `/etc/i2pd/tunnels.conf.d/` (exemples dans `/etc/i2pd/tunnels.conf`) puis `systemctl restart i2pd`.

Remplacez `<port_http>` etc. par les valeurs choisies à l'installation : `yunohost app setting i2pd list`.

## Connectivité

Transférez le port pair (par défaut **4567**) en **TCP et UDP** sur votre box pour un statut « OK » au lieu de « Firewalled » — côté pare-feu YunoHost, l'app a déjà ouvert le port. i2pd fonctionne aussi en mode firewalled (perçage SSU2), simplement moins bien comme relais.

## Applications et conteneurs locaux

Pointez-les sur les proxys loopback ou le pont SAM. Ils écoutent `127.0.0.1` exprès ; pour servir un réseau Docker, transférez depuis la passerelle du bridge (p. ex. `socat`) ou rebindéz l'`address` de la section dans `/etc/i2pd/i2pd.conf` — voir `doc/ADMIN.md`.

## À côté du routeur Java (`java_i2p`) ?

Rien à corriger après coup : les questions d'installation ont déjà placé i2pd hors des ports du routeur Java (proxy HTTP 4444, proxy HTTPS 4445, SAM 7656, console 7657, eepsite 7658, IRC/SMTP/POP 6668/7659/7660 — tous en loopback). Les deux routeurs ont des noms de service, utilisateurs, répertoires de données, vhosts et ports pairs séparés (java 51427, i2pd 4567). Le tableau complet est dans le README de l'app.
