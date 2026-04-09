# Nom du cluster
NAME = me-cluster

# Couleurs pour le terminal
GREEN = \033[0;32m
RED = \033[0;31m
RESET = \033[0m

all: setup

setup:
	@echo "$(GREEN)Création du cluster k3d...$(RESET)"
	k3d cluster create $(NAME) --agents 2 -p "8080:80@loadbalancer" -p "8888:8888@loadbalancer"
	@echo "$(GREEN)Création des namespaces...$(RESET)"
	kubectl create namespace argocd
	kubectl create namespace dev
	@echo "$(GREEN)Installation d'Argo CD...$(RESET)"
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo "$(GREEN)Attente du démarrage des pods Argo CD (ça peut prendre 1-2 min)...$(RESET)"
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
	@$(MAKE) password

start:
	@echo "$(GREEN)Démarrage du cluster $(NAME)...$(RESET)"
	k3d cluster start $(NAME)

stop:
	@echo "$(RED)Arrêt du cluster $(NAME)...$(RESET)"
	k3d cluster stop $(NAME)

clean:
	@echo "$(RED)Suppression du cluster $(NAME)...$(RESET)"
	k3d cluster delete $(NAME)

fclean: clean
	@echo "$(RED)Nettoyage complet effectué.$(RESET)"

re: fclean all

# Commande pratique pour récupérer le mot de passe admin
password:
	@echo "$(GREEN)Mot de passe Argo CD :$(RESET)"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Commande pour le port-forward (à lancer dans un terminal séparé)
forward:
	@echo "$(GREEN)Port-forwarding sur le port 8443...$(RESET)"
	@echo "Lien : https://localhost:8443"
	kubectl port-forward svc/argocd-server -n argocd 8443:443