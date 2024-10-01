To deploy your applications and databases (PostgreSQL and MS SQL) within an **EKS cluster**, you will use **Kubernetes manifests** (YAML files) to define the resources for your databases, applications, and services. Here's a step-by-step guide, from setting up **Kubernetes StatefulSets** for the databases to deploying your applications with appropriate configurations.

### Steps for Deploying Applications and Databases in EKS:

1. **Install and Configure kubectl for EKS:**
   You need to have **kubectl** and **aws-iam-authenticator** installed to interact with your EKS cluster. After deploying the EKS cluster using Terraform, follow these steps to configure access:

   - **Get kubeconfig:**
     After your EKS cluster is deployed, retrieve the Kubernetes configuration using:
     ```bash
     aws eks update-kubeconfig --region <your-region> --name <eks-cluster-name>
     ```

   - **Verify the connection:**
     Check the connection to your EKS cluster:
     ```bash
     kubectl get svc
     ```

2. **Deploy Databases (PostgreSQL & MS SQL) using Kubernetes StatefulSets:**

   StatefulSets are ideal for databases because they provide stable network identities and persistent storage across pod restarts.

   #### 2.1. **PostgreSQL StatefulSet:**

   - Create a persistent volume claim (PVC) and StatefulSet for PostgreSQL.
   - Use `ConfigMap` for configuration and `Secret` for sensitive data like passwords.

   ```yaml
   # postgres-configmap.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: postgres-config
   data:
     POSTGRES_DB: "oesysdb"
     POSTGRES_USER: "postgres"
     POSTGRES_PASSWORD: "password"
   ```

   ```yaml
   # postgres-statefulset.yaml
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: postgres
   spec:
     serviceName: "postgres"
     replicas: 1
     selector:
       matchLabels:
         app: postgres
     template:
       metadata:
         labels:
           app: postgres
       spec:
         containers:
         - name: postgres
           image: postgres:13
           ports:
           - containerPort: 5432
           envFrom:
           - configMapRef:
               name: postgres-config
           volumeMounts:
           - name: postgres-storage
             mountPath: /var/lib/postgresql/data
     volumeClaimTemplates:
     - metadata:
         name: postgres-storage
       spec:
         accessModes: [ "ReadWriteOnce" ]
         resources:
           requests:
             storage: 20Gi
   ```

   - Apply the configuration:
     ```bash
     kubectl apply -f postgres-configmap.yaml
     kubectl apply -f postgres-statefulset.yaml
     ```

   #### 2.2. **MS SQL StatefulSet:**

   Similar to PostgreSQL, deploy **MS SQL** using StatefulSets and Persistent Volumes.

   ```yaml
   # mssql-configmap.yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: mssql-config
   data:
     MSSQL_SA_PASSWORD: "StrongPassword123!"
     ACCEPT_EULA: "Y"
   ```

   ```yaml
   # mssql-statefulset.yaml
   apiVersion: apps/v1
   kind: StatefulSet
   metadata:
     name: mssql
   spec:
     serviceName: "mssql"
     replicas: 1
     selector:
       matchLabels:
         app: mssql
     template:
       metadata:
         labels:
           app: mssql
       spec:
         containers:
         - name: mssql
           image: mcr.microsoft.com/mssql/server:2019-latest
           ports:
           - containerPort: 1433
           envFrom:
           - configMapRef:
               name: mssql-config
           volumeMounts:
           - name: mssql-storage
             mountPath: /var/opt/mssql
     volumeClaimTemplates:
     - metadata:
         name: mssql-storage
       spec:
         accessModes: [ "ReadWriteOnce" ]
         resources:
           requests:
             storage: 20Gi
   ```

   - Apply the MS SQL StatefulSet:
     ```bash
     kubectl apply -f mssql-configmap.yaml
     kubectl apply -f mssql-statefulset.yaml
     ```

   You now have both PostgreSQL and MS SQL deployed as StatefulSets inside your EKS cluster.

---

### 3. **Deploy the Applications (OESYS, Mailing, LongView) in EKS:**

Assume you have Docker images of your applications available on DockerHub or a private registry. You’ll use **Deployments** to manage these applications in Kubernetes.

#### 3.1. **OESYS App Deployment:**

```yaml
# oesys-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oesys-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: oesys
  template:
    metadata:
      labels:
        app: oesys
    spec:
      containers:
      - name: oesys
        image: your-dockerhub-username/oesys-app:latest
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "postgres"
        - name: DB_PORT
          value: "5432"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
```

#### 3.2. **Mailing App Deployment:**

```yaml
# mailing-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mailing-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mailing
  template:
    metadata:
      labels:
        app: mailing
    spec:
      containers:
      - name: mailing
        image: your-dockerhub-username/mailing-app:latest
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "mssql"
        - name: DB_PORT
          value: "1433"
        - name: DB_USER
          value: "sa"
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mssql-secret
              key: MSSQL_SA_PASSWORD
```

#### 3.3. **LongView App Deployment:**

```yaml
# longview-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: longview-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: longview
  template:
    metadata:
      labels:
        app: longview
    spec:
      containers:
      - name: longview
        image: your-dockerhub-username/longview-app:latest
        ports:
        - containerPort: 80
```

- Apply all deployments:
  ```bash
  kubectl apply -f oesys-deployment.yaml
  kubectl apply -f mailing-deployment.yaml
  kubectl apply -f longview-deployment.yaml
  ```

---

### 4. **Expose Applications using Kubernetes Services:**

Each application can be exposed via **Kubernetes Services**. You can use **LoadBalancer** type services to expose your applications externally through the ALB created in your Terraform configuration.

```yaml
# oesys-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: oesys-service
spec:
  type: LoadBalancer
  selector:
    app: oesys
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# mailing-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: mailing-service
spec:
  type: LoadBalancer
  selector:
    app: mailing
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# longview-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: longview-service
spec:
  type: LoadBalancer
  selector:
    app: longview
  ports:
  - port: 80
    targetPort: 80
```

- Apply the services:
  ```bash
  kubectl apply -f oesys-service.yaml
  kubectl apply -f mailing-service.yaml
  kubectl apply -f longview-service.yaml
  ```

The `LoadBalancer` service will provision a public-facing load balancer (mapped to the ALB created earlier via Terraform).

---

### 5. **Monitoring (Prometheus and Grafana):**

- You can deploy **Prometheus** and **Grafana** for monitoring. Typically, these are deployed as **Helm charts** in Kubernetes.

   - **Install Prometheus:**
     ```bash
     helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
     helm repo update
     helm install prometheus prometheus-community/prometheus
     ```

   - **Install Grafana:**
     ```bash
     helm repo add grafana https://grafana.github.io/helm-charts
     helm repo update
     helm install grafana grafana/grafana
     ```



---

### 6. **Accessing the Applications:**

Once the services are created, you can access the applications via the **AWS LoadBalancer** DNS names. You can retrieve the DNS name using:

```bash
kubectl get svc oesys-service mailing-service longview-service
```

You’ll see the **external IP** or **DNS** assigned to your services by the LoadBalancer.

---

### Summary:

1. **Set up** and configure **EKS** with **kubectl**.
2. **Deploy databases** (PostgreSQL and MS SQL) as **StatefulSets** with persistent volumes.
3. **Deploy applications** (OESYS, Mailing, LongView) as **Deployments**.
4. **Expose services** using **Kubernetes Services** with **LoadBalancer** to leverage the **ALB**.
5. (Optional) Set up **monitoring** with Prometheus and Grafana.
  
This approach provides a highly scalable and fault-tolerant deployment model, with the ability to easily add new services or modify configurations as required.