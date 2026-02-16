#!/bin/bash

echo "=== Deploying phpMyAdmin with Persistent MySQL ==="

# Check if kubectl is available
echo -e "\nChecking kubectl..."
kubectl version --client

# Deploy MySQL PV and PVC
echo -e "\n[1/5] Creating Persistent Volume and PVC..."
kubectl apply -f mysql-pv.yaml

# Deploy MySQL
echo -e "\n[2/5] Deploying MySQL..."
kubectl apply -f mysql-deployment.yaml

# Deploy MySQL Service
echo -e "\n[3/5] Creating MySQL Service..."
kubectl apply -f mysql-service.yaml

# Deploy phpMyAdmin
echo -e "\n[4/5] Deploying phpMyAdmin..."
kubectl apply -f phpmyadmin-deployment.yaml

# Deploy phpMyAdmin Service
echo -e "\n[5/5] Creating phpMyAdmin Service..."
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
echo "phpMyAdmin URL: http://localhost:30080"
echo "Username: root"
echo "Password: rootpassword"
echo -e "\nWait a minute for all pods to be fully ready, then access phpMyAdmin!"
