GREEN = \033[0;32m
RED   = \033[0;31m
RESET = \033[0m
CURRENT_DIR := $(CURDIR)
NAME = iot-cluster

# To manage VM
build-vm:
	@echo "Building VMs....."
	vagrant up

clean-vm:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant
#-------------------------------------------------------------------
# Inside the VM
build: setup-dependencies forward connect-gitlab-argocd
	@echo "$(GREEN)✅ Tout est prêt !$(RESET)"

setup-dependencies:
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	@chmod +x $(CURRENT_DIR)/scripts/setup-gitlab.sh
	@$(CURRENT_DIR)/scripts/setup-gitlab.sh

forward:
	@echo "$(GREEN)Forwarding GitLab on http://localhost:8081 in background...$(RESET)"
	@nohup kubectl port-forward --address 0.0.0.0 svc/traefik -n kube-system 8081:80 > /dev/null 2>&1 &
	@sleep 2

connect-gitlab-argocd:
	@echo "$(GREEN)Connecting GitLab with ArgoCD...$(RESET)"
	@chmod +x $(CURRENT_DIR)/scripts/connect-gitlab-argocd.sh
	@$(CURRENT_DIR)/scripts/connect-gitlab-argocd.sh

cancel-forward:
	@echo "$(YELLOW)Arrêt du port-forwarding...$(RESET)"
	@pid=$(lsof -t -i:8081) && kill -9 $$pid 2>/dev/null || true

rm-pods:
	@kubectl delete pods --all-namespaces --field-selector status.phase=Failed
	@kubectl delete pods --all-namespaces --field-selector status.phase=Evicted

clean:
	rm -rf ../../inception-of-things-bonus
	@echo "$(RED)Suppression du cluster $(NAME)...$(RESET)"
	k3d cluster delete $(NAME)
	@echo "$(RED)Suppression de k3d...$(RESET)"
	sudo rm -f /usr/local/bin/k3d
	@echo "$(RED)Suppression des images Docker...$(RESET)"
	docker system prune -af
	

.PHONY: build-vm clean clean-vm password rm-pods forward cancel-forward build setup-dependencies connect-gitlab-argocd
