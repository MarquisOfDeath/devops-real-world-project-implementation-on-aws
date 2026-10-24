# 12_04: Package & Publish Retail UI Helm Chart (ECR Private)

## Step-01: Introduction

In this demo, we will learn how to **package, publish, install, and verify** a Helm chart for the **Retail Store UI Application** using **Amazon ECR Private**.

**Key topics:**

* Update chart metadata (`Chart.yaml`)
* Package Helm chart (`.tgz`)
* Push to **Amazon ECR Private** (OCI registry)
* Install Helm chart directly from ECR
* Understand image tag fallback (`.Chart.Version`)
* New: Release Info ConfigMap

---

## Pre-requiste Item
```bash
# Create a workspace and enter it
mkdir -p charts && cd charts


# Pull the UI chart from ECR Public (OCI) and unpack it
helm pull oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.6.3 \
  --untar

# Inspect what got created
ls -la  

# Rename the long folder name to smaller folder name
mv retail-store-sample-ui-chart ui

# Optional: install 'tree' if not present
# Amazon Linux
sudo dnf install tree -y
# macOS
brew install tree

# If you have 'tree':
tree -a || true
```

## Step-02: Update Chart Metadata

Edit **`Chart.yaml`** inside your chart (`ui/`):

```yaml
apiVersion: v2
name: retail-store-sample-ui-chart
description: Retail Store UI Helm Chart
type: application
version: 2.0.0       # Chart version (bump from 1.6.3 to 2.0.0)
```

* Always bump `version` when releasing a new chart.

---

## Step-03: Add Release Info ConfigMap 
* Create a new template file: **`templates/release-info.yaml`**

```yaml
{{- if .Values.releaseInfo.enabled }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "ui.fullname" . }}-release-info
  labels:
    {{- include "ui.labels" . | nindent 4 }}
data:
  chartName: "{{ .Chart.Name }}"
  chartVersion: "{{ .Chart.Version }}"
  appVersion: "{{ .Chart.AppVersion }}"
  releaseName: "{{ .Release.Name }}"
  releaseNamespace: "{{ .Release.Namespace }}"
  releaseRevision: "{{ .Release.Revision }}"
  releaseTime: "{{ now | date "2006-01-02T15:04:05Z07:00" }}"
{{- end }}
```

### Add defaults in `ui/values.yaml`

```yaml
releaseInfo:
  enabled: false
```

### Add overrides in `retailstore-apps/values-ui.yaml`

```yaml
releaseInfo:
  enabled: true
```

---

## Step-04: End-to-End Workflow 
1. Create AWS ECR Private repository
2. helm package
3. helm push

```bash

🔍 Why the OCI URL syntax looks specific (oci://...)
When Helm interacts with container registries like Amazon ECR, it uses the Open Container Initiative (OCI) standard. Under this protocol:
1. oci:// is the schema prefix: Just like http:// or ftp:// tells your browser how to talk to a server, oci:// tells the Helm CLI to stop looking for a traditional Helm Chart Repository index file and instead treat the destination like a Docker registry.
2. The Registry Endpoint Structure: The base domain layout for a private AWS ECR registry is formatted as [AWS-Account-ID].dkr.ecr.[AWS-Region].amazonaws.com.
3. The Target Repository Path: To push an OCI artifact, you must target the specific repository namespace.
For your setup, the exact, fully qualified OCI URL for your repository is:
oci://://amazonaws.com
When running helm push, the tool evaluates the package name and version inside your chart archive and automatically pushes the artifact straight into that exact repository path.

=========================

# Set Variables
REGION=ap-south-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
# Verify Variables
echo $REGION
echo $ACCOUNT_ID
echo $REGISTRY

# Step 1: Open the Correct Directory
## Navigate to your working directory where your local ui chart folder is located.
cd /Users/shaktiswarupmohanty/Documents/k8s_helm/helm_package_and_publish/charts

# Step 2: Create the Private ECR Repository
## Run this AWS CLI command to provision the blank repository inside the Mumbai (ap-south-1) region.
aws ecr create-repository \
    --repository-name retail-store-sample-ui-chart \
    --region ap-south-1

# Step 3: Authenticate the Helm CLI to AWS ECR
## Generate a temporary container registry authorization token via AWS CLI and pass it into the standard Helm login registry engine.
aws ecr get-login-password --region ap-south-1 | helm registry login --username AWS --password-stdin 478416475193.dkr.ecr.ap-south-1.amazonaws.com
### Expected Output: Login Succeeded

# Step 4: Package your Local Chart into an Archive
## Compile the directory components of your ui chart into a compressed OCI-compliant tarball distribution package.
helm package ui
### Note: This command reads your Chart.yaml file to determine the chart version. Assuming your version is 2.0.0, it will generate a file named "retail-store-sample-ui-chart-2.0.0.tgz" right inside your current directory.

# Step 5: Upload the Compressed Archive to ECR
## Push the compiled archive to your newly built container registry backend using the exact OCI target location layout.
helm push retail-store-sample-ui-chart-2.0.0.tgz oci://478416475193.dkr.ecr.ap-south-1.amazonaws.com

### oci url format: oci://[AWS-Account-ID].dkr.ecr.[AWS-Region].amazonaws.com

=========================

🔍 Verification Procedures

# Test A: Query AWS ECR to confirm the artifact exists
## Run this validation lookup to verify that Amazon ECR has successfully received and indexed the Helm chart artifact layout.

aws ecr describe-images \
    --repository-name retail-store-sample-ui-chart \
    --region ap-south-1 --query 'imageDetails[].imageTags'

### Look for an output block showing the structural artifact details, confirming the metadata upload was successful.

# Test B: Fetch the chart remotely to verify readability
## Move out of your active directory space completely and pull the uploaded package from the registry to confirm it can be cleanly used for deployments.
### Shift context to a temporary directory space
cd /tmp
### Pull and extract the remote package using the explicit repository link
helm pull oci://478416475193.dkr.ecr.ap-south-1.amazonaws.com --version 2.0.0 --untar


```

---

## Step-05: Install Chart from ECR Private

```bash
# helm install
helm install retail-ui \
  oci://"$REGISTRY"/retail-store-sample-ui-chart \
  --version 2.0.0 \
  -f ../retailstore-apps/values-ui.yaml
```

Or for upgrades:

```bash
# helm upgrade
helm upgrade --install retail-ui \
  oci://"$REGISTRY"/retail-store-sample-ui-chart \
  --version 2.0.0 \
  -f ../retailstore-apps/values-ui.yaml
```

---

## Step-06: Important Note on Deployment & Image Tags

The Deployment template defines the container image like this:

```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.Version }}"
```

Meaning:

* If you **set** `image.tag`, that tag is used.
* If you **don’t set it**, Helm falls back to `.Chart.Version`.

**Best Practice:** Always set `image.repository` and `image.tag` explicitly.

Example (`values-ui.yaml`):

```yaml
# Add Image and Tag
image:
  repository: public.ecr.aws/aws-containers/retail-store-sample-ui
  pullPolicy: IfNotPresent
  tag: 1.6.3   
```

* [Docker Image: retail-store-sample-ui](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui)

---

## Step-07: Verify Resources

```bash
# List Helm Releases
helm list

# List Kubernetes Resources
helm status retail-ui --show-resources 

# Verify pods & service
kubectl get pods,svc

# Verify Release Info ConfigMap
kubectl get cm 
kubectl get cm retail-ui-release-info -o yaml
kubectl describe cm retail-ui-release-info
```

---

## Step-08: Cleanup

```bash
helm uninstall retail-ui
```

---

## Step-09: Cleanup ECR Repository (Optional)
* To completely remove the chart repository from ECR:
```bash
# Delete AWS ECR Repository
aws ecr delete-repository \
  --repository-name retail-store-sample-ui-chart \
  --region "$REGION" \
  --force
```
>  Use `--force` to delete the repo along with all images (chart versions) inside it.

---
## Step-10: Summary

* Packaged **Retail UI Helm Chart v1.3.1**
* Published to **Amazon ECR Private**
* Installed directly from ECR
* Verified new **Release Info ConfigMap**
* Learned about **image tag fallback** (`.Chart.Version`)

**Note:** This completes the **real-world Helm packaging & publishing workflow** on AWS.

---

