pipeline{
    agent any
    parameters {
        choice(
            name: 'action',
            choices: ['apply', 'destroy'],
            description: 'Action to perform: apply to create/update infrastructure, destroy to tear it down'
        )
    }
    environment{
        AWS_ACCESS_KEY_ID = credentials("AWS_ACCESS_KEY_ID")
        AWS_SECRET_ACCESS_KEY = credentials("AWS_SECRET_ACCESS_KEY")
        AWS_DEFAULT_REGION = "ap-south-1"
    }

    stages{
        stage("Initialize terraform"){
            steps{
                sh "terraform init"
            }
        }

        stage("Validate terraform"){
            steps{
                sh "terraform validate"
            }
        }

        stage("Plan terraform"){
            steps{
                sh "terraform plan"
                input(message: "Do you want to continue?", ok: "Proceed")
            }
        }

        stage('Pre-destroy cleanup') {
            when {
                expression { params.action == 'destroy' }
            }
            steps {
                sh '''
                aws eks update-kubeconfig --name DEV-cluster --region ap-south-1
                kubectl delete ingress --all --all-namespaces
                kubectl delete svc --all -n argocd
                kubectl delete -n kube-system deployment aws-load-balancer-controller
                sleep 60  # Give AWS time to delete resources
                '''
            }
        }
        
        stage("Destroy/Apply EKS Cluster"){
            steps{
                sh "terraform \$action -auto-approve"
            }
        }
    }
    post{
        always{
            echo "========always========"
        }
        success{
            echo "========pipeline executed successfully ========"
        }
        failure{
            echo "========pipeline execution failed========"
        }
    }
}