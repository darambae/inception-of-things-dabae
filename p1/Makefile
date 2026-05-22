
build:
	@echo "Génération des VMs....."
	vagrant up --no-provision && \
	vagrant provision dabaeS && \
	vagrant provision dabaeSW

clean:
	@echo "Nettoyage des VMs....."
	vagrant destroy -f && rm -rf .vagrant node-token *.pub

.PHONY: build clean