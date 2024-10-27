# ----------------------------------------------------
# Local Minikube Deployment
# ----------------------------------------------------

NAMESPACE := op-stack
RELEASE_NAME := op-stack-release
K8S_MANIFESTS_DIR := deployment/k8s-manifests
CHART_DIR := deployment/helm/op-stack-chart

.PHONY: install uninstall status delete-statefulset reapply-statefulset

# Install the entire OP Node stack using Helm
install: 
	kubectl get namespace $(NAMESPACE) || kubectl create namespace $(NAMESPACE)
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) --namespace $(NAMESPACE)

# Uninstall the OP Node stack
uninstall:
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

# Reapply the op-geth statefulset
reapply_statefulset:
	kubectl apply -f $(K8S_MANIFESTS_DIR)/op-geth/statefulset.yaml -n $(NAMESPACE)

# Delete the op-geth statefulset
delete_statefulset:
	kubectl delete statefulset op-geth -n $(NAMESPACE) --cascade=orphan

# Check the status of the deployment
status:
	kubectl get all -n $(NAMESPACE)

# ----------------------------------------------------
# GCP GKE Deployment
# ----------------------------------------------------
K8S_MANIFESTS_DIR := deployment/k8s-manifests
NAMESPACE := op-stack

.PHONY: auth deploy

# Deploy Kubernetes manifests to GKE
gcp_deploy:
	@echo "Creating namespace $(NAMESPACE) if it doesn't exist..."
	kubectl get namespace $(NAMESPACE) || kubectl create namespace $(NAMESPACE)
	@echo "Deploying Kubernetes manifests from $(K8S_MANIFESTS_DIR) to GKE..."
	kubectl apply -R -f $(K8S_MANIFESTS_DIR) -n $(NAMESPACE)
	@echo "Deployment complete!"

gcp_cleanup:
	@echo "Cleaning up all resources in the namespace $(NAMESPACE)..."
	kubectl delete all --all -n $(NAMESPACE)
	@echo "Deleting namespace $(NAMESPACE)..."
	kubectl delete namespace $(NAMESPACE)
	@echo "Cleanup complete!"
