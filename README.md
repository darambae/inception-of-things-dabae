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
```
---

## Running Part 3 (recommended flow)
0. For Part 3, you can run in your host machine. However, as we have done Bonus part and it should work with Part 3, I recommend you to run both Part 3 and Bonus in the VM that you can setup by 'make build-vm' in /bonus 

1. To build part 3 either in your host machine or in the VM:
   - VM
```bash
vagrant ssh
cd inception-of-things/p3
make build
```
   - Host machine
```bash
make build
```

1. Confirm the application is reachable at `http://app-iot:8080/` (if using the VM) and ArgoCD at `https://argocd-iot.com:9443/`.

Note: To access from your host machine, add the following to `/etc/hosts` on your host:

```
192.168.56.10	app-iot.com argocd-iot.com gitlab.127.0.0.1.nip.io
```

3. To test ArgoCD sync: update `deployment.yaml` (e.g. change `v1` → `v2`), commit, and let ArgoCD synchronize or manually press sync button. When the ArgoCD app shows Healthy & Synced, reload the application page to confirm the change.

---

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