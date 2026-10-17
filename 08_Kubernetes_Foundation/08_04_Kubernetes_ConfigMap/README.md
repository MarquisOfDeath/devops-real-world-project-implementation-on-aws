# 08-04: Kubernetes ConfigMap – Catalog Microservice

In this demo, we’ll learn how to use a **Kubernetes ConfigMap** to externalize application configuration for our **Catalog microservice**.

- [Catalog Microservice - Documentation](https://github.com/stacksimplify/retail-store-sample-app-aws/tree/main/src/catalog)

---

## **Step-01: Create ConfigMap**

**Manifest:** `03_catalog_configmap.yaml`

```yaml
apiVersion: v1
data:
  RETAIL_CATALOG_PERSISTENCE_DB_NAME: catalogdb
  RETAIL_CATALOG_PERSISTENCE_ENDPOINT: ""
  RETAIL_CATALOG_PERSISTENCE_USER: "catalog_user"
  RETAIL_CATALOG_PERSISTENCE_PASSWORD: ""
  RETAIL_CATALOG_PERSISTENCE_PROVIDER: in-memory
  RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT: "5"
  MY_CREATOR: "MarquisOfDeath" ## added just for fun, not used by the application
kind: ConfigMap
metadata:
  name: catalog
  namespace: default

```

> 🔹 Even though the defaults are already set in the app, we explicitly define them in the ConfigMap.
> This demonstrates *Configuration as Code* — making all runtime configuration visible and manageable via Kubernetes manifests.

---

## **Step-02: Update Deployment to use ConfigMap**

**Manifest:** `01_catalog_deployment.yaml`

Under the container section, add:

```yaml
      containers:
      - image: public.ecr.aws/aws-containers/retail-store-sample-catalog:1.3.0
        imagePullPolicy: IfNotPresent
        name: catalog-pod-container
        envFrom:
        - configMapRef:
            name: catalog
```

> This tells Kubernetes to load all key-value pairs from the ConfigMap as environment variables inside the container.

---

## **Step-03: Deploy and Verify**

```bash
kubectl apply -f catalog_k8s_manifests/
```
==================

shaktiswarupmohanty@Shakti-MacBook-Air configmap % kubectl get all -o wide                         
NAME                          READY   STATUS    RESTARTS   AGE    IP            NODE                                         NOMINATED NODE   READINESS GATES
pod/catalog-987d49fd8-29cq5   1/1     Running   0          116s   10.0.10.230   ip-10-0-10-151.ap-south-1.compute.internal   <none>           <none>
pod/catalog-987d49fd8-2pd99   1/1     Running   0          116s   10.0.12.222   ip-10-0-12-86.ap-south-1.compute.internal    <none>           <none>
pod/catalog-987d49fd8-4z522   1/1     Running   0          116s   10.0.11.160   ip-10-0-11-212.ap-south-1.compute.internal   <none>           <none>

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE    SELECTOR
service/catalog-service   ClusterIP   172.20.167.50   <none>        8080/TCP   116s   app.kubernetes.io/name=catalog
service/kubernetes        ClusterIP   172.20.0.1      <none>        443/TCP    42h    <none>

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS              IMAGES                                                            SELECTOR
deployment.apps/catalog   3/3     3            3           117s   catalog-pod-container   public.ecr.aws/aws-containers/retail-store-sample-catalog:1.3.0   app.kubernetes.io/name=catalog

NAME                                DESIRED   CURRENT   READY   AGE    CONTAINERS              IMAGES                                                            SELECTOR
replicaset.apps/catalog-987d49fd8   3         3         3       117s   catalog-pod-container   public.ecr.aws/aws-containers/retail-store-sample-catalog:1.3.0   app.kubernetes.io/name=catalog,pod-template-hash=987d49fd8
shaktiswarupmohanty@Shakti-MacBook-Air configmap % 

==============

Once the pod is running, verify environment variables inside the container:

```bash
kubectl exec -it <catalog-pod-name> -- env
```

You should see all environment variables from the ConfigMap:

```
RETAIL_CATALOG_PERSISTENCE_PROVIDER=in-memory
RETAIL_CATALOG_PERSISTENCE_DB_NAME=catalogdb
RETAIL_CATALOG_PERSISTENCE_USER=catalog_user
RETAIL_CATALOG_PERSISTENCE_CONNECT_TIMEOUT=5
RETAIL_CATALOG_PERSISTENCE_ENDPOINT=
RETAIL_CATALOG_PERSISTENCE_PASSWORD=
```
===============

shaktiswarupmohanty@Shakti-MacBook-Air configmap % kubectl port-forward service/catalog-service 6090:8080
Forwarding from 127.0.0.1:6090 -> 8080
Forwarding from [::1]:6090 -> 8080
Handling connection for 6090
Handling connection for 6090
Handling connection for 6090

================

---

## **Step-04: Clean-Up**

```bash
kubectl delete -f catalog_k8s_manifests/
```

This will delete all the resources (Deployment, Service, ConfigMap) created for this demo.

---

## ✅ **Summary**

* ConfigMaps help externalize configuration from the container image.
* We defined all environment variables explicitly, even defaults.
* Deployment consumed ConfigMap via `envFrom`.
* Verified that environment variables were successfully injected into the container.

---

