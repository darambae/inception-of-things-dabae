# Inception of Things

Ce dépôt contient un laboratoire en plusieurs parties illustrant la construction et le déploiement d'une application exemple avec GitLab et ArgoCD. Les parties 1 à 3 peuvent être exécutées localement ; la section Bonus nécessite une VM et s'appuie sur la Partie 3.

## Prérequis

- VirtualBox >= 7.x
- Vagrant >= 2.x

---

## Partie 1 — Vagrant et K3s

Cette partie introduit Vagrant et Kubernetes dans sa version allégée K3s. L'objectif est de mettre en place deux machines virtuelles communicantes via un réseau privé, provisionnées automatiquement par Vagrant.

- **dabaeS** (IP `192.168.56.110`) — K3s en mode **controller** (nœud maître)
- **dabaeSW** (IP `192.168.56.111`) — K3s en mode **agent** (nœud worker)

Les deux machines acceptent des connexions SSH sans mot de passe. `kubectl` est installé sur le controller pour interagir avec le cluster depuis l'intérieur.

### Démarrage

```bash
# Dans p1/
make build

# Se connecter au server
vagrant ssh dabaeS
```

### Vérifications — Controller

```bash
# Adresse IP
ip a show enp0s8
ip a show eth1

# Hostname
hostname

# État de K3s
systemctl status k3s
k3s --version

# Nœuds du cluster
kubectl get nodes -o wide
```

### Vérifications — Worker

```bash
# Dans un autre terminal
vagrant ssh dabaeSW

# État de l'agent K3s
systemctl status k3s-agent
```

### Nettoyage

```bash
exit        # Quitter la connexion SSH
make clean  # Supprimer les VMs
```

---

## Partie 2 — K3s et trois applications

Cette partie introduit le routage HTTP par nom de domaine dans Kubernetes. Une seule machine virtuelle (**kbrenerS**, IP `192.168.56.110`) fait tourner un cluster K3s hébergeant trois applications web simultanément sur la même adresse IP.

L'**Ingress** joue le rôle d'aiguilleur : il analyse le header `Host` de chaque requête et redirige vers la bonne application — `app1.com` → app1, `app2.com` → app2, toute autre requête → app3 par défaut.

La deuxième application tourne avec trois réplicas, illustrant le load balancing : les requêtes sont réparties entre les trois pods, et Kubernetes en recrée un automatiquement si l'un tombe.

### Démarrage

```bash
# Dans p2/
make build
vagrant ssh
ip addr show eth1
```

### Vérifications

```bash
# Hostname et K3s
hostname
sudo systemctl status k3s
k3s --version

# Nœuds et ressources
kubectl get nodes -o wide
kubectl get all -n kube-system
kubectl get all -n default

# Ingress
kubectl get ingress
kubectl describe ingress app-ingress

# Accessibilité des applications
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: app3.com" http://192.168.56.110
```

### Nettoyage

```bash
exit        # Quitter la connexion SSH
make clean  # Supprimer les VMs
```

---

## Partie 3 — GitOps avec ArgoCD

Cette partie introduit le GitOps, une méthodologie où Git est la source de vérité unique pour la configuration de l'infrastructure et des applications.

Un cluster Kubernetes local est créé avec **k3d** (Kubernetes dans Docker), dans lequel **ArgoCD** est installé et configuré pour surveiller un dépôt GitHub. Tout changement poussé sur le dépôt est automatiquement détecté et déployé dans le cluster, sans intervention manuelle.

- Namespace **`dev`** — héberge l'application
- Namespace **`argocd`** — héberge les composants ArgoCD

> 💡 Si vous comptez faire le Bonus, lancez plutôt la VM du bonus (`make build-vm` dans `/bonus`) puis exécutez la Partie 3 depuis cette VM — le dépôt y est automatiquement cloné.

### Démarrage

```bash
# Depuis une VM
vagrant ssh
cd inception-of-things/p3
make build

# Depuis la machine hôte
cd p3
make build
```

### Vérifications

```bash
# Namespaces et pods
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev

# Vue complète
kubectl get all -n argocd
kubectl get all -n dev

# Nœuds du cluster k3d
kubectl get nodes
```

### Configuration `/etc/hosts`

```bash
# Dans la VM
192.168.56.10   app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io

# Sur la machine hôte
127.0.0.1       app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```

### Accès

| Interface | URL |
|---|---|
| Application | http://app-iot.com:8080/ |
| ArgoCD | https://argocd-iot.com:9443/ |

Identifiants ArgoCD : user `admin`, mot de passe affiché dans le terminal après l'installation de k3d.

### Tester ArgoCD

```bash
# 1. Modifier p3/confs/deployment.yaml (ex: v1 → v2, ou 1 → 3 réplicas)
# 2. Forcer la synchronisation
make sync

# Vérifier la version de l'app
curl http://localhost:8888/

# Vérifier les réplicas
kubectl get pods -n dev
```

### Arrêt et nettoyage

```bash
make stop   # Arrêter le cluster
make clean  # Supprimer le cluster
```

---

## Bonus — GitLab local + ArgoCD

Cette partie s'ajoute par-dessus la **Partie 3** et nécessite une instance GitLab locale intégrée à l'ArgoCD précédemment créé. Elle s'exécute entièrement dans une VM afin d'éviter toute modification du système hôte. Le dossier du projet est pré-cloné dans la VM.

> ⚠️ **Prérequis** : La Partie 3 doit être correctement configurée et active dans la VM.

### Architecture

- **Pipeline GitOps** — nouvelle application ArgoCD surveillant un dépôt hébergé sur l'instance GitLab locale
- **Composants externes** — PostgreSQL et Redis installés séparément pour garantir la stabilité avec la dernière version du Helm Chart GitLab
- **Gestion Git** — connexion SSH sécurisée ; création du dépôt entièrement automatisée par le script d'installation

### Démarrage

```bash
# 1. Créer et démarrer la VM (depuis le dossier bonus/)
make build-vm
vagrant ssh

# 2. Lancer la Partie 3
cd inception-of-things/p3
make build

# 3. Déployer le Bonus (peut prendre jusqu'à 30 minutes)
cd ../bonus
make build
```

### Tester le Bonus

1. Ouvrez ArgoCD : [https://argocd-iot.com:9443/](https://argocd-iot.com:9443/)
2. Modifiez `inception-of-things-bonus/p3/confs/deployment.yaml` (ex : `v1` → `v2`), puis committez et poussez vers GitLab.
3. Une fois `app-bonus` en statut **Healthy** et **Synced**, vérifiez le changement sur [http://app-iot.com:8080/](http://app-iot.com:8080/).

