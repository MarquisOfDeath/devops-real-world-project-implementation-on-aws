# 08-03: Kubernetes Services

### **Step-01: Verify existing Deployment**

```bash
kubectl get deploy catalog-deployment
kubectl get pods -l app=catalog
```

Ensure 3 replicas are running.

---

### **Step-02: Create ClusterIP Service**

**File:** `02_catalog_clusterip_service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog-service
  namespace: default
  labels:
    app: catalog
    env: dev
    createdBy: MarquisOfDeath
spec:
  type: ClusterIP

  # Selector MUST match the Pod template labels exactly
  selector:
    app: catalog

  ports:
  - name: http # Named port for clean Ingress mapping
    protocol: TCP
    port: 80 # Standard web traffic entry port for other apps in the cluster
    targetPort: http # References the named containerPort "http" (8080) from your deployment. 
    # "http" will work only if you have explicitly given the name "http" to the containerPort inside your Deployment's template.

    # Production Traffic & Reliability Controls
  sessionAffinity: None # Ensures standard, even round-robin load balancing across replicas
  internalTrafficPolicy: Cluster # Normal routing to all ready endpoints across the cluster

```

---

### **Step-03: Apply and verify**

```bash
kubectl apply -f 02_catalog_clusterip_service.yaml
kubectl get svc
kubectl describe svc catalog-service
```

Highlight output:

* **Type:** ClusterIP
* **ClusterIP:** 10.x.x.x
* **Ports:** 8080/TCP
* **Endpoints:** Pod IPs behind the service

---

### **Step-04: Inspect EndpointSlices and Pod Matching**

After creating the service, verify how Kubernetes automatically links **Pods to the Service** using **labels**.

```bash
kubectl get pods -o wide
kubectl get endpointslices -l kubernetes.io/service-name=catalog
```

You should see something like:

```
NAME                    ADDRESSTYPE   PORTS   ENDPOINTS
catalog-service-abcde   IPv4          8080    10.0.11.45,10.0.12.18,10.0.13.29
```

- ✅ **Key concept:**
Kubernetes **uses the selector labels** in the Service definition to automatically discover Pods that match those labels.
It then creates an **EndpointSlice** object listing the **Pod IPs** and **ports** that belong to that Service.

> Even if pods restart and get new IPs, the EndpointSlice automatically updates ensuring the Service always routes traffic to healthy, matching pods.

---

### **Step-05: Verify Service Connectivity (Internal Test)**

Run a test pod inside the same namespace:

```bash
kubectl run test --image=curlimages/curl -it --rm -- sh
```

Inside the pod:

```bash
curl http://catalog-service:80/topology
```

Expected output:

```json
{"databaseEndpoint":"N/A","persistenceProvider":"in-memory"}
```

Then exit.

> “This proves that even though our pods have dynamic IPs, we can consistently reach the catalog application using the service name.”

---

### **Step-06: DNS Resolution Check**

```bash
kubectl run dns-test --image=busybox:1.28 -it --rm
```

Inside pod:

```bash
nslookup catalog-service
```

Explain how Kubernetes DNS automatically creates entries like:

```
catalog-service.default.svc.cluster.local
```

---

## Step-07: Access the Application via Port Forwarding
```
# Expose the Pod locally using:
kubectl port-forward service/catalog-service 7080:80 >/dev/null 2>&1 &

# Topology Endpoint
http://localhost:7080/topology

# Health Endpoint
http://localhost:7080/health

# Catalog - Get Products
http://localhost:7080/catalog/products

# Catalog - Get Products By ID
http://localhost:7080/catalog/products/d77f9ae6-e9a8-4a3e-86bd-b72af75cbc49

# Catalog - Get Size
http://localhost:7080/catalog/size

# Catalog - Get Tags
http://localhost:7080/catalog/tags
```


## Step-08: Clean Up 

```bash
# Delete k8s Resources
kubectl delete svc catalog-service
kubectl delete deploy catalog-deployment

### OR ###

# Delete using YAML files
kubectl delete -f catalog_k8s_manifests
```

