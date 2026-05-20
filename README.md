# Inception of Things

This repository contains a multi-part lab that demonstrates building and deploying an example application with GitLab and ArgoCD. Parts 1–3 can be run locally; the Bonus section requires a VM so it runs on top of Part 3.

## Contents
- `p1/`, `p2/`, `p3/` — project parts
- `bonus/` — VM-based bonus material that depends on Part 3

## Quick overview
1. Run Part 1 (local) — follow instructions in `p1/`
2. Run Part 2 (local) — follow instructions in `p2/`
3. Run Part 3 (local or inside VM) — follow instructions in `p3/`
4. Bonus — runs inside a VM on top of Part 3 (see below)

---

## Running Part 3 (recommended flow)
1. From the repo root, change into the `p3` scripts and run the build:

```bash
cd p3/scripts
./setup.sh
cd ..
make build
```

2. Confirm the application is reachable at `http://192.168.56.10:8080/` (if using the VM) and ArgoCD at `https://192.168.56.10:9443/`.

Note: To access from your host machine, add the following to `/etc/hosts` on your host:

```
192.168.56.10	gitlab.127.0.0.1.nip.io
```

3. To test ArgoCD sync: update `deployment.yaml` (e.g. change `v1` → `v2`), commit, and let ArgoCD synchronize. When the ArgoCD app shows Healthy & Synced, reload the application page to confirm the change.

---

## Bonus (VM-based)
The Bonus section is intended to run inside a Vagrant VM to avoid modifying your host system.

Prerequisite: Part 3 must be set up and running (inside the VM or accessible from the VM).

To build and enter the Bonus VM:

```bash
cd bonus
make build-vm
vagrant ssh
```

Inside the VM, run the bonus setup and connect ArgoCD to the GitLab instance:

```bash
cd inception-of-things-dabae/p3/scripts
./setup.sh
cd ../../..   # return to repo root inside VM
cd bonus
make build
```

How to test the Bonus:
- Open ArgoCD at `https://192.168.56.10:9443/`.
- Modify `inception-of-things-bonus/p3/confs/application.yaml` (e.g. change `v1` → `v2`) and commit/push.
- If the `app-bonus` application becomes Healthy and Synced, the integration is working.

---

## Troubleshooting
- If `git push` fails with a 502, wait a few moments and retry — GitLab services may still be initializing.
- Ensure the GitLab pods are Running and Ready before pushing code; use `kubectl get pods -n gitlab`.
- If you can't reach ArgoCD/GitLab from the host, verify `/etc/hosts` and that port-forwards are running (see `make forward` in `bonus/Makefile`).

## Helpful Make targets (from `bonus/Makefile`)
- `make build-vm` — create and start the VM
- `make build` — run the full in-VM setup sequence
- `make forward` — port-forward GitLab to host
- `make password` — print GitLab root password

