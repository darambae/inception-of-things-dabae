
build:
	@echo "Building VMs....."
	vagrant up

clean:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant

password:
	kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode && echo

.PHONY: build clean password
