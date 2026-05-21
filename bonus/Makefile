GREEN = \033[0;32m
RED   = \033[0;31m
RESET = \033[0m
CURRENT_DIR := $(CURDIR)

# To manage VM on your host machine
build-vm:
	@echo "Building VMs....."
	vagrant up

clean-vm:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant
#-------------------------------------------------------------------
# Inside VM
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

password:
	@echo "$(GREEN)GitLab Root Password:$(RESET)"
	@kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode && echo

cancel-forward:
	@echo "$(YELLOW)Arrêt du port-forwarding...$(RESET)"
	@pid=$(lsof -t -i:8081) && kill -9 $$pid 2>/dev/null || true

rm-pods:
	@kubectl delete pods --all-namespaces --field-selector status.phase=Failed
	@kubectl delete pods --all-namespaces --field-selector status.phase=Evicted

clean:
	@echo "$(RED)Cleaning up GitLab and Bonus resources...$(RESET)"
	@helm uninstall gitlab -n gitlab 2>/dev/null || true
	@kubectl delete namespace gitlab --wait=true 2>/dev/null || true
	@argocd repo rm http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git --insecure 2>/dev/null || true
	
	@echo "$(GREEN)Cleanup complete. Ready for re-run.$(RESET)"

.PHONY: build-vm clean clean-vm password rm-pods forward-gitlab max-memory
