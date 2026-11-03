KUBECTL ?= kubectl

DEPLOYMENT := web
LOAD_BALANCER_SERVICE := web-load-balancer
PVC := web-pvc

# Keep this order: the Deployment depends on the volume, and the backup job depends on the app.
MANIFESTS := web-volumes.yml web-deployments.yml lb-services.yml web-services.yml web-backups.yml
DELETE_MANIFESTS := web-backups.yml web-services.yml lb-services.yml web-deployments.yml web-volumes.yml

.DEFAULT_GOAL := help
.PHONY: help apply rollout status endpoints test port-forward recreate-pending-pvc restore delete

help: ## Show the available commands.
	@awk 'BEGIN { FS = ":.*##" } /^[a-zA-Z_-]+:.*##/ { printf "%-22s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

apply: ## Apply all application manifests.
	@for manifest in $(MANIFESTS); do \
		echo "Applying $$manifest"; \
		$(KUBECTL) apply -f "$$manifest"; \
	done

rollout: ## Wait for the web Deployment to finish rolling out.
	$(KUBECTL) rollout status deployment/$(DEPLOYMENT)

status: ## Show the web Deployment, pods, and Services.
	$(KUBECTL) get deployment/$(DEPLOYMENT)
	$(KUBECTL) get pods --show-labels
	$(KUBECTL) get services

endpoints: ## Show endpoints behind the load-balancer Service.
	$(KUBECTL) get endpointslices -l kubernetes.io/service-name=$(LOAD_BALANCER_SERVICE) -o wide

test: ## Send 1,000 requests to a load balancer at localhost:8080.
	./test-load-balancer.sh

port-forward: ## Forward localhost:8080 to the load-balancer Service.
	$(KUBECTL) port-forward service/$(LOAD_BALANCER_SERVICE) 8080:8080

recreate-pending-pvc: ## Recreate the PVC only if it is unbound and Pending.
	@phase="$$($(KUBECTL) get pvc $(PVC) -o jsonpath='{.status.phase}' 2>/dev/null || true)"; \
	if [ "$$phase" = "Pending" ]; then \
		echo "Deleting Pending PVC $(PVC)"; \
		$(KUBECTL) delete pvc $(PVC); \
	elif [ -n "$$phase" ]; then \
		echo "Refusing to delete $(PVC): its phase is $$phase." >&2; \
		exit 1; \
	fi
	$(KUBECTL) apply -f web-volumes.yml
	$(KUBECTL) apply -f web-deployments.yml
	$(KUBECTL) rollout status deployment/$(DEPLOYMENT)

restore: ## Restore a backup; run as make restore BACKUP_DATE=DD-MM-YYYY.
	@test -n "$(BACKUP_DATE)" || { echo "Set BACKUP_DATE=DD-MM-YYYY." >&2; exit 2; }
	bash ./restore-web-volume.sh "$(BACKUP_DATE)"

delete: ## Delete all application manifests in reverse dependency order.
	@for manifest in $(DELETE_MANIFESTS); do \
		echo "Deleting $$manifest"; \
		$(KUBECTL) delete -f "$$manifest"; \
	done
