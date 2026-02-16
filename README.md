# Kubernetes phpMyAdmin with Persistent MySQL Database

This project deploys phpMyAdmin with a persistent MySQL database on Kubernetes (Docker Desktop). The database persists data even when pods are deleted and recreated.

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl configured to use docker-desktop context

## Project Structure

```
newkube8s/
├── mysql-pv.yaml              # Persistent Volume & PVC
├── mysql-deployment.yaml      # MySQL deployment
├── mysql-service.yaml         # MySQL service
├── phpmyadmin-deployment.yaml # phpMyAdmin deployment
├── phpmyadmin-service.yaml    # phpMyAdmin service
└── README.md                  # This file
```

## Deployment Steps

### 1. Verify Kubernetes is Running

```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Deploy MySQL with Persistent Storage

```bash
# Create persistent volume and claim
kubectl apply -f mysql-pv.yaml

# Deploy MySQL
kubectl apply -f mysql-deployment.yaml

# Create MySQL service
kubectl apply -f mysql-service.yaml
```

### 3. Deploy phpMyAdmin

```bash
# Deploy phpMyAdmin
kubectl apply -f phpmyadmin-deployment.yaml

# Create phpMyAdmin service
kubectl apply -f phpmyadmin-service.yaml
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all

# Check persistent volume
kubectl get pv
kubectl get pvc

# Check pod status
kubectl get pods
```

Wait until all pods are in `Running` state.

### 5. Access phpMyAdmin

Open your browser and navigate to:
```
http://localhost:30080
```

Login credentials:
- **Server:** mysql
- **Username:** root
- **Password:** rootpassword

Alternatively, use the non-root user:
- **Username:** dbuser
- **Password:** dbpassword

## Testing Data Persistence

### Step 1: Create Test Data

1. Access phpMyAdmin at http://localhost:30080
2. Login with root credentials
3. Select the `testdb` database
4. Create a new table:

```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

5. Insert some test data:

```sql
INSERT INTO users (name, email) VALUES 
('John Doe', 'john@example.com'),
('Jane Smith', 'jane@example.com'),
('Bob Johnson', 'bob@example.com');
```

6. Verify data exists:

```sql
SELECT * FROM users;
```

### Step 2: Stress Test - Delete MySQL Pod

Delete the MySQL pod to simulate a crash:

```bash
# Get the MySQL pod name
kubectl get pods | grep mysql

# Delete the MySQL pod (it will automatically restart)
kubectl delete pod <mysql-pod-name>

# Example:
# kubectl delete pod mysql-7d8f5c6b9d-xyz12
```

Watch the pod restart:

```bash
kubectl get pods -w
```

### Step 3: Verify Data Persistence

1. Wait for the new MySQL pod to be in `Running` state
2. Refresh phpMyAdmin in your browser
3. Navigate to the `testdb` database
4. Check if your `users` table and data still exist:

```sql
SELECT * FROM users;
```

**Result:** Your data should still be there! This proves the persistent volume is working.

## Stress Test Scenarios

### Scenario 1: Delete MySQL Pod

```bash
kubectl delete pod -l app=mysql
kubectl get pods -w
```

### Scenario 2: Scale Down and Up

```bash
# Scale down to 0
kubectl scale deployment mysql --replicas=0

# Wait a few seconds, then scale back up
kubectl scale deployment mysql --replicas=1
```

### Scenario 3: Delete phpMyAdmin Pod

```bash
# This won't affect database data
kubectl delete pod -l app=phpmyadmin
```

### Scenario 4: Delete Entire Deployment (Keep PVC)

```bash
# Delete MySQL deployment
kubectl delete deployment mysql

# Redeploy
kubectl apply -f mysql-deployment.yaml
```

**Important:** As long as you don't delete the PVC (`kubectl delete pvc mysql-pvc`), your data will persist!

## Load Testing (Optional)

To simulate heavy load on phpMyAdmin:

```bash
# Install Apache Bench (if not already installed)
# On Windows WSL or Git Bash:
apt-get install apache2-utils  # Ubuntu/Debian

# Run load test (100 requests, 10 concurrent)
ab -n 100 -c 10 http://localhost:30080/
```

## Monitoring

### View Logs

```bash
# MySQL logs
kubectl logs -f deployment/mysql

# phpMyAdmin logs
kubectl logs -f deployment/phpmyadmin
```

### Check Resource Usage

```bash
kubectl top pods
kubectl top nodes
```

### Describe Resources

```bash
kubectl describe pod <pod-name>
kubectl describe pvc mysql-pvc
kubectl describe pv mysql-pv
```

## Cleanup

### Delete Everything (Including Data)

```bash
# Delete all deployments and services
kubectl delete -f phpmyadmin-service.yaml
kubectl delete -f phpmyadmin-deployment.yaml
kubectl delete -f mysql-service.yaml
kubectl delete -f mysql-deployment.yaml
kubectl delete -f mysql-pv.yaml
```

### Delete Only Apps (Keep Data)

```bash
# This keeps the PV and PVC intact
kubectl delete -f phpmyadmin-service.yaml
kubectl delete -f phpmyadmin-deployment.yaml
kubectl delete -f mysql-service.yaml
kubectl delete -f mysql-deployment.yaml
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods

# View pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>
```

### Can't Access phpMyAdmin

1. Verify service is running:
   ```bash
   kubectl get svc
   ```

2. Check if port 30080 is accessible:
   ```bash
   netstat -an | findstr 30080  # Windows
   ```

3. Ensure Docker Desktop Kubernetes is using localhost

### PVC Stuck in Pending

```bash
# Check PVC status
kubectl describe pvc mysql-pvc

# Ensure PV is available
kubectl get pv
```

## Configuration Details

### Database Credentials
- Root Password: `rootpassword`
- Database: `testdb`
- User: `dbuser`
- Password: `dbpassword`

### Ports
- MySQL: Internal port 3306 (ClusterIP)
- phpMyAdmin: External port 30080 (NodePort)

### Storage
- Volume Size: 5Gi
- Storage Location: `/mnt/data/mysql` (on Docker Desktop VM)
- Access Mode: ReadWriteOnce

## Key Concepts Demonstrated

 **Persistent Volumes:** Data survives pod deletions
 **StatefulSets Alternative:** Using PV with Deployment
 **Service Discovery:** phpMyAdmin connects to MySQL using service name
 **Resource Limits:** CPU and memory limits prevent resource exhaustion
 **Health Checks:** Kubernetes automatically restarts failed pods
