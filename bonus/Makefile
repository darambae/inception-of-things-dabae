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
build: setup-dependencies max-memory confirm-status connect-gitlab-argocd forward-gitlab 

setup-dependencies:
	@echo "$(GREEN)Installing dependencies...$(RESET)"
	@chmod +x $(CURRENT_DIR)/scripts/setup-gitlab.sh
	@$(CURRENT_DIR)/scripts/setup-gitlab.sh

confirm-status:
	@echo "$(GREEN)Checking GitLab Pods Status...$(RESET)"
	@chmod +x $(CURRENT_DIR)/scripts/check-status.sh
	@$(CURRENT_DIR)/scripts/check-status.sh

connect-gitlab-argocd:
	@echo "$(GREEN)Connecting GitLab with ArgoCD...$(RESET)"
	@chmod +x $(CURRENT_DIR)/scripts/connect-gitlab-argocd.sh
	@$(CURRENT_DIR)/scripts/connect-gitlab-argocd.sh
# setup-argocd:
# 	@echo "$(GREEN)Setting up ArgoCD & Injecting SSH Key...$(RESET)"
# 	@if [ ! -f ~/.ssh/id_rsa_argocd ]; then ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_argocd -N ""; fi
# 	@TOOLBOX_POD=$$(kubectl get pods -n gitlab -o custom-columns=NAME:.metadata.name --no-headers | grep toolbox | head -n 1); \
# 	PUB_KEY=$$(cat ~/.ssh/id_rsa_argocd.pub); \
# 	kubectl exec -i -n gitlab $TOOLBOX_POD -- env PUB_KEY="$PUB_KEY" gitlab-rails runner "user = User.find_by_username('root'); if user; key = Key.find_by(title: 'argocd-ssh-key') || Key.new(title: 'argocd-ssh-key', user: user); key.key = ENV['PUB_KEY']; if key.save; puts '🚀 SSH Key Registered Successfully'; else; puts key.errors.full_messages; end; else; puts '❌ Root user not found'; end"; \
# 	ARGOCD_PWD=$$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode); \
# 	argocd login 127.0.0.1:9443 --username admin --password "$$ARGOCD_PWD" --insecure; \
# 	argocd repo add git@gitlab-gitlab-shell.gitlab.svc.cluster.local:root/inception-of-things-bonus.git \
# 		--ssh-private-key-path ~/.ssh/id_rsa_argocd \
# 		--insecure-ignore-host-key \
# 		--server 127.0.0.1:9443 || echo "⚠️ Repo already exists"
# setup-git:
# 	@echo "$(GREEN)Initializing Git repository and pushing code...$(RESET)"
# 	mkdir -p $(CURRENT_DIR)/../inception-of-things-bonus
# 	cp -r $(CURRENT_DIR)/* $(CURRENT_DIR)/../inception-of-things-bonus/ 2>/dev/null || true
# 	cd $(CURRENT_DIR)/../inception-of-things-bonus && \
# 		git init --initial-branch=main && \
# 		git config user.email "dabae@gmail.com" && \
# 		git config user.name "daram bae" && \
# 		git remote add origin http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git 2>/dev/null || true && \
# 		git add . && \
# 		git commit -m "Initial commit" --allow-empty && \
# 		git push -u origin main --force
# 	kubectl apply -f confs/application.yaml

rm-pods:
	@kubectl delete pods --all-namespaces --field-selector status.phase=Failed
	@kubectl delete pods --all-namespaces --field-selector status.phase=Evicted

clean:
	@echo "$(RED)Cleaning up GitLab and Bonus resources...$(RESET)"
	@helm uninstall gitlab -n gitlab 2>/dev/null || true
	@k delete namespace gitlab --wait=true 2>/dev/null || true
	@argocd repo rm http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git --insecure 2>/dev/null || true
	
	@echo "$(GREEN)Cleanup complete. Ready for re-run.$(RESET)"

forward-gitlab:
	@echo "$(GREEN)Forwarding GitLab on http://localhost:8081...$(RESET)"
	@kubectl port-forward --address 0.0.0.0 svc/gitlab-nginx-ingress-controller -n gitlab 8081:80

password:
	@echo "$(GREEN)GitLab Root Password:$(RESET)"
	@kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode && echo

max-memory:
	sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
	sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

.PHONY: build-vm clean clean-vm password rm-pods forward-gitlab max-memory

# To see the details of a pod: kubectl describe pod <pod_name> -n <namespace>
# To see logs of a pod: kubectl logs <pod_name> -n <namespace>
# To see live logs of a pod: kubectl logs -f <pod_name> -n <namespace>


# STEPS
# 1> Build VMs: make build-vm
# 2> Build part 3: run p3/script/setup.sh -> make build, make forward 
# 3> (Once argocd is ready and running) Build bonus part: run bonus/scripts/setup.sh 

# IMPORTANT: Make sure to have the following pods in "Running" state and "Ready" condition before pushing code to GitLab:
# Gitlab is fully operational if the following pods are in "Running" state and "Ready" condition:
# 1. gitlab-postgresql-0 is running and ready
# 2. gitlab-redis-0 is running and ready
# 3. gitlab-gitaly-0 is running and ready
# 4. gitlab-webservice-default-<random> is running and ready 

# Once gitlab-webservice is running, git add, commit, and push to the repository to trigger ArgoCD synchronization.
# To access to GitLab UI from your host machine, configure your etc/hosts like 192.168.56.10 gitlab.127.0.0.1.nip.io
# And then open GitLab UI at http://gitlab.127.0.0.1.nip.io:8081/users/sign_in 