# EKS Cluster

This Terraform project provisions an Amazon EKS (Elastic Kubernetes Service) cluster with proper networking and security configurations.

## Features
- VPC with public and private subnets across multiple availability zones
- EKS cluster with the latest Kubernetes version
- Node groups running in private subnets for better security
- Public API endpoint with private endpoint access enabled
- AWS Load Balancer Controller IAM permissions ready
- NAT Gateway for outbound internet access from private subnets

## Prerequisites
- AWS CLI installed and configured
- Terraform installed
- Knowledge of Kubernetes and AWS services

## Usage
1. Update `terraform.tfvars` with your desired configuration
2. Initialize Terraform: `terraform init`
3. Plan the changes: `terraform plan`
4. Apply the changes: `terraform apply`

## Post-Installation
To install ArgoCD and configure ingress:

1. Update kubeconfig:
```bash
aws eks update-kubeconfig --name DEV-cluster --region ap-south-1
```

2. Install AWS Load Balancer Controller:
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=DEV-cluster \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller
```

3. Install ArgoCD:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

4. Configure ingress for ArgoCD:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: ingress.k8s.aws/alb
EOF
```

5. Create an ingress resource for ArgoCD:
```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  rules:
    - http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: argocd-server
              port:
                number: 80
EOF
```