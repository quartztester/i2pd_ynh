# i2pd — runbook admin (app YunoHost `i2pd`)

## Qui tourne où

- Le binaire, le service systemd (`i2pd.service`), l'utilisateur `i2pd` et le profil AppArmor viennent tous du deb de la release amont épinglé. L'épinglage (version + sha256 par architecture) est dans `scripts/_common.sh` du dépôt de l'app — pour mettre à jour, incrémentez-le ainsi que la version du manifeste, puis `yunohost app upgrade i2pd`.
- Configuration gérée : `/etc/i2pd/i2pd.conf` et `/etc/i2pd/tunnels.conf` (suivies par somme de contrôle : les modifications locales sont détectées et conservées à la mise à jour). Tunnels en fichiers additionnels : `/etc/i2pd/tunnels.conf.d/*.conf`.
- Données : `/var/lib/i2pd` — identité du routeur, netDb, carnet d'adresses, certificats de reseed. Conservées lors d'un simple `yunohost app remove i2pd` (une réinstallation reprend comme le même routeur) ; supprimées uniquement avec `yunohost app remove i2pd --purge`.
- Journaux : `/var/log/i2pd/i2pd.log` (logrotate fourni par le deb). Aussi via `yunohost service log i2pd`.

## Ports et réglages

Lisibles avec `yunohost app setting i2pd get -k <clé>` :

| réglage | défaut | sens |
|---|---|---|
| `port` | 7070 | console web — loopback, proxyfiée par nginx derrière le SSO |
| `port_ext` | 4567 | port pair I2NP (NTCP2 TCP + SSU2 UDP), ouvert dans nftables |
| `port_http` | 4444 | proxy HTTP eepsite intégré — loopback |
| `port_socks` | 4447 | proxy SOCKS eepsite intégré — loopback |
| `port_sam` | 7656 | pont SAMv3 TCP — loopback (`port_sam_udp` = TCP−1) |

Pour en changer : éditez `/etc/i2pd/i2pd.conf` puis `systemctl restart i2pd`.

## Coexistence avec `java_i2p`

Les deux apps routeur peuvent tourner simultanément sur le même serveur. Seuls les défauts amont se chevauchent :

- Les deux apps activent leur pont SAM par défaut sur le port amont 7656 : la première installée le garde, la seconde détecte le conflit et bascule automatiquement sur 7666 (`port_sam` enregistre le port réel — `yunohost app setting i2pd port_sam`). Le seul chevauchement restant est le proxy HTTP Java (4444/4445) face au défaut HTTP d'i2pd ; les questions `port_http` / `port_socks` y pourvoient. L'installation échoue immédiatement si un port choisi est déjà occupé.
- Les ports pairs ne se chevauchent jamais : java 51427, i2pd 4567. Transférez les deux, TCP **et** UDP, sur la box pour la meilleure connectivité.
- Laissez la section `[i2cp]` d'i2pd désactivée (défaut amont) : le routeur Java sert l'I2CP sur 7654.
- Noms de service, utilisateurs système, répertoires de données et vhosts nginx sont totalement séparés.

## Opérations courantes

- Redémarrer : `systemctl restart i2pd`
- Statut reseed/floodfill : `grep -iE 'reseed|floodfill|network status' /var/log/i2pd/i2pd.log | tail`
- Test proxy : `curl -x http://127.0.0.1:$(yunohost app setting i2pd get -k port_http) http://identiguy.i2p/`
- Sauvegardes : incluent `/etc/i2pd` et `/var/lib/i2pd` ; la restauration retélécharge le deb épinglé et remet les deux en place.

## Conteneurs et applications locales

Les proxys et le pont SAM écoutent sur `127.0.0.1` par principe. Pour des conteneurs : soit transférez un port vers leur réseau (p. ex. `socat` depuis la passerelle du bridge docker vers le proxy loopback), soit rebindéz l'`address` de la section concernée dans `/etc/i2pd/i2pd.conf` sur une IP de passerelle de bridge et redémarrez.
