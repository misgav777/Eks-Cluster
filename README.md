# EKS Cluster

This Terraform project provisions an Amazon EKS (Elastic Kubernetes Service) cluster with proper networking and security configurations.

## Features
- VPC with public and private subnets across multiple availability zones
- EKS cluster with the latest Kubernetes version
- Node groups running in private subnets for better security
- Public API endpoint with private endpoint access enabled
- AWS Load Balancer Controller IAM permissions ready
- NAT Gateway for outbound internet access from private subnets
- Support for Kubernetes Ingress resources via AWS Load Balancer Controller
- Ready for ArgoCD deployment with ingress access

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

> ⚠️ **IMPORTANT**: The AWS Load Balancer Controller **must** be installed before deploying ArgoCD or any services that use ingress.

1. Update kubeconfig:
```bash
aws eks update-kubeconfig --name DEV-cluster --region ap-south-1
```

2. Install AWS Load Balancer Controller:
```bash
# Create IAM OIDC provider
eksctl utils associate-iam-oidc-provider --region ap-south-1 --cluster DEV-cluster --approve

# Create service account for controller
eksctl create iamserviceaccount \
  --cluster=DEV-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/EKS-Cluster-AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# Install controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=DEV-cluster \
  --set serviceAccount.create=false \
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

6. Access ArgoCD through the ALB URL:
```bash
# Find the ALB URL
kubectl get ingress -n argocd

# The output will contain the ADDRESS which is your ALB DNS name
# Example: argocd-server-ingress   80, 443   k8s-argocd-argocds-123456789.us-west-2.elb.amazonaws.com   *      2m
```

7. Get the initial admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

8. Use the ALB DNS name in your browser to access ArgoCD UI, and log in with:
   - Username: admin
   - Password: (from step 7)