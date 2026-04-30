
rm-pods:
	k delete pods --all-namespaces --field-selector status.phase=Failed

clean:
	@echo "$(RED)Cleaning up GitLab and Bonus resources...$(RESET)"
	@helm uninstall gitlab -n gitlab 2>/dev/null || true
	@k delete namespace gitlab --wait=true 2>/dev/null || true
	@argocd repo rm http://gitlab.127.0.0.1.nip.io:8081/root/inception-of-things-bonus.git --insecure 2>/dev/null || true
	
	@echo "$(GREEN)Cleanup complete. Ready for re-run.$(RESET)"

forward-gitlab:
	@echo "$(GREEN)Forwarding GitLab on http://localhost:8081...$(RESET)"
	kubectl port-forward --address 0.0.0.0 svc/gitlab -n gitlab 8081:80

build-vm:
	@echo "Building VMs....."
	vagrant up

clean-vm:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant

password:
	k get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode && echo

.PHONY: build-vm clean clean-vm password
