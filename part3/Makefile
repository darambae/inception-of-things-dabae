NAME        = iot-cluster
ARGOCD_NS   = argocd
DEV_NS      = dev
APP_CONF    = confs/application.yaml

GREEN  = \033[0;32m
RED    = \033[0;31m
YELLOW = \033[0;33m
RESET  = \033[0m

# ─── Cible par défaut ───────────────────────────────────────────────────────

build: cluster namespaces argocd-install argocd-wait argocd-app password
	@echo "$(GREEN)✅ Tout est prêt !$(RESET)"
	@echo "$(YELLOW)Lance 'make forward' dans un autre terminal pour accéder à l'UI.$(RESET)"

# ─── Cluster ────────────────────────────────────────────────────────────────

cluster:
	@echo "$(GREEN)Création du cluster k3d...$(RESET)"
	k3d cluster create $(NAME) \
		--agents 2 \
		-p "8080:80@loadbalancer" \
		-p "8888:8888@loadbalancer"

# ─── Namespaces ─────────────────────────────────────────────────────────────

namespaces:
	@echo "$(GREEN)Création des namespaces...$(RESET)"
	kubectl create namespace $(ARGOCD_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create namespace $(DEV_NS)    --dry-run=client -o yaml | kubectl apply -f -

# ─── Installation d'ArgoCD ──────────────────────────────────────────────────

argocd-install:
	@echo "$(GREEN)Installation d'Argo CD...$(RESET)"
	kubectl apply -n $(ARGOCD_NS) \
		--server-side \
		-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

argocd-wait:
	@echo "$(YELLOW)Attente des pods Argo CD (1-2 min)...$(RESET)"
	kubectl wait --for=condition=ready pod \
		-l app.kubernetes.io/name=argocd-server \
		-n $(ARGOCD_NS) \
		--timeout=300s

# ─── Application ArgoCD (lien GitHub → cluster) ─────────────────────────────

argocd-app:
	@echo "$(GREEN)Configuration de l'application ArgoCD...$(RESET)"
	kubectl apply -f $(APP_CONF)

# ─── Cycle de vie ────────────────────────────────────────────────────────────

start:
	@echo "$(GREEN)Démarrage du cluster $(NAME)...$(RESET)"
	k3d cluster start $(NAME)

stop:
	@echo "$(YELLOW)Arrêt du cluster $(NAME)...$(RESET)"
	k3d cluster stop $(NAME)

clean:
	@echo "$(RED)Suppression du cluster $(NAME)...$(RESET)"
	k3d cluster delete $(NAME)

fclean: clean
	@echo "$(RED)Nettoyage complet.$(RESET)"

re: fclean build

# ─── Utilitaires ─────────────────────────────────────────────────────────────

password:
	@echo "$(GREEN)Mot de passe Argo CD (user: admin) :$(RESET)"
	@kubectl -n $(ARGOCD_NS) get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 -d && echo

forward:
	@echo "$(GREEN)UI ArgoCD dispo sur : https://localhost:8443$(RESET)"
	kubectl port-forward svc/argocd-server -n $(ARGOCD_NS) 8443:443

sync:
	kubectl -n $(ARGOCD_NS) patch configmap argocd-cm --patch \
		'{"data":{"timeout.reconciliation":"10s"}}' 2>/dev/null || true
	argocd app sync wil-playground \
		--insecure \
		--port-forward \
		--port-forward-namespace $(ARGOCD_NS)

.PHONY: build cluster namespaces argocd-install argocd-wait argocd-app \
        start stop clean fclean re password forward sync