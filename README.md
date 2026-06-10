# Inception of Things

This repository contains a multi-part lab that demonstrates building and deploying an example application with GitLab and ArgoCD. Parts 1–3 can be run locally; the Bonus section requires a VM so it runs on top of Part 3.


## Quick overview
1. Run Part 1 (local) — follow instructions in `p1/`
2. Run Part 2 (local) — follow instructions in `p2/`
3. Run Part 3 (local or inside VM) — follow instructions in `p3/`
4. Bonus — runs inside a VM on top of Part 3 (see below)

## Prérequis
- VirtualBox >= 7.x
- Vagrant >= 2.x
---

## partie 1
Cette partie introduit Vagrant et Kubernetes dans sa version allégée K3s. L'objectif est de mettre en place deux machines virtuelles communicantes via un réseau privé, provisionnées automatiquement par Vagrant.
La première machine (dabaeS, IP 192.168.56.110) fait tourner K3s en mode controller — c'est le nœud maître qui orchestre le cluster. La seconde machine (dabaeSW, IP 192.168.56.111) fait tourner K3s en mode agent — c'est le nœud worker qui exécute les charges de travail sous les ordres du controller.
Les deux machines sont configurées pour accepter des connexions SSH sans mot de passe, et kubectl est installé sur le controller pour interagir avec le cluster depuis l'intérieur.
### Générer les VM via vagrant
dans p1/
```bash
make build
```
### Entrer dans la VM server par ssh:
```bash
vagrant ssh dabaeS
```

### Vérifier l'adresse IP:
```bash
ip a show enp0s8
ip a show eth1
```
### Vérifier le hostname
`hostname`

### Vérifier que k3s tourne
`systemctl status k3s`
`k3s --version`
### Vérifier que le server et le worker sont dans le même cluster
`kubectl get nodes -o wide`

Dans un autre terminal, entrer dans la VM worker:
```bash
vagrant ssh dabaeSW
```
### Vérifier que k3s agent tourne sur le worker
`systemctl status k3s-agent`

### Sortir de la connection ssh
`exit`

### Nettoyer les VMs
`make clean`

---

## Partie 2
Partie 2 — K3s et trois applications simples
Cette partie introduit le routage HTTP par nom de domaine dans Kubernetes. Une seule machine virtuelle (kbrenerS, IP 192.168.56.110) fait tourner un cluster K3s qui héberge trois applications web simultanément sur la même adresse IP.
Le composant clé est l'Ingress, qui joue le rôle d'aiguilleur : il analyse le header Host de chaque requête entrante et redirige vers la bonne application — app1.com vers app1, app2.com vers app2, et toute autre requête vers app3 par défaut.
La deuxième application tourne avec trois réplicas, illustrant le load balancing : les requêtes sont automatiquement réparties entre les trois pods, et Kubernetes en recrée un automatiquement si l'un d'eux tombe.
### Générer la VM, dans /p2:
```bash
make build
vagrant ssh
ip addr show eth1
```
### checker le nom de la machine
`hostname`
### vérifier que k3s tourne
`sudo systemctl status k3s`
`k3s --version`
### vérifier le noeud et son ip
`kubectl get nodes -o wide`
### vérifier les 3 apps dans kube-system
`kubectl get all -n kube-system`
### vérifier les 3 apps dans default
`kubectl get all -n default`
### vérifier l'ingress
`kubectl get ingress`
`kubectl describe ingress app-ingress`
### vérifier l'accessibilité des apps
`curl -H "Host: app1.com" http://192.168.56.110`
`curl -H "Host: app2.com" http://192.168.56.110`
`curl -H "Host: app3.com" http://192.168.56.110`

### Sortir de la connection ssh
`exit`

### Nettoyer les VMs
`make clean`
---

## Partie 3
Cette partie introduit le GitOps, une méthodologie de déploiement où Git est la source de vérité unique pour la configuration de l'infrastructure et des applications.
Un cluster Kubernetes local est créé avec k3d (Kubernetes dans Docker), dans lequel ArgoCD est installé et configuré pour surveiller un dépôt GitHub. Tout changement poussé sur le dépôt est automatiquement détecté et déployé dans le cluster, sans aucune intervention manuelle.
La configuration inclut un namespace dev dans lequel l'application tourne, et un namespace argocd pour les composants ArgoCD. L'application est exposée via un Ingress et peut être mise à jour simplement en poussant un nouveau tag d'image sur le dépôt GitHub — ArgoCD se charge du reste.

Pour la partie 3, vous pouvez lancer le projet directement sur votre machine ou bien dans une machine virtuelle. 
Comme nous avons fait le bonus, nous vous recommandons de lancer la vm du bonus (`make build-vm` dans le dossier /bonus) puis de lancer la partie 3 dans cette machine (le git est automatiquement cloné dans la VM), vous gagnerez du temps. 

### construire le cluster 
si VM
```bash
vagrant ssh
cd inception-of-things/p3
make build
```
si machine hote
```bash
cd p3
make build
```

### Vérifier les namespaces
kubectl get ns

### Vérifier tous les pods ArgoCD
kubectl get pods -n argocd

### Vérifier tous les pods dev
kubectl get pods -n dev

### Vue complète
kubectl get all -n argocd
kubectl get all -n dev

### Vérifier les noeuds du cluster k3d
kubectl get nodes

### pour la VM modifier `/etc/hosts` en ajoutant:
```
192.168.56.10	app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```
### pour la machine hote modifier `/etc/hosts` en ajoutant:
```
127.0.0.1	app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```

l'application est consultable via ce lien (curl ou navigateur) :
`http://app-iot:8080/`
l'interface ArgoCD via ce lien: 
`https://argocd-iot.com:9443/`.
mettre 'admin' pour le user et le mdp fourni dans le terminal après l'installation de k3d

### Pour tester le bon fonctionnement de ArgoCD:
modifier le fichier `/p3/confs/deployment.yaml` (par exemple, 3 réplicas au lieu de 1 ou v2 au lieu de v1) 
forcer la synchronisation de ArgoCD dans l'interface (ou bien utiliser la commande `make sync`)
### pour voir le changement de version de l'app
`curl http://localhost:8888/`
### pour voir les réplicas
`kubectl get pods -n dev`

### arrêter le cluster:
`make stop`

### supprimer le cluster:
`make clean`

## Bonus
The Bonus section is intended to run inside a Vagrant VM to avoid modifying your host system.

Prerequisite: Part 3 must be set up and running inside the VM.

To build and enter the Bonus VM:

```bash
make build-vm
vagrant ssh
```

Inside the VM, run the bonus setup and connect ArgoCD to the GitLab instance:

```bash
cd inception-of-things/p3
make build
cd ../bonus
make build
```

How to test the Bonus:
- Open ArgoCD at `https://argocd-iot.com:9443/`.
- Modify `inception-of-things-bonus/p3/confs/application.yaml` (e.g. change `v1` → `v2`) and commit/push.
- If the `app-bonus` application becomes Healthy and Synced, the integration is working.

---

## Troubleshooting
- If `git push` fails with a 502, wait a few moments and retry — GitLab services may be restarting.
- Ensure the GitLab pods are Running and Ready before pushing code; use `kubectl get pods -n gitlab`.
- If you can't reach ArgoCD/GitLab from the host, verify `/etc/hosts` and that port-forwards are running (see `make forward` in `bonus/Makefile`).

## Helpful Make targets (from `bonus/Makefile`)
- `make build-vm` — create and start the VM
- `make build` — run the full in-VM setup sequence
- `make forward` — port-forward GitLab to host in background process
- `make password` — print GitLab root password