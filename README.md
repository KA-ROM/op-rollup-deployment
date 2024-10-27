# OP Stack Rollup Deployment

This project deploys an OP Stack rollup. Defaults come from [Optimism's Create L2 Rollup guide](https://docs.optimism.io/builders/chain-operators/tutorials/create-l2-rollup).

## Deploying Locally to Minikube

### Prerequisites
- Minikube: https://minikube.sigs.k8s.io/docs/start/
- kubectl: https://kubernetes.io/docs/tasks/tools/

### Steps:

1. **Start Minikube:**

   Make sure Minikube is running:

   `minikube start`

2. **Deploy to Minikube:**

   Deploy all manifests to Minikube:

   `kubectl config use-context minikube`

   `make install_all`

3. **Check Deployment Status:**

   To see the status of the resources deployed:

   `make status`

4. **Uninstall from Minikube:**

   To clean up the deployment in Minikube:

   `make cleanup`


## Deploying to GKE on GCP

### Prerequisites
- Google Cloud SDK: https://cloud.google.com/sdk/docs/install
- kubectl: https://kubernetes.io/docs/tasks/tools/

### Steps:

1. **Roll out Terraform resources if needed:**

    Related commands include: 

    `gcloud auth application-default login`
    
    `cd deployment/terraform`
    
    `terraform init`
    
    `terraform plan`
    
    `terraform apply`
    
    Order matters. First, run `init` with the state backend config commented out in `deployment/terraform/main.tf`. 
    Afterward, `apply` the backend-state module. Then migrate the state to the backend (CLI prompts will walk you through it). You can apply the rest as normal! 

2. **Authenticate with GCP and Get GKE Cluster Credentials:**

   Run the following command to authenticate and set up credentials for the GKE cluster:

   `make gcp_auth`

3. **Deploy to GKE:**

   Once authenticated, deploy the manifests to the GKE cluster:

   `make gcp_deploy`

4. **Check Deployment Status:**

   To check the status of resources deployed on GKE:

   `make status`

5. **Cleanup Resources (without deleting the cluster):**

   To clean up all Kubernetes resources in the GCP environment while keeping the cluster intact:

   `make gcp_cleanup`


## To Do List... Tomorrow 🤞

- Expand documentation.
- Auto-scaling: Add auto-scaling support.
- Keta Integration: Introduce metric-based scaling using Keta.
- Karpenter: Implement Karpenter to manage node groups for better control over rotation.
- Secrets: Implement Secret Manager.
- Dynamic Authentication: Set up dynamic authentication for Proxyd.
- GitHub Actions: Automate deployment to GCP using GitHub Actions.
- Build Config Scripts: Create scripts to dynamically build fresh configurations based on parameters.
- Prometheus & Grafana: Add charts for monitoring and observability.

