# 12_01 Helm Basics - Retail Store UI Application (Basic Demo)

## Step-00: Helm Introduction

### Why Helm?
![Why Helm?](../../images/12-01-Why-Helm.png)


### Helm Benefits
![Helm Benefits](../../images/12-02-Helm-Benefits.png)


### Helm Workflow
![Why Helm](../../images/12-03-Helm-Workflow.png)

## Step-01: Introduction
In this demo, we will learn **Helm basics** using our **Retail Store UI Application**.

- How to **install a Helm chart from OCI**
- How to list and inspect Helm releases
- How to upgrade and rollback Helm releases
- How to override application values
- How to view **chart values and rendered manifests**
- How to uninstall a release

---

## Step-02: Explore Helm Chart Source
- [Search for Helm Charts at Artifacthub.io](https://artifacthub.io/)
- Retail Store UI Chart is published as an **OCI Helm Chart** in AWS Public ECR.
- [Retail Store UI Helm Chart](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui-chart)

👉 Since this is an **OCI-based chart**, we don’t add it with `helm repo add`.  
Instead, we install it directly from the `oci://` URL.

---

## Step-03: Install Retail UI Helm Chart (Default Settings)
By default, the chart installs with its own service configuration.

```bash
# Authenticate to Public ECR
## Helm needs a valid authentication token to pull OCI charts from Amazon ECR Public.
aws ecr-public get-login-password --region us-east-1 | helm registry login -u AWS --password-stdin public.ecr.aws


# Install Retail UI Helm Chart (version 1.0.0)
helm install retail-store-ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.6.3 \
  --namespace retail-app \
  --create-namespace


```

---

## Step-04: List Helm Releases

```bash
# List Helm releases (default table output)
shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % helm list -n retail-app                                                                           
NAME           	NAMESPACE 	REVISION	UPDATED                            	STATUS  	CHART                             	APP VERSION
retail-store-ui	retail-app	1       	2026-10-22 18:17:29.71079 +0530 IST	deployed	retail-store-sample-ui-chart-1.6.3	           
shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % 
shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % helm list -A           
NAME                        	NAMESPACE  	REVISION	UPDATED                             	STATUS  	CHART                                      	APP VERSION
aws-load-balancer-controller	kube-system	1       	2026-10-21 17:52:24.771521 +0530 IST	deployed	aws-load-balancer-controller-3.6.0         	v3.6.0     
csi-secrets-store           	kube-system	1       	2026-10-19 12:34:10.573418 +0530 IST	deployed	secrets-store-csi-driver-1.6.1             	1.6.1      
retail-store-ui             	retail-app 	1       	2026-10-22 18:17:29.71079 +0530 IST 	deployed	retail-store-sample-ui-chart-1.6.3         	           
secrets-provider-aws        	kube-system	1       	2026-10-19 12:41:07.147872 +0530 IST	deployed	secrets-store-csi-driver-provider-aws-3.1.4	           
shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % 

# List Helm releases in YAML or JSON
helm list -A --output=yaml
helm list -A --output=json

# List Helm releases for a specific namespace (if not using default)
helm list -n <namespace>
```

---

## Step-05: Verify Kubernetes Resources

After Helm installs the chart, Kubernetes resources are created automatically.

```bash
# List Pods, services etc created by the 'retail-store-ui' release

shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % kubectl get all -n retail-app -o wide
NAME                                   READY   STATUS    RESTARTS   AGE     IP            NODE                                         NOMINATED NODE   READINESS GATES
pod/retail-store-ui-599fb7f974-trfqj   1/1     Running   0          7m28s   10.0.12.193   ip-10-0-12-103.ap-south-1.compute.internal   <none>           <none>

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/retail-store-ui   ClusterIP   172.20.51.141   <none>        80/TCP    7m29s   app.kubernetes.io/component=service,app.kubernetes.io/instance=retail-store-ui,app.kubernetes.io/name=ui,app.kubernetes.io/owner=retail-store-sample

NAME                              READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                                                       SELECTOR
deployment.apps/retail-store-ui   1/1     1            1           7m29s   ui           public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.3   app.kubernetes.io/component=service,app.kubernetes.io/instance=retail-store-ui,app.kubernetes.io/name=ui,app.kubernetes.io/owner=retail-store-sample

NAME                                         DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES                                                       SELECTOR
replicaset.apps/retail-store-ui-599fb7f974   1         1         1       7m29s   ui           public.ecr.aws/aws-containers/retail-store-sample-ui:1.6.3   app.kubernetes.io/component=service,app.kubernetes.io/instance=retail-store-ui,app.kubernetes.io/name=ui,app.kubernetes.io/owner=retail-store-sample,pod-template-hash=599fb7f974
shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % 


```

👉 By default, the **Retail UI chart exposes a ClusterIP service**.
To access it from your local machine, use port-forward:

```bash
# Port-forward to access the application locally (adjust service name if different)
kubectl port-forward svc/retail-store-ui 30080:80 -n retail-app &


# Access the Retail UI application
http://localhost:30080
```

> Tip: If the service name isn’t exactly `ui`, find it via label:
>
> ```bash
> shaktiswarupmohanty@Shakti-MacBook-Air helm_basics % kubectl get svc -l app.kubernetes.io/instance=retail-store-ui -n retail-app
NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
retail-store-ui   ClusterIP   172.20.51.141   <none>        80/TCP    17m
> ```

---

## Step-06: Upgrade Retail UI Release
- [Retail UI - Documentation](https://github.com/stacksimplify/retail-store-sample-app-aws/tree/main/src/ui)
```bash
# Upgrade to a new chart version (1.6.2) and change app theme (example)
helm upgrade retail-store-ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.6.2 \
  --set app.theme=orange -n retail-app


# Check release history
helm history retail-store-ui -n retail-app

# Watch Pods during rollout
kubectl get pods -n retail-app -w

# (If service is ClusterIP) Port-forward again to access the app
kubectl port-forward svc/retail-store-ui 30080:80 -n retail-app &
# Then browse:
# http://localhost:30080
```

---

## Step-07: Print Helm Values & Manifests

To verify which values are in effect and what Kubernetes resources were created:

```bash
# Print only overridden values
helm get values retail-store-ui -n retail-app

# Print all values (defaults + overrides)
helm get values retail-store-ui -n retail-app --all

# Print rendered Kubernetes manifests (Deployment, Service, etc.)
helm get manifest retail-store-ui -n retail-app
```

---

## Step-08: Rollback to Previous Release

```bash
# Show release history
helm history retail-store-ui -n retail-app

# Roll back to revision 1
helm rollback retail-store-ui 1 -n retail-app

# Verify rollback
helm list -n retail-app
helm history retail-store-ui -n retail-app
kubectl get pods -n retail-app -w

# (If service is ClusterIP) Port-forward to access the application
kubectl port-forward svc/retail-store-ui 30080:80 -n retail-app &
# http://localhost:30080
```

**Pro Tips**

* `helm rollback retail-store-ui -n retail-app` → rolls back to the last successful release.
* `helm rollback retail-store-ui 1 -n retail-app --dry-run` → preview rollback without applying.

---

## Step-09: Update Application Theme

You can update application values (like theme) during an upgrade.

👉 Pods may not restart automatically because ConfigMap/env changes don’t always trigger a rollout.
If that happens, restart the Deployment manually.

```bash
# First Upgrade to latest version
helm upgrade retail-store-ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 -n retail-app
  
# Change theme to green (stays on chart version 1.3.0)
helm upgrade retail-store-ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version 1.3.0 \
  --set app.theme=green -n retail-app

# If pods don't restart automatically, trigger a rollout:
kubectl rollout restart deployment/retail-store-ui -n retail-app

# Verify pods
kubectl get pods -n retail-app

# (If service is ClusterIP) Port-forward to access the app
kubectl port-forward svc/retail-store-ui 30080:80 -n retail-app &
# http://localhost:30080
```

---

## Step-10: Uninstall Retail UI Release

```bash
# List Helm releases
helm ls -n retail-app

# Uninstall the 'ui' release
helm uninstall retail-store-ui -n retail-app
```

---

## Helm Chart Referece
- [Retail Store Helm Chart - UI App](https://gallery.ecr.aws/aws-containers/retail-store-sample-ui-chart)

---
