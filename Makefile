GCP_PROJECT_ID = gelato-project-439308
GCP_REGION = eu-north1
GKE_REGION = europe-north1
GKE_CLUSTER_NAME = op-stack-gke-cluster

K8S_NAMESPACE := op-stack
K8S_RELEASE_NAME := op-stack-release
K8S_MANIFESTS_DIR := deployment/k8s-manifests
CHART_DIR_OP_STACK := deployment/helm/op-stack-chart
CHART_DIR_PROXYD := deployment/helm/proxyd-chart

# ----------------------------------------------------
# GCP Auth / Other Setup
# ----------------------------------------------------

gcp_auth:
	gcloud container clusters get-credentials $(GKE_CLUSTER_NAME) --region $(GKE_REGION) --project $(GCP_PROJECT_ID)
	gcloud auth configure-docker $(GKE_REGION)-docker.pkg.dev
	cd $(CHART_DIR_OP_STACK) && helm dependency update
	cd $(CHART_DIR_PROXYD) && helm dependency update

# ----------------------------------------------------
# Local Minikube Deployment
# ----------------------------------------------------

.PHONY: install uninstall status delete-statefulset reapply-statefulset

install_all: install_op install_proxyd
cleanup: uninstall_op uninstall_proxyd

# Install the entire OP Node stack using Helm
install_op: 
	kubectl get namespace $(K8S_NAMESPACE) || kubectl create namespace $(K8S_NAMESPACE)
	helm upgrade --install $(K8S_RELEASE_NAME) $(CHART_DIR_OP_STACK) --namespace $(K8S_NAMESPACE)

# Uninstall the OP Node stack
uninstall_op:
	helm uninstall $(K8S_RELEASE_NAME) --namespace $(K8S_NAMESPACE)

# Deploy proxyd along with the OP Node stack
install_proxyd: install
	helm upgrade --install proxyd-release $(CHART_DIR_PROXYD) --namespace $(K8S_NAMESPACE)

# Uninstall the proxyd service
uninstall_proxyd:
	helm uninstall proxyd-release --namespace $(K8S_NAMESPACE)

# Reapply the op-geth statefulset
reapply_statefulset:
	kubectl apply -f $(K8S_MANIFESTS_DIR)/op-geth/statefulset.yaml -n $(K8S_NAMESPACE)

# Delete the op-geth statefulset
delete_statefulset:
	kubectl delete statefulset op-geth -n $(K8S_NAMESPACE) --cascade=orphan

# Check the status of the deployment
status:
	kubectl get all -n $(K8S_NAMESPACE)

# ----------------------------------------------------
# GCP GKE Deployment
# ----------------------------------------------------

.PHONY: auth deploy

# Deploy Kubernetes manifests to GKE
gcp_deploy:
	kubectl get namespace $(K8S_NAMESPACE) || kubectl create namespace $(K8S_NAMESPACE)
	kubectl apply -R -f $(K8S_MANIFESTS_DIR) -n $(K8S_NAMESPACE)

gcp_cleanup:
	kubectl delete all --all -n $(K8S_NAMESPACE)
	kubectl delete namespace $(K8S_NAMESPACE)
