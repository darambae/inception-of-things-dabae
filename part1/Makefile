
build:
	@echo "Building VMs....."
	vagrant up --no-provision
	vagrant provision dabaeS
	vagrant provision dabaeSW

clean:
	@echo "Cleaning up VMs....."
	vagrant destroy -f && rm -rf .vagrant node-token