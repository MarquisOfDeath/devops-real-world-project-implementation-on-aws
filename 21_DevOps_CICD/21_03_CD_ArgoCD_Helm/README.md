# ArgoCD Deployment for Retail UI (Helm-based GitOps)

This guide covers deploying the `retail-ui` microservice using **ArgoCD + Helm** in a GitOps-driven CI/CD workflow.

---

## Step-01: Introduction

![ArgoCD Retail UI Application](images/argocd-retail-ui.png)

This example demonstrates using ArgoCD to deploy a Helm-based microservice (`ui`) from a GitHub repo into an EKS cluster.

---

## Step-02: Add Git Repository Authentication (Only for Private Repos)

> **Skip this step if your GitHub repo is public.**
> In this demo, the repository [aws-devops-github-actions-ecr-argocd3](https://github.com/stacksimplify/aws-devops-github-actions-ecr-argocd3/) will be made public by the time you're implementing it, so authentication won’t be required in most cases.

>  ArgoCD can access public repos without any authentication.

If your repository is **private**, ArgoCD needs credentials to **clone the repo and fetch manifests**. Without this, you'll see errors like:

```vbnet
ComparisonError: failed to load target state: authentication required
```

✅ You can fix this by registering your private Git repo with ArgoCD using:

* A GitHub Personal Access Token (PAT), or
* SSH key-based authentication (advanced)

### Step-02-00: Install ArgoCD CLI
- [ArgoCD CLI Installation](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
```bash
# MacOs ArgoCD Install
brew install argocd

```

### Step-02-01: Get ArgoCD Admin Password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode && echo
```

### Step-02-02: Login to ArgoCD CLI

```bash
# ArgoCD - port-forward to access via localhost
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login to ArgoCD
argocd login localhost:8080 --username admin --password <copied-password> --insecure

# Verify argocd version
argocd version
```

### Step-02-03: Register Your GitHub Repo with ArgoCD

```bash
# Template: Register Your GitHub Repo with ArgoCD
argocd repo add https://github.com/stacksimplify/aws-devops-github-actions-ecr-argocd3.git \
  --username <your-github-username> \
  --password <your-personal-access-token> \
  --name aws-devops-github-actions-ecr-argocd3


argocd repo add https://github.com/stacksimplify/aws-devops-github-actions-ecr-argocd3.git \
  --username stacksimplify \
  --password <your-personal-access-token> \
  --name aws-devops-github-actions-ecr-argocd3  
```

✅ Once added, verify in the ArgoCD UI:

* Go to **Settings → Repositories**
* Confirm repo shows as **"Successful"** under **Connection Status**

#### How to get Github Personal Access Token?
- Go to Github -> Settings -> Developer Settings 
- Go to Personal Access Tokens -> Tokens (classic) -> Generate new token

---

## Step-03: Review ArgoCD Application Manifest

This file is located at: `argocd-manifests/application-ui.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ui
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/stacksimplify/aws-devops-github-actions-ecr-argocd3.git
    targetRevision: main
    path: src/ui/chart
    helm:
      valueFiles:
        - values-ui.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true    # Auto-delete resources not in Git
      selfHeal: true # Auto-sync if drift detected
    syncOptions:
      - CreateNamespace=true

```


This file is located at: `argocd-manifests/application-ui.yaml`
It defines **how ArgoCD should deploy the `retail-ui` microservice** using your Git repository and Helm chart.

==========

###### Production grade yaml file: ###########

```yaml
# =====================================================================
# ArgoCD setup for the "ui" service (production)
#
# This ONE file has 2 objects (separated by ---):
#   1. AppProject  -> security boundary: what this app is allowed to touch
#   2. Application -> watches the Helm chart in GitHub and deploys it
#
# Apply with:  kubectl apply -f argocd-ui.yaml
# Check with:  kubectl get application ui -n argocd
#
# Lines marked  # <-- CHECK  are the ones to review before applying.
# =====================================================================

---
# ---------------------------------------------------------------------
# 1. APPPROJECT
# Restricts the app to ONE repo, ONE cluster and ONE namespace.
# This is safer than using the "default" project, which allows anything.
# ---------------------------------------------------------------------
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: retail-store
  namespace: argocd
spec:
  description: Retail store microservices (production)

  # Apps in this project may only read from this Git repo
  sourceRepos:
    - https://github.com/MarquisOfDeath/aws-devops-github-actions-ecr-argocd3.git

  # Apps in this project may only deploy to this cluster + namespace
  destinations:
    - server: https://kubernetes.default.svc   # the cluster ArgoCD runs in
      namespace: retail-store                  # <-- CHECK: target namespace

  # Block cluster-wide resources, except Namespace
  # (Namespace is needed for the CreateNamespace=true option below)
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace

  # Warn in the UI if something exists in the namespace that is not in Git
  orphanedResources:
    warn: true

---
# ---------------------------------------------------------------------
# 2. APPLICATION
# Tells ArgoCD: "take the Helm chart from this repo/path and keep it
# deployed in this namespace".
# ---------------------------------------------------------------------
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ui
  namespace: argocd
  labels:
    app.kubernetes.io/name: ui
    app.kubernetes.io/part-of: retail-store
    env: prod
  # If this Application is deleted, also delete everything it deployed.
  # Remove this line if you want workloads to survive its deletion.
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: retail-store            # must match the AppProject name above

  # WHERE the Helm chart lives
  source:
    repoURL: https://github.com/MarquisOfDeath/aws-devops-github-actions-ecr-argocd3.git
    targetRevision: main           # branch to track (pin a tag/commit for stricter control)
    path: src/ui/chart             # folder that contains Chart.yaml
    helm:
      releaseName: ui
      valueFiles:
        - values-ui.yaml           # relative to "path". CI updates image.tag in this file
      ignoreMissingValueFiles: false   # fail loudly if the values file is missing

  # WHERE to deploy
  destination:
    server: https://kubernetes.default.svc
    namespace: retail-store        # <-- CHECK: same namespace as in the AppProject

  # HOW to sync
  syncPolicy:
    automated:
      prune: true                  # delete resources that were removed from Git
      selfHeal: true               # undo manual changes made directly in the cluster
      allowEmpty: false            # never sync if the chart renders nothing (safety net)

    syncOptions:
      - CreateNamespace=true       # create the namespace if it does not exist
      - ServerSideApply=true       # safer applies, avoids annotation size limits
      - ApplyOutOfSyncOnly=true    # only touch resources that actually changed
      - PruneLast=true             # delete old resources only after new ones are healthy

    # Labels put on the namespace that ArgoCD creates
    managedNamespaceMetadata:
      labels:
        pod-security.kubernetes.io/enforce: restricted   # <-- CHECK: use "baseline" if pods fail to start

    # If a sync fails (e.g. temporary API error), retry with backoff
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m

  # Keep the last 10 syncs so you can roll back
  revisionHistoryLimit: 10

  # Only needed if the chart uses an HPA. Without it, selfHeal keeps
  # resetting the replica count back to the value in Git.
  # ignoreDifferences:
  #   - group: apps
  #     kind: Deployment
  #     jsonPointers:
  #       - /spec/replicas

```

---

### Breakdown of Key Fields:

#### `metadata.name` & `metadata.namespace`

```yaml
name: ui
namespace: argocd
```

This tells ArgoCD:

* The application is called `ui`
* It will be managed by the ArgoCD instance running in the `argocd` namespace

---

#### `source`

```yaml
repoURL: https://github.com/stacksimplify/aws-devops-github-actions-ecr-argocd3.git
targetRevision: main
path: src/ui/chart
```

This defines **where ArgoCD should pull the deployment configuration from**:

* `repoURL`: The GitHub repo where your Helm chart lives
* `targetRevision`: Branch name (usually `main`)
* `path`: Directory path to the Helm chart within the repo

---

#### `helm.valueFiles`

```yaml
helm:
  valueFiles:
    - values-ui.yaml
```

This tells ArgoCD which values file to use when rendering the Helm chart.
You're overriding defaults in `values.yaml` with EKS-specific settings in `values-ui.yaml`.

---

#### `destination`

```yaml
server: https://kubernetes.default.svc
namespace: default
```

This tells ArgoCD **where to deploy the app**:

* `server`: Deploy into the same Kubernetes cluster where ArgoCD is installed
* `namespace`: Target namespace (`default` for now; can be `retailapps` later)

---

#### `syncPolicy`

```yaml
automated:
  prune: true
  selfHeal: true
syncOptions:
  - CreateNamespace=true
```

These settings control **how and when ArgoCD syncs the application**:

* `automated`: Enables automatic sync on any Git change
* `prune`: Deletes old resources no longer defined in Git
* `selfHeal`: Restores drift if someone manually edits the app in the cluster
* `CreateNamespace=true`: Creates the target namespace if it doesn't exist

---

### Summary

This manifest makes your app fully **Git-driven and self-healing**:

* You control deployments via Git commits
* ArgoCD ensures what's in Git is always what's in the cluster


---

## Step-04: Deploy ArgoCD Application

```bash
kubectl apply -f argocd-manifests/application-ui.yaml
```

---

## Step-05: Review Application in ArgoCD UI

1. Port-forward ArgoCD UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

2. Open your browser:

```
https://localhost:8080
```

3. Login:

```bash
Username: admin
Password: (from step 2 or script output)

# Get ArgoCD Admin Password
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode && echo
```

4. Verify the application is **Synced** and **Healthy**

---

### What Does "Synced" Mean?

* ArgoCD compares Git state with cluster state
* If the app is not present or is outdated, it deploys it
* If the app is already up to date, it reports `Synced`
* ArgoCD will auto-correct any drift if `selfHeal: true` is enabled

---

🎉 🎉 🎉 You're now running GitOps-based CD with ArgoCD, EKS, Helm, and GitHub Actions!
