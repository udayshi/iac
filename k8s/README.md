# Kubernetes Commands Guide: Basic to Advanced

A comprehensive, step-by-step guide to Kubernetes commands with descriptions and examples.

---

## Table of Contents

1. [Prerequisites & Setup](#prerequisites--setup)
2. [Basic Commands](#basic-commands)
3. [Cluster Management](#cluster-management)
4. [Namespace Management](#namespace-management)
5. [Pod Operations](#pod-operations)
6. [Deployment Management](#deployment-management)
7. [Service & Networking](#service--networking)
8. [ConfigMaps & Secrets](#configmaps--secrets)
9. [Storage Management](#storage-management)
10. [StatefulSets & DaemonSets](#statefulsets--daemonsets)
11. [Scaling & Resource Management](#scaling--resource-management)
12. [Monitoring & Debugging](#monitoring--debugging)
13. [RBAC & Security](#rbac--security)
14. [Advanced Operations](#advanced-operations)

---

## Prerequisites & Setup

Before running any commands, ensure you have:
- `kubectl` installed
- Access to a Kubernetes cluster (local: minikube/Docker Desktop/kind, or cloud: EKS/GKE/AKS)

### Step 1: Verify kubectl installation and cluster access

```bash
# Check kubectl version
kubectl version --client

# Get cluster information
kubectl cluster-info

# View current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch to a specific context
kubectl config use-context <context-name>
```

---

## Basic Commands

### Step 2: Get cluster and API server info

```bash
# Display cluster configuration
kubectl cluster-info dump

# Get API server URL
kubectl cluster-info | grep 'Kubernetes master'

# View kubeconfig file
kubectl config view

# Get API resources available
kubectl api-resources
```

### Step 3: View cluster nodes

```bash
# List all nodes in the cluster
kubectl get nodes

# List nodes with detailed information
kubectl get nodes -o wide

# Get detailed information about a specific node
kubectl describe node <node-name>

# Get node capacity and allocatable resources
kubectl top nodes

# Check node status
kubectl get nodes -o json | jq '.items[].status.conditions'
```

---

## Cluster Management

### Step 4: Check cluster health

```bash
# Get cluster status summary
kubectl get componentstatuses

# View system pods (control plane components)
kubectl get pods -n kube-system

# Check API server logs (if accessible)
kubectl logs -n kube-system -l component=kube-apiserver

# Verify core DNS is running
kubectl get pods -n kube-system | grep coredns
```

### Step 5: Manage node status

```bash
# Cordon a node (mark as unschedulable, prevents new pods)
kubectl cordon <node-name>

# Drain a node (gracefully evict all pods, then cordon it)
kubectl drain <node-name> --ignore-daemonsets

# Uncordon a node (mark as schedulable again)
kubectl uncordon <node-name>

# Get node labels
kubectl get nodes --show-labels

# Add label to a node
kubectl label nodes <node-name> key=value

# Remove label from a node
kubectl label nodes <node-name> key-
```

---

## Namespace Management

### Step 6: Create and manage namespaces

```bash
# List all namespaces
kubectl get namespaces

# Create a new namespace
kubectl create namespace my-app

# Create namespace with YAML
```

Save as `development-namespace.yml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: development
```

```bash
kubectl apply -f development-namespace.yml

# Set default namespace for current context
kubectl config set-context --current --namespace=my-app

# Verify current namespace
kubectl config view --minify | grep namespace

# Get namespace details
kubectl describe namespace my-app

# List resources in a namespace
kubectl get all -n my-app

# Delete a namespace (deletes all resources in it)
kubectl delete namespace my-app
```

---

## Pod Operations

### Step 7: Create and manage pods

```bash
# Create a simple pod from command line
kubectl run nginx-pod --image=nginx --restart=Never

# Create pod with resource limits
kubectl run my-pod --image=busybox --restart=Never --requests=cpu=100m,memory=128Mi --limits=cpu=500m,memory=256Mi

# List all pods
kubectl get pods

# List pods in specific namespace
kubectl get pods -n kube-system

# List pods with wide output (includes node info)
kubectl get pods -o wide

# Get pod details in JSON format
kubectl get pod <pod-name> -o json

# Describe a pod (detailed information)
kubectl describe pod <pod-name>

# Get pod logs
kubectl logs <pod-name>

# Get logs from previous instance (if pod crashed)
kubectl logs <pod-name> --previous

# Stream pod logs in real-time
kubectl logs <pod-name> -f

# Execute command in pod
kubectl exec <pod-name> -- ls -la

# Interactive shell into pod
kubectl exec -it <pod-name> -- /bin/bash

# Copy file from pod to local
kubectl cp <pod-name>:/path/to/file ./local-file

# Copy file from local to pod
kubectl cp ./local-file <pod-name>:/path/to/file

# Delete a pod
kubectl delete pod <pod-name>

# Delete pod with grace period (allows cleanup)
kubectl delete pod <pod-name> --grace-period=30

# Force delete pod immediately
kubectl delete pod <pod-name> --grace-period=0 --force
```

### Step 8: Create pod from YAML

```bash
# Create pod from YAML file
```

Save as `nginx-example-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-example
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

```bash
kubectl apply -f nginx-example-pod.yml

# Get pod status
kubectl get pod nginx-example

# Delete pod
kubectl delete pod nginx-example
```

---

## Deployment Management

### Step 9: Create and update deployments

```bash
# Create a simple deployment
kubectl create deployment nginx-deploy --image=nginx

# List deployments
kubectl get deployments

# Get deployment details with wide output
kubectl get deployments -o wide

# Describe deployment
kubectl describe deployment nginx-deploy

# View deployment YAML
kubectl get deployment nginx-deploy -o yaml

# Scale deployment to 3 replicas
kubectl scale deployment nginx-deploy --replicas=3

# Get replica set information
kubectl get replicasets

# Describe replica set
kubectl describe replicaset <rs-name>
```

### Step 10: Update deployment image

```bash
# Update image in deployment
kubectl set image deployment/nginx-deploy nginx=nginx:1.19

# Check rollout status
kubectl rollout status deployment/nginx-deploy

# View rollout history
kubectl rollout history deployment/nginx-deploy

# Rollback to previous version
kubectl rollout undo deployment/nginx-deploy

# Rollback to specific revision
kubectl rollout undo deployment/nginx-deploy --to-revision=2

# View revision details
kubectl rollout history deployment/nginx-deploy --revision=1
```

### Step 11: Create deployment from YAML

```bash
```

Save as `web-app-deployment.yml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

```bash
kubectl apply -f web-app-deployment.yml

# Verify deployment
kubectl get deployment web-app
kubectl get pods -l app=web
```

---

## Service & Networking

### Step 12: Create and manage services

```bash
# Expose deployment as service (ClusterIP - default)
kubectl expose deployment nginx-deploy --type=ClusterIP --port=80 --target-port=80

# Create LoadBalancer service
kubectl expose deployment nginx-deploy --type=LoadBalancer --port=80 --target-port=80

# Create NodePort service
kubectl expose deployment nginx-deploy --type=NodePort --port=80 --target-port=80

# List services
kubectl get services

# Get service details
kubectl get service nginx-deploy -o wide

# Describe service
kubectl describe service nginx-deploy

# Get service endpoints
kubectl get endpoints nginx-deploy

# Port forward to service
kubectl port-forward service/nginx-deploy 8080:80

# Port forward to pod
kubectl port-forward pod/nginx-deploy-<id> 8080:80
```

### Step 13: Create service from YAML

```bash
```

Save as `web-service.yml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  labels:
    app: web
spec:
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    nodePort: 30080
  selector:
    app: web
```

```bash
kubectl apply -f web-service.yml

# Verify service
kubectl get svc web-service
kubectl describe svc web-service
```

### Step 14: Network policies (if supported)

```bash
# List network policies
kubectl get networkpolicies

# Create network policy
```

Save as `deny-ingress-network-policy.yml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

```bash
kubectl apply -f deny-ingress-network-policy.yml

# Describe network policy
kubectl describe networkpolicy deny-ingress

# Delete network policy
kubectl delete networkpolicy deny-ingress
```

---

## ConfigMaps & Secrets

### Step 15: ConfigMap operations

```bash
# Create ConfigMap from literal values
kubectl create configmap app-config --from-literal=database.host=localhost --from-literal=database.port=5432

# Create ConfigMap from file
echo "key=value" > config.properties
kubectl create configmap app-config --from-file=config.properties

# List ConfigMaps
kubectl get configmaps

# Get ConfigMap details
kubectl describe configmap app-config

# View ConfigMap YAML
kubectl get configmap app-config -o yaml

# Delete ConfigMap
kubectl delete configmap app-config

# Create ConfigMap from YAML
```

Save as `app-settings-configmap.yml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
data:
  app.properties: |
    server.port=8080
    server.host=0.0.0.0
  database.properties: |
    db.host=localhost
    db.port=5432
```

```bash
kubectl apply -f app-settings-configmap.yml
```

### Step 16: Secret operations

```bash
# Create secret from literal values
kubectl create secret generic db-secret --from-literal=username=admin --from-literal=password=secret123

# Create secret from file
echo -n "admin" > username.txt
echo -n "secret123" > password.txt
kubectl create secret generic db-secret --from-file=username.txt --from-file=password.txt

# List secrets
kubectl get secrets

# Get secret details (encoded, not decoded in output)
kubectl describe secret db-secret

# View secret YAML
kubectl get secret db-secret -o yaml

# Decode secret value (base64 decoding)
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 --decode

# Create secret from YAML
```

Save as `api-keys-secret.yml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: api-keys
type: Opaque
stringData:
  api-key: my-secret-key
```

```bash
kubectl apply -f api-keys-secret.yml

# Delete secret
kubectl delete secret db-secret

# Create TLS secret
kubectl create secret tls tls-secret --cert=cert.pem --key=key.pem
```

### Step 17: Mount ConfigMap/Secret in pod

```bash
# Create pod with ConfigMap as environment variable
```

Save as `config-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ['sh', '-c', 'echo $DB_HOST']
    env:
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.host
```

```bash
kubectl apply -f config-pod.yml

# Create pod with Secret as environment variable
```

Save as `secret-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-pod
spec:
  containers:
  - name: app
    image: busybox
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

```bash
kubectl apply -f secret-pod.yml

# Mount ConfigMap as volume
```

Save as `config-volume-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-volume-pod
spec:
  containers:
  - name: app
    image: busybox
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-settings
```

```bash
kubectl apply -f config-volume-pod.yml

# Verify ConfigMap mount
kubectl exec config-volume-pod -- cat /etc/config/app.properties
```

---

## Storage Management

### Step 18: PersistentVolume and PersistentVolumeClaim

```bash
# List PersistentVolumes
kubectl get pv

# List PersistentVolumeClaims
kubectl get pvc

# Describe PersistentVolume
kubectl describe pv <pv-name>

# Describe PersistentVolumeClaim
kubectl describe pvc <pvc-name>

# Create PersistentVolumeClaim
```

Save as `my-pvc.yml`:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

```bash
kubectl apply -f my-pvc.yml

# Use PVC in pod
```

Save as `storage-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: storage-pod
spec:
  containers:
  - name: app
    image: busybox
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

```bash
kubectl apply -f storage-pod.yml

# Delete PVC
kubectl delete pvc my-pvc
```

### Step 19: Storage Classes

```bash
# List storage classes
kubectl get storageclass

# Describe storage class
kubectl describe storageclass standard

# Create custom storage class
```

Save as `fast-storage-class.yml`:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: pd.csi.storage.gke.io
parameters:
  type: pd-ssd
```

```bash
kubectl apply -f fast-storage-class.yml

# Get storage class details
kubectl get sc fast-storage -o yaml
```

---

## StatefulSets & DaemonSets

### Step 20: StatefulSet operations

```bash
# Create StatefulSet
```

Save as `mysql-statefulset.yml`:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "password"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

```bash
kubectl apply -f mysql-statefulset.yml

# List StatefulSets
kubectl get statefulsets

# Describe StatefulSet
kubectl describe statefulset mysql

# Get StatefulSet pods (note: ordered names)
kubectl get pods -l app=mysql

# Scale StatefulSet
kubectl scale statefulset mysql --replicas=5

# Delete StatefulSet and PVCs
kubectl delete statefulset mysql --cascade=orphan
kubectl delete pvc -l app=mysql
```

### Step 21: DaemonSet operations

```bash
# Create DaemonSet
```

Save as `node-monitor-daemonset.yml`:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
spec:
  selector:
    matchLabels:
      app: node-monitor
  template:
    metadata:
      labels:
        app: node-monitor
    spec:
      containers:
      - name: monitor
        image: busybox
        command: ['sh', '-c', 'while true; do echo "Monitoring node"; sleep 60; done']
```

```bash
kubectl apply -f node-monitor-daemonset.yml

# List DaemonSets
kubectl get daemonsets

# Describe DaemonSet
kubectl describe daemonset node-monitor

# Get DaemonSet pods (one per node)
kubectl get pods -l app=node-monitor

# Delete DaemonSet
kubectl delete daemonset node-monitor
```

---

## Scaling & Resource Management

### Step 22: Horizontal Pod Autoscaling

```bash
# Create HorizontalPodAutoscaler from command line
kubectl autoscale deployment nginx-deploy --min=2 --max=5 --cpu-percent=80

# List HPA
kubectl get hpa

# Describe HPA
kubectl describe hpa nginx-deploy

# Watch HPA status
kubectl get hpa -w

# Create HPA from YAML
```

Save as `web-app-hpa.yml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

```bash
kubectl apply -f web-app-hpa.yml

# Delete HPA
kubectl delete hpa nginx-deploy
```

### Step 23: Resource quotas and limits

```bash
# Create resource quota for namespace
```

Save as `compute-quota.yml`:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: my-app
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
    services.nodeports: "5"
```

```bash
kubectl apply -f compute-quota.yml

# List resource quotas
kubectl get resourcequota -n my-app

# Describe resource quota
kubectl describe resourcequota compute-quota -n my-app

# Create limit range for namespace
```

Save as `memory-cpu-limits.yml`:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: memory-cpu-limits
  namespace: my-app
spec:
  limits:
  - max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
    type: Container
```

```bash
kubectl apply -f memory-cpu-limits.yml

# List limit ranges
kubectl get limitrange -n my-app

# Describe limit range
kubectl describe limitrange memory-cpu-limits -n my-app
```

---

## Monitoring & Debugging

### Step 24: Pod and cluster monitoring

```bash
# Get resource usage of pods
kubectl top pods

# Get resource usage of specific pod
kubectl top pod <pod-name>

# Get resource usage of nodes
kubectl top nodes

# Get events in cluster
kubectl get events

# Get events in specific namespace
kubectl get events -n my-app

# Watch events in real-time
kubectl get events -w

# Check pod status and conditions
kubectl describe pod <pod-name>

# Get previous pod logs (if pod restarted)
kubectl logs <pod-name> --previous

# Get logs from multiple pods
kubectl logs -l app=web --all-containers=true

# Get specific number of log lines
kubectl logs <pod-name> --tail=50

# Get logs with timestamps
kubectl logs <pod-name> --timestamps=true

# Stream logs from pod
kubectl logs -f <pod-name>
```

### Step 25: Debugging tools and techniques

```bash
# Get detailed pod information
kubectl get pod <pod-name> -o yaml

# Check pod conditions
kubectl describe pod <pod-name>

# Execute debug command in pod
kubectl exec <pod-name> -- env

# Check pod events
kubectl describe pod <pod-name> | grep -A 10 "Events:"

# Get pod network info
kubectl exec <pod-name> -- hostname -i
kubectl exec <pod-name> -- ip route

# Debug with debug pod (Alpine with tools)
kubectl run -it --rm debug --image=alpine --restart=Never -- sh

# Debug pod network connectivity
kubectl run -it --rm netshoot --image=nicolaka/netshoot --restart=Never -- bash

# Check node logs (requires node access)
kubectl debug node/<node-name> -it --image=ubuntu

# Get kubelet logs
kubectl logs -n kube-system -l component=kubelet

# Watch pod creation in real-time
kubectl get pods -w

# Watch specific resource changes
kubectl get deployment -w

# Troubleshoot pod startup issues
kubectl describe pod <pod-name>  # Check Events and Conditions sections
```

### Step 26: Metrics and monitoring

```bash
# Enable metrics-server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait for metrics-server to be ready
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s

# Get pod metrics
kubectl top pods

# Get pod metrics with labels
kubectl top pods --show-labels

# Get node metrics
kubectl top nodes

# Monitor resource usage over time
kubectl top pods --containers

# Get custom metrics (requires metrics-server)
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | jq .
```

---

## RBAC & Security

### Step 27: Role-Based Access Control (RBAC)

```bash
# List roles
kubectl get roles

# List roles in specific namespace
kubectl get roles -n my-app

# Describe role
kubectl describe role <role-name>

# Create role from YAML
```

Save as `pod-reader-role.yml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/logs"]
  verbs: ["get"]
```

```bash
kubectl apply -f pod-reader-role.yml

# List cluster roles
kubectl get clusterroles

# List role bindings
kubectl get rolebindings

# Describe role binding
kubectl describe rolebinding <binding-name>

# Create role binding from YAML
```

Save as `read-pods-role-binding.yml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: User
  name: "user@example.com"
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl apply -f read-pods-role-binding.yml

# Check what permissions you have
kubectl auth can-i get pods

# Check if user can perform action
kubectl auth can-i get pods --as=user@example.com

# Check all permissions for a user
kubectl auth can-i --list --as=user@example.com
```

### Step 28: ServiceAccount and Pod Security

```bash
# List service accounts
kubectl get serviceaccounts

# Create service account
kubectl create serviceaccount my-app-sa

# Get service account details
kubectl describe serviceaccount my-app-sa

# Use service account in pod
```

Save as `app-with-sa.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sa
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: busybox
    command: ['sleep', '3600']
```

```bash
kubectl apply -f app-with-sa.yml

# Get service account token
kubectl describe secret $(kubectl get secret -n default -l serviceaccount=my-app-sa -o jsonpath='{.items[0].metadata.name}')

# Create pod with security context
```

Save as `security-pod.yml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: app
    image: busybox
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
```

```bash
kubectl apply -f security-pod.yml

# View pod security policy (if enabled)
kubectl get psp
```

---

## Advanced Operations

### Step 29: Custom Resources and Controllers

```bash
# List available API resources
kubectl api-resources

# List custom resources
kubectl get crd

# Describe CRD
kubectl describe crd <crd-name>

# Create custom resource instance (requires its CRD)
```

Save as `my-custom-resource.yml`:

```yaml
apiVersion: example.com/v1
kind: MyCustomResource
metadata:
  name: my-instance
spec:
  field1: value1
```

```bash
kubectl apply -f my-custom-resource.yml

# Watch custom resource
kubectl get <custom-resource> -w

# Delete custom resource
kubectl delete <custom-resource> my-instance
```

### Step 30: Helm basics (if Helm installed)

```bash
# Check Helm version
helm version

# Add Helm repository
helm repo add stable https://charts.helm.sh/stable

# Update Helm repositories
helm repo update

# Search for charts
helm search repo nginx

# Install Helm chart
helm install my-nginx stable/nginx-ingress

# List installed releases
helm list

# Get release details
helm show values stable/nginx-ingress

# Upgrade release
helm upgrade my-nginx stable/nginx-ingress

# Rollback release to previous version
helm rollback my-nginx

# Uninstall release
helm uninstall my-nginx

# Create Helm chart template
helm create my-chart

# Validate Helm chart
helm lint my-chart

# Package Helm chart
helm package my-chart

# Install chart from local file
helm install my-release ./my-chart
```

### Step 31: Batch jobs and CronJobs

```bash
# Create Job
```

Save as `data-processor-job.yml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processor
spec:
  template:
    spec:
      containers:
      - name: processor
        image: busybox
        command: ['sh', '-c', 'echo "Processing data"; sleep 5; echo "Done"']
      restartPolicy: Never
  backoffLimit: 3
```

```bash
kubectl apply -f data-processor-job.yml

# List jobs
kubectl get jobs

# Describe job
kubectl describe job data-processor

# Get job status
kubectl get job data-processor -o wide

# View job logs
kubectl logs job/data-processor

# Delete job (cascading deletion)
kubectl delete job data-processor

# Create CronJob
```

Save as `daily-backup-cronjob.yml`:

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: busybox
            command: ['sh', '-c', 'echo "Running backup"']
          restartPolicy: OnFailure
```

```bash
kubectl apply -f daily-backup-cronjob.yml

# List CronJobs
kubectl get cronjobs

# Describe CronJob
kubectl describe cronjob daily-backup

# Manually trigger CronJob
kubectl create job --from=cronjob/daily-backup manual-backup-run

# Delete CronJob
kubectl delete cronjob daily-backup
```

### Step 32: Ingress and traffic routing

```bash
# List Ingress resources
kubectl get ingress

# Describe Ingress
kubectl describe ingress <ingress-name>

# Create Ingress
```

Save as `web-ingress.yml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

```bash
kubectl apply -f web-ingress.yml

# View Ingress YAML
kubectl get ingress web-ingress -o yaml

# Delete Ingress
kubectl delete ingress web-ingress

# Get Ingress IP address
kubectl get ingress web-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Step 33: Apply and manage resources with files

```bash
# Apply single YAML file
kubectl apply -f deployment.yaml

# Apply multiple YAML files in directory
kubectl apply -f ./k8s/

# Apply from URL
kubectl apply -f https://raw.githubusercontent.com/example/repo/main/deployment.yaml

# Apply with dry-run (preview changes without applying)
kubectl apply -f deployment.yaml --dry-run=client

# Apply with server-side dry-run
kubectl apply -f deployment.yaml --dry-run=server

# Show diff before applying
kubectl diff -f deployment.yaml

# Delete resources from file
kubectl delete -f deployment.yaml

# Replace (delete and recreate) resources
kubectl replace -f deployment.yaml --force

# Apply with specific namespace
kubectl apply -f deployment.yaml -n my-app

# Get all resources created from label
kubectl get all -l app=web
```

### Step 34: Patch and edit resources

```bash
# Edit resource in default editor
kubectl edit deployment nginx-deploy

# Edit in JSON format
kubectl edit deployment nginx-deploy -o json

# Patch resource with JSON merge
kubectl patch deployment nginx-deploy -p '{"spec":{"replicas":5}}'

# Patch using strategic merge patch
kubectl patch deployment nginx-deploy --type='json' -p='[{"op":"replace","path":"/spec/replicas","value":5}]'

# Set image (common patch operation)
kubectl set image deployment/nginx-deploy nginx=nginx:1.20

# Set environment variable
kubectl set env deployment/nginx-deploy ENV_VAR=value

# Set resource limits
kubectl set resources deployment/nginx-deploy --limits=cpu=500m,memory=256Mi --requests=cpu=100m,memory=64Mi
```

### Step 35: Cleanup and garbage collection

```bash
# Delete completed pods
kubectl delete pod --field-selector status.phase=Succeeded

# Delete failed pods
kubectl delete pod --field-selector status.phase=Failed

# Delete pods by age (older than 1 hour)
kubectl delete pod --all --grace-period=0 --force

# List unused PVCs
kubectl get pvc --all-namespaces

# Delete unused PVC
kubectl delete pvc <pvc-name>

# Clean up old ReplicaSets
kubectl delete replicaset --all-namespaces --all-failed=true

# List resources with no owner (orphaned)
kubectl get all --all-namespaces | grep none

# Delete orphaned resources
kubectl delete pod <orphaned-pod-name>

# Clean up all completed jobs
kubectl delete job --field-selector status.successful=1
```

---

## Quick Reference Commands

### Context and Cluster Info
```bash
kubectl cluster-info
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <context>
```

### Get Resources
```bash
kubectl get nodes
kubectl get pods [--all-namespaces] [-n namespace]
kubectl get services
kubectl get deployments
kubectl get configmaps
kubectl get secrets
```

### Create Resources
```bash
kubectl apply -f <file.yaml>
kubectl create deployment <name> --image=<image>
kubectl expose deployment <name> --type=<type> --port=<port>
```

### Debugging
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
kubectl port-forward <resource> <local-port>:<remote-port>
```

### Modify Resources
```bash
kubectl scale deployment <name> --replicas=<count>
kubectl set image deployment/<name> <container>=<image>
kubectl edit <resource-type> <resource-name>
```

### Delete Resources
```bash
kubectl delete pod <pod-name>
kubectl delete deployment <name>
kubectl delete namespace <name>
```

---

## Common Scenarios

### Deploy an application and expose it
```bash
# Step 1: Create deployment
kubectl create deployment myapp --image=myapp:1.0

# Step 2: Scale to 3 replicas
kubectl scale deployment myapp --replicas=3

# Step 3: Expose as service
kubectl expose deployment myapp --type=LoadBalancer --port=8080 --target-port=8080

# Step 4: Get service info
kubectl get svc myapp

# Step 5: Access the service
# For LoadBalancer: use the EXTERNAL-IP
# For NodePort: use <node-ip>:<node-port>
```

### Debug a failing pod
```bash
# Step 1: Check pod status
kubectl describe pod <failing-pod>

# Step 2: Check logs
kubectl logs <failing-pod>

# Step 3: Check previous logs if crashed
kubectl logs <failing-pod> --previous

# Step 4: Exec into pod for debugging
kubectl exec -it <failing-pod> -- /bin/bash

# Step 5: Check events
kubectl get events | grep <pod-name>
```

### Perform a rolling update
```bash
# Step 1: Update deployment image
kubectl set image deployment/myapp myapp=myapp:2.0

# Step 2: Monitor rollout
kubectl rollout status deployment/myapp

# Step 3: If needed, rollback
kubectl rollout undo deployment/myapp
```
