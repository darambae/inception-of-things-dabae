# To manage VM on your host machine
build-vm:
	@echo "Building VMs....."
	vagrant up

clean-vm:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant
#-------------------------------------------------------------------
# Inside VM
rm-pods:
	@kubectl delete pods --all-namespaces --field-selector status.phase=Failed

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
	@kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode && echo

.PHONY: build-vm clean clean-vm password rm-pods forward-gitlab

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