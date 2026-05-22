# Inception of Things

This repository contains a multi-part lab that demonstrates building and deploying an example application with GitLab and ArgoCD. Parts 1–3 can be run locally; the Bonus section requires a VM so it runs on top of Part 3.


## Quick overview
1. Run Part 1 (local) — follow instructions in `p1/`
2. Run Part 2 (local) — follow instructions in `p2/`
3. Run Part 3 (local or inside VM) — follow instructions in `p3/`
4. Bonus — runs inside a VM on top of Part 3 (see below)

---
## Running Part 1
1. Build VM
```bash
make build
```
2. Enter Server and Worker VMs using ssh
```bash
vagrant ssh dabaeS
```
 In another terminal,
```bash
vagrant ssh dabaeSW
```
3. Verify ip addresses
```bash
ip a show enp0s8
```
---
## Running Part 2
1. Build VM
```bash
make build
vagrant ssh
ip addr show eth1
#checker le nom de la machine
hostname
#vérifier que k3s tourne
sudo systemctl status k3s
k3s --version
#vérifier le noeud et son ip
kubectl get nodes -o wide
#vérifier les 3 apps dans kube-system
kubectl get all -n kube-system
#vérifier les 3 apps dans default
kubectl get all -n default
#vérifier l'ingress
kubectl get ingress
kubectl describe ingress app-ingress
#vérifier l'accessibilité des apps
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: app3.com" http://192.168.56.110
```
---

## Partie 3
Cette partie introduit le GitOps, une méthodologie de déploiement où Git est la source de vérité unique pour la configuration de l'infrastructure et des applications.
Un cluster Kubernetes local est créé avec k3d (Kubernetes dans Docker), dans lequel ArgoCD est installé et configuré pour surveiller un dépôt GitHub. Tout changement poussé sur le dépôt est automatiquement détecté et déployé dans le cluster, sans aucune intervention manuelle.
La configuration inclut un namespace dev dans lequel l'application tourne, et un namespace argocd pour les composants ArgoCD. L'application est exposée via un Ingress et peut être mise à jour simplement en poussant un nouveau tag d'image sur le dépôt GitHub — ArgoCD se charge du reste.

Pour la partie 3, vous pouvez lancer le projet directement sur votre machine ou bien dans une machine virtuelle. 
Comme nous avons fait le bonus, nous vous recommandons de lancer la vm de la bonus (`make build-vm` dans le dossier /bonus) puis de lancer la partie 3 dans cette machine (le git est automatiquement cloné dans la VM), vous gagnerez du temps. 

# construire le cluster 
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

# Vérifier les namespaces
kubectl get ns

# Vérifier tous les pods ArgoCD
kubectl get pods -n argocd

# Vérifier tous les pods dev
kubectl get pods -n dev

# Vue complète
kubectl get all -n argocd
kubectl get all -n dev

# Vérifier les noeuds du cluster k3d
kubectl get nodes

# pour la VM modifier `/etc/hosts` en ajoutant:
```
192.168.56.10	app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```
# pour la machine hote modifier `/etc/hosts` en ajoutant:
```
127.0.0.1	app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```

l'application est consultable via ce lien (curl ou navigateur) :
`http://app-iot:8080/`
l'interface ArgoCD via ce lien: 
`https://argocd-iot.com:9443/`.

# Pour tester le bon fonctionnement de ArgoCD:
modifier le fichier `/p3/confs/deployment.yaml` (par exemple, 3 réplicas au lieu de 1 ou v2 au lieu de v1) 
forcer la synchronisation de ArgoCD dans l'interface (ou bien utiliser la commande `make sync`)
# pour voir le changement de version de l'app
`curl http://localhost:8888/`
# pour voir les réplicas
`kubectl get pods -n dev`

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