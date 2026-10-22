# Kubernetes Ingress - HTTPS (with ACM + Route53)

> **Pre-requisite Note**  
> To follow along with the HTTPS demo, you should already have a **registered domain name in AWS Route53**.  
> This is important because ACM (AWS Certificate Manager) requires a domain for SSL certificate validation.  
> For learning purposes, you don’t need to actually implement this step end-to-end. Just understand the flow.


## Step-01: What we’ll do
1. Create **ACM cert** + **Route53 DNS**.
2. Deploy **HTTPS Ingress**, test end-to-end.
3. Undeploy the resources after learning

---

## Step-02: SSL Certificate (ACM) + DNS (Route53)

1. **Request Public Certificate** in **AWS Certificate Manager (ACM)**:

   ```
   themarquisofdeathmarvel.co.in
   ```
2. **Validate via DNS**: ACM will show CNAME records to create in **Route53 → Hosted Zone: themarquisofdeathmarvel.co.in**.
3. Wait for certificate **Status: Issued**.

> Keep the certificate in the same AWS region as your EKS/ALB.

---

## Step-03: Kubernetes Manifests (Ingress - HTTPS)

Folder: `https_retail_store_k8s_manifests/`

* [01_catalog](./https_retail_store_k8s_manifests/01_catalog/)
* [02_cart](./https_retail_store_k8s_manifests/02_cart/)
* [03_checkout](./https_retail_store_k8s_manifests/03_checkout/)
* [04_orders](./https_retail_store_k8s_manifests/04_orders/)
* [05_ui](./https_retail_store_k8s_manifests/05_ui/)
* [06 Ingress Instance Mode: 06_ingress/01_ingress_http_instance_mode.yaml](./https_retail_store_k8s_manifests/06_ingress/01_ingress_https_instance_mode.yaml)

* [06 Ingress IP Mode: 06_ingress/02_ingress_http_ip_mode.yaml](./https_retail_store_k8s_manifests/06_ingress/02_ingress_https_ip_mode.yaml)

### Update both Ingress Manifests with SSL Certificate ARN 
```yaml
    ## SSL Settings
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-south-1:478416475193:certificate/b2f2572d-a120-4820-b965-7fc22ced681b
```

![K8s Ingress HTTP Flow](./images/02_ingress-https.png)

### Deploy Kubernetes Ingress HTTPS

```bash
# Apply all HTTPS manifests (includes Ingress with TLS annotations)
kubectl apply -R -f https_retail_store_k8s_manifests/
```

### Create DNS record (Route53)

After ALB is provisioned (check ADDRESS column):

```bash
kubectl get ingress 
```

In **Route53 → themarquisofdeathmarvel.co.in**, create **A record with Alias**:

```

Now, route your traffic to it:
1. Open the AWS Route 53 console and click on your Hosted Zone (themarquisofdeathmarvel.co.in).
2. Click Create record.
3. Record name: Leave it blank for the root domain (or enter www if you are setting up the www subdomain).
4. Record type: Choose A – Routes traffic to an IPv4 address and some AWS resources.
5. Toggle the Alias switch to ON.
6. In the Route traffic to dropdown:
	• Select Alias to Application and Classic Load Balancer.
	• Select the AWS Region where your cluster is.
	• Select your ALB name from the list that appears.


```

---

## Step-04: Verify Kubernetes Ingress - HTTPS

```bash
# Ingress overall
kubectl get ingress -A

shaktiswarupmohanty@Shakti-MacBook-Air Kubernetes_Ingress_https % kubectl get ingress -A
NAMESPACE   NAME                               CLASS   HOSTS   ADDRESS                                                                    PORTS   AGE
default     retail-store-https-instance-mode   alb     *       retail-store-https-instance-mode-1526458705.ap-south-1.elb.amazonaws.com   80      73s
default     retail-store-https-ip-mode         alb     *       retail-store-https-ip-mode-1044313028.ap-south-1.elb.amazonaws.com         80      73s
shaktiswarupmohanty@Shakti-MacBook-Air Kubernetes_Ingress_https % 

# Inspect annotations, rules, and TLS
kubectl describe ingress retail-store-https-instance-mode
kubectl describe ingress retail-store-https-ip-mode

# Test HTTPS with SNI
curl -vk https://themarquisofdeathmarvel.co.in

shaktiswarupmohanty@Shakti-MacBook-Air Kubernetes_Ingress_https % nslookup retail-store-https-instance-mode-1526458705.ap-south-1.elb.amazonaws.com
Server:		192.168.1.254
Address:	192.168.1.254#53

Non-authoritative answer:
Name:	retail-store-https-instance-mode-1526458705.ap-south-1.elb.amazonaws.com
Address: 15.207.123.84
Name:	retail-store-https-instance-mode-1526458705.ap-south-1.elb.amazonaws.com
Address: 13.205.44.68
Name:	retail-store-https-instance-mode-1526458705.ap-south-1.elb.amazonaws.com
Address: 13.206.191.4


shaktiswarupmohanty@Shakti-MacBook-Air Kubernetes_Ingress_https % nslookup retail-store-https-ip-mode-1044313028.ap-south-1.elb.amazonaws.com
Server:		192.168.1.254
Address:	192.168.1.254#53

Non-authoritative answer:
Name:	retail-store-https-ip-mode-1044313028.ap-south-1.elb.amazonaws.com
Address: 65.1.24.148
Name:	retail-store-https-ip-mode-1044313028.ap-south-1.elb.amazonaws.com
Address: 13.202.39.34
Name:	retail-store-https-ip-mode-1044313028.ap-south-1.elb.amazonaws.com
Address: 13.204.247.74

shaktiswarupmohanty@Shakti-MacBook-Air Kubernetes_Ingress_https % 


```

> Expect a valid TLS handshake (issued by ACM) and Retail Store UI over **HTTPS**.

--- 

## Step-05: Undeploy Ingress HTTPS 

```bash
kubectl delete -R -f https_retail_store_k8s_manifests
```

---


