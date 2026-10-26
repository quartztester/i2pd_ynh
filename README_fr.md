<!--
N.B. : ce README suit la mise en page du générateur de README de YunoHost
(https://github.com/YunoHost/apps_tools/blob/main/readme_generator)
pour pouvoir être régénéré depuis le manifeste plus tard sans rework.
-->

<h1>
  <img src="logos/i2pd.png" width="32px" alt="Logo de i2pd">
  i2pd, empaqueté pour YunoHost
</h1>

Routeur C++ léger pour le réseau anonyme I2P

[i2pd](https://i2pd.website) est un routeur I2P complet écrit en C++ — une alternative plus légère au routeur Java. Il relaie les tunnels chiffrés du réseau (par défaut en tant que **floodfill**) et offre au serveur des points d'accès locaux à I2P : un proxy HTTP et un proxy SOCKS pour les eepsites, plus un pont SAM pour les applications et conteneurs. La console web (pairs, tunnels, bande passante, carnet d'adresses) est proxyfiée par nginx derrière le portail SSO de YunoHost.

**Partage de capacité :** le mode floodfill répond aux requêtes de la base de données distribuée du réseau — la principale façon de contribuer à I2P. Désactivez-le avec `floodfill = false` dans `/etc/i2pd/i2pd.conf` pour un simple relais. Transférez le port pair (par défaut **4567, TCP et UDP**) sur votre box internet pour que le routeur atteigne « OK » au lieu de « Firewalled ».

**Côte à côte avec le routeur Java :** cette app et `java_i2p` peuvent tourner en même temps — les ports de console et pair ne se chevauchent jamais — mais les deux héritent des mêmes défauts amont pour les proxys/SAM (4444 / 7656). Lors de l'installation d'i2pd sur un serveur qui fait déjà tourner `java_i2p`, choisissez d'autres ports quand ils sont demandés (p. ex. 4447, 4448, 7666) ; l'installation échoue immédiatement sur un port occupé.

[![🌐 Site officiel de l'app](https://img.shields.io/badge/Site_officiel_de_l_app-darkgreen?style=for-the-badge)](https://i2pd.website)
![Version : 3.0.0~ynh1](https://img.shields.io/badge/Version-3.0.0~ynh1-rgb%2818,138,11%29?style=for-the-badge)

## Liens

- Projet amont : <https://i2pd.website>
- Paquet YunoHost : <https://github.com/quartztester/i2pd_ynh>

## Captures d'écran

![i2pd — console web](./doc/screenshots/webconsole.png)

## 📦 Infos développeur

🛠️ Dépôt amont i2pd : <https://github.com/PurpleI2P/i2pd>

L'app installe le `.deb` officiel de la release amont pour votre architecture (épinglé par sha256 dans `scripts/_common.sh` ; le dépôt apt amont est contourné). Le deb apporte son propre service systemd, son utilisateur `i2pd` et son profil AppArmor — le paquet conserve tous les chemins natifs du deb (`/etc/i2pd`, `/var/lib/i2pd`).

Installez l'état de développement directement avec :
```
# installation fraîche :
sudo yunohost app install https://github.com/quartztester/i2pd_ynh

# mise à jour d'une installation existante :
sudo yunohost app upgrade i2pd -u https://github.com/quartztester/i2pd_ynh
```
