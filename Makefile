# ----------------------------------------------------
# Local Minikube Deployment
# ----------------------------------------------------

K8S_MANIFESTS_DIR := deployment/k8s-manifests
NAMESPACE := op-stack
.PHONY: ha delete-statefulset reapply-statefulset watch reload-all

install: delete-statefulset reapply-statefulset
	kubectl get namespace $(NAMESPACE) || kubectl create namespace $(NAMESPACE)
	@echo "Applying HA manifests from $(K8S_MANIFESTS_DIR) into namespace $(NAMESPACE)..."
	cd $(K8S_MANIFESTS_DIR) && kubectl apply -R -f . -n $(NAMESPACE)

delete-statefulset:
	kubectl delete statefulset op-geth -n $(NAMESPACE) --cascade=orphan

reapply-statefulset:
	kubectl apply -f $(K8S_MANIFESTS_DIR)/op-geth/statefulset.yaml -n $(NAMESPACE)

status:
	@echo "Checking deployment status in namespace $(NAMESPACE)..."
	kubectl get all -n $(NAMESPACE)

# ----------------------------------------------------
# GCP GKE Deployment
# ----------------------------------------------------

PROJECT_ID := gelato-project-439308
CLUSTER_NAME := op-stack-gke-cluster
CLUSTER_ZONE := europe-north1
K8S_MANIFESTS_DIR := deployment/k8s-manifests
NAMESPACE := op-stack

.PHONY: auth deploy

# Authenticate with Google Cloud and get GKE credentials
gcp_auth:
	@echo "Authenticating with Google Cloud..."
	gcloud auth login
	@echo "Setting Google Cloud project to $(PROJECT_ID)..."
	gcloud config set project $(PROJECT_ID)
	@echo "Fetching GKE cluster credentials for $(CLUSTER_NAME) in zone $(CLUSTER_ZONE)..."
	gcloud container clusters get-credentials $(CLUSTER_NAME) --zone $(CLUSTER_ZONE)

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


