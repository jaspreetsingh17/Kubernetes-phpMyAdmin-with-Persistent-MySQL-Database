# Kubernetes phpMyAdmin with Persistent MySQL Database and MinIO S3 Storage

This project deploys phpMyAdmin with a persistent MySQL database and MinIO S3-compatible object storage on Kubernetes (Docker Desktop). All data persists even when pods are deleted and recreated.

> **⚠️ WARNING:** The `.env` file is included in this repository for testing and demonstration purposes only. In production environments, **NEVER** commit `.env` files containing sensitive credentials to version control. Always add `.env` to your `.gitignore` file.

## Features

✓ **Persistent Storage** - MySQL and MinIO data survives pod restarts and deletions  
✓ **S3-Compatible Storage** - MinIO provides Amazon S3-compatible object storage  
✓ **Secret Management** - Credentials stored in Kubernetes Secrets from .env file  
✓ **Health Probes** - Startup, Liveness, and Readiness probes configured  
✓ **Graceful Shutdown** - Proper termination with preStop hooks  
✓ **Resource Limits** - CPU and memory constraints defined  
✓ **Production-Ready** - Best practices for Kubernetes deployments

## Prerequisites

- Docker Desktop with Kubernetes enabled
- kubectl configured to use docker-desktop context

## Project Structure

```
project/
├── .env                       # Environment variables (credentials)
├── mysql-pv.yaml              # MySQL Persistent Volume for StatefulSet
├── mysql-statefulset.yaml     # MySQL StatefulSet with probes
├── mysql-service.yaml         # MySQL headless service
├── minio-pv.yaml              # MinIO Persistent Volume for StatefulSet
├── minio-statefulset.yaml     # MinIO StatefulSet with probes
├── minio-service.yaml         # MinIO API and Console services
├── phpmyadmin-deployment.yaml # phpMyAdmin deployment with probes
├── phpmyadmin-service.yaml    # phpMyAdmin service
├── deploy.sh                  # Deployment script
├── cleanup.sh                 # Cleanup script
└── README.md                  # This file
```
Quick Deploy (Recommended)

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment script
./deploy.sh
```

The script will:
1. Create Kubernetes Secrets from `.env` file
2. Create Persistent Volumes and PVCs for MySQL and MinIO
3. Deploy MySQL with health probes
4. Deploy MinIO with health probes
5. Deploy phpMyAdmin with health probes
6. Show deployment status

### Manual Deployment

If you prefer manual steps:

```bash
# 1. Create Secrets from .env
kubectl create secret generic mysql-secrets --from-env-file=.env
kubectl create secret generic minio-secrets --from-env-file=.env

# 2. Create persistent volumes
kubectl apply -f mysql-pv.yaml
kubectl apply -f minio-pv.yaml

# 3. Deploy MySQL StatefulSet
kubectl apply -f mysql-statefulset.yaml
kubectl apply -f mysql-service.yaml

# 4. Deploy MinIO StatefulSet
kubectl apply -f minio-statefulset.yaml
kubectl apply -f minio-service.yaml

# 5. Deploy phpMyAdmin
kubectl apply -f phpmyadmin-deployment.yaml
kubectl apply -f phpmyadmin-service.yaml
```

### Verify Deployment

```bash
# Check all resources
kubectl get all

# Check persistent volumes
kubectl get pv
kubectl get pvc
```

## Access Applications

### phpMyAdmin

Open your browser and navigate to:
```
http://localhost:30080
```

Login credentials (from `.env` file):
- **Server:** mysql
- **Username:** root
- **Password:** (check MYSQL_ROOT_PASSWORD in .env)

Alternatively, use the non-root user:
- **Username:** dbuser
- **Password:** (check MYSQL_PASSWORD in .env)

### MinIO Console

Open your browser and navigate to:
```
http://localhost:30090
```

Login credentials (from `.env` file):
- **Username:** (check MINIO_ROOT_USER in .env)
- **Password:** (check MINIO_ROOT_PASSWORD in .env)

### MinIO API Access

The MinIO S3-compatible API is accessible at:
```
http://localhost:30091
```

You can use AWS CLI or any S3-compatible client to interact with MinIO:

```bash
# Configure AWS CLI for MinIO
aws configure set aws_access_key_id <MINIO_ROOT_USER>
aws configure set aws_secret_access_key <MINIO_ROOT_PASSWORD>
aws --endpoint-url http://localhost:30091 s3 ls
```

## Configuration Management

### Environment Variables

All sensitive data is stored in `.env` file:

```env
# MySQL Configuration
MYSQL_ROOT_PASSWORD=admin@123
MYSQL_DATABASE=testdb
MYSQL_USER=dbuser
MYSQL_PASSWORD=dbpassword

# phpMyAdmin Configuration
PMA_HOST=mysql
PMA_PORT=3306

# MinIO Configuration
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
```

**Important:** Add `.env` to `.gitignore` to prevent committing secrets!

### Updating Credentials

To change passwords or configuration:

1. Edit `.env` file
2. Delete old data: 
   - MySQL: `sudo rm -rf /mnt/h/mysql-data/*`
   - MinIO: `sudo rm -rf /mnt/h/minio-data/*`
3. Redeploy: `./cleanup.sh && ./deploy.sh`

**Note:** MySQL and MinIO only use environment variables during initial setup. To change passwords on existing databases, you must reset the data.

## Testing Data Persistence

### MySQL Persistence Test

#### Step 1: Create Test Data

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

### MinIO Persistence Test

#### Step 1: Create Test Bucket and Upload File

1. Access MinIO Console at http://localhost:30090
2. Login with your MinIO credentials
3. Create a new bucket called `test-bucket`
4. Upload a test file to the bucket

Alternatively, use AWS CLI:

```bash
# Create a test bucket
aws --endpoint-url http://localhost:30091 s3 mb s3://test-bucket

# Upload a test file
echo "Hello MinIO!" > test.txt
aws --endpoint-url http://localhost:30091 s3 cp test.txt s3://test-bucket/

# List files
aws --endpoint-url http://localhost:30091 s3 ls s3://test-bucket/
```

#### Step 2: Delete MinIO Pod

```bash
# Get the MinIO pod name
kubectl get pods | grep minio

# Delete the MinIO pod
kubectl delete pod minio-0

# Watch it restart
kubectl get pods -w
```

#### Step 3: Verify Data Persistence

1. Wait for the new MinIO pod to be `Running`
2. Access MinIO Console and verify your bucket and files still exist

Or use AWS CLI:

```bash
# List buckets
aws --endpoint-url http://localhost:30091 s3 ls

# List files in bucket
aws --endpoint-url http://localhost:30091 s3 ls s3://test-bucket/
```

**Result:** Your buckets and files should still be there!

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

### Scenario 4: Delete MinIO Pod

```bash
# Delete MinIO pod
kubectl delete pod -l app=minio
kubectl get pods -w
```

### Scenario 5: Delete Entire StatefulSet (Keep Data)

```bash
# Delete MySQL StatefulSet
kubectl delete statefulset mysql

# Delete MinIO StatefulSet
kubectl delete statefulset minio

# Redeploy
kubectl apply -f mysql-statefulset.yaml
kubectl apply -f minio-statefulset.yaml
```

**Important:** As long as you don't delete the PVCs, your data will persist!
- MySQL PVC: `mysql-data-mysql-0`
- MinIO PVC: `minio-data-minio-0`

**Note:** StatefulSet creates PVCs with pattern: `<volumeClaimTemplate-name>-<statefulset-name>-<ordinal>`

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

```bash
# Check pod status and logs
kubectl get pods
kubectl logs <pod-name>

# Describe resources
kubectl describe pod <pod-name>
kubectl describe pvc <pvc-name>
kubectl describe pv <pv-name>

# Watch pod status in real-time
kubectl get pods -w
```

## Cleanup

### Quick Cleanup (Recommended)

```bash
# Delete everything including secrets and PVCs
./cleanup.sh
```

The cleanup script will remove:
- All deployments and services
- All StatefulSets
- All Persistent Volumes and PVCs
- All secrets

### Manual Cleanup

```bash
# Delete all resources including secrets
kubectl delete -f phpmyadmin-service.yaml
kubectl delete -f phpmyadmin-deployment.yaml
kubectl delete -f mysql-service.yaml
kubectl delete -f mysql-statefulset.yaml
kubectl delete -f mysql-pv.yaml
kubectl delete -f minio-service.yaml
kubectl delete -f minio-statefulset.yaml
kubectl delete -f minio-pv.yaml
kubectl delete secret mysql-secrets
kubectl delete secret minio-secrets

# Delete PVCs created by StatefulSets
kubectl delete pvc mysql-data-mysql-0
kubectl delete pvc minio-data-minio-0
```

### Delete Everything (Including Data)

```bash
# Delete all deployments and services
kubectl delete -f phpmyadmin-service.yaml
kubectl delete -f phpmyadmin-deployment.yaml
kubectl delete -f mysql-service.yaml
kubectl delete -f mysql-statefulset.yaml
kubectl delete -f mysql-pv.yaml
kubectl delete secret mysql-secrets

# Also delete PVC created by StatefulSet
kubectl delete pvc minio-data-minio-0
```

### Delete Only Apps (Keep Data)

```bash
# This keeps the PVs and PVCs intact
kubectl delete -f phpmyadmin-service.yaml
kubectl delete -f phpmyadmin-deployment.yaml
kubectl delete -f mysql-service.yaml
kubectl delete -f mysql-statefulset.yaml
kubectl delete -f minio-service.yaml
kubectl delete -f minio-statefulset.yaml
# PVs and PVCs remain, data is preserved
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
2. Check if port 30080 is accessible
3. Verify phpMyAdmin pod is running

### Can't Access MinIO Console

1. Verify MinIO service is running:
   ```bash
   kubectl get svc minio-console
   ```
2. Check if port 30090 is accessible
3. Verify MinIO pod is running and healthy

### PVC Stuck in Pending

```bash
# Check PVC status
kubectl describe pvc <pvc-name>

# Ensure PV is available
kubectl get pv
```

## Advanced Features

### Health Probes

Both MySQL and phpMyAdmin have comprehensive health checks:

#### Startup Probes
- **MySQL:** 150 seconds max startup time (30 checks × 5s)
- **MinIO:** 120 seconds max startup time (24 checks × 5s)
- **phpMyAdmin:** 60 seconds max startup time (12 checks × 5s)
- Prevents premature container restarts during slow initialization

#### Liveness Probes
- **MySQL:** Checks `mysqladmin ping` every 10s
- **MinIO:** HTTP GET on `/minio/health/live` every 10s
- **phpMyAdmin:** HTTP GET on port 80 every 10s
- Restarts container if unhealthy

#### Readiness Probes
- **MySQL:** Checks `mysqladmin ping` every 5s
- **MinIO:** HTTP GET on `/minio/health/ready` every 5s
- **phpMyAdmin:** HTTP GET on port 80 every 5s
- Removes pod from service endpoints if not ready

### Graceful Shutdown

#### MySQL & MinIO
- **terminationGracePeriodSeconds:** 30 seconds
- Allows time for proper shutdown and connection cleanup

#### phpMyAdmin
- **terminationGracePeriodSeconds:** 30 seconds
  - Allow active HTTP requests to complete
  - Gracefully close connections

### Secret Management

- Credentials stored in Kubernetes Secrets
- Created from `.env` file during deployment
- Environment variables injected using `envFrom: secretRef`
- Separation of config from code
- Separate secrets for MySQL and MinIO

## Configuration Details

### Ports
- **MySQL:** Internal port 3306 (ClusterIP - headless service)
- **MinIO API:** Port 9000 (Internal), Port 30091 (NodePort)
- **MinIO Console:** Port 9001 (Internal), Port 30090 (NodePort)
- **phpMyAdmin:** Port 80 (Internal), Port 30080 (NodePort)

### Storage
- **MySQL:**
  - Volume Size: 5Gi
  - Storage Location: `/mnt/h/mysql-data` (host path)
  - Access Mode: ReadWriteOnce
  - Reclaim Policy: Retain
- **MinIO:**
  - Volume Size: 10Gi
  - Storage Location: `/mnt/h/minio-data` (host path)
  - Access Mode: ReadWriteOnce
  - Reclaim Policy: Retain

## Key Concepts Demonstrated

✓ **Persistent Volumes:** Data survives pod deletions
✓ **StatefulSets:** Stable network identities and persistent storage
✓ **Service Discovery:** Applications connect using Kubernetes service names
✓ **Resource Limits:** CPU and memory limits prevent resource exhaustion
✓ **Health Checks:** Kubernetes automatically restarts failed pods
✓ **S3-Compatible Storage:** MinIO provides object storage with AWS S3 API
✓ **Multi-Service Architecture:** Database, object storage, and admin interface working together
