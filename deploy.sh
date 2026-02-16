#!/bin/bash

echo "=== Deploying phpMyAdmin, MySQL and MinIO S3 Storage ==="

# Check if kubectl is available
echo -e "\nChecking kubectl..."
kubectl version --client

# Create Secrets from .env file
echo -e "\n[1/8] Creating Secrets from .env file..."
kubectl create secret generic mysql-secrets --from-env-file=.env --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic minio-secrets --from-env-file=.env --dry-run=client -o yaml | kubectl apply -f -

# Deploy Persistent Volumes
echo -e "\n[2/8] Creating Persistent Volumes..."
kubectl apply -f mysql-pv.yaml
kubectl apply -f minio-pv.yaml

# Deploy MySQL StatefulSet
echo -e "\n[3/8] Deploying MySQL StatefulSet..."
kubectl apply -f mysql-statefulset.yaml

# Deploy MySQL Service
echo -e "\n[4/8] Creating MySQL Service..."
kubectl apply -f mysql-service.yaml

# Deploy MinIO StatefulSet
echo -e "\n[5/8] Deploying MinIO StatefulSet..."
kubectl apply -f minio-statefulset.yaml

# Deploy MinIO Service
echo -e "\n[6/8] Creating MinIO Services..."
kubectl apply -f minio-service.yaml

# Deploy phpMyAdmin
echo -e "\n[7/8] Deploying phpMyAdmin..."
kubectl apply -f phpmyadmin-deployment.yaml

echo -e "\n[8/8] Creating phpMyAdmin Service..."
kubectl apply -f phpmyadmin-service.yaml

# Wait for pods to be ready
echo -e "\nWaiting for pods to be ready..."
sleep 5

# Show status
echo -e "\n=== Deployment Status ==="
kubectl get all
kubectl get pv
kubectl get pvc

echo -e "\n=== Access Information ==="
echo "phpMyAdmin URL:    http://localhost:30080"
echo "MinIO Console URL: http://localhost:30090"
echo "MinIO API URL:     http://localhost:30091"
echo ""
echo "MinIO Credentials:"
echo "  Access Key: minioadmin"
echo "  Secret Key: minioadmin123"
