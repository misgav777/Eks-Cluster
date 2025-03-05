pipeline{
    agent any
    environment{
        AWS_ACCESS_KEY_ID = credentials("AWS_ACCESS_KEY_ID")
        AWS_SECRET_ACCESS_KEY = credentials("AWS_SECRET_ACCESS_KEY")
        AWS_DEFAULT_REGION = "ap-south-1"
    }

    stages{
        stage("Initialize terraform"){
            steps{
                    {
                    sh "terraform init"
                }
            }
        }

        stage("Validate terraform"){
            steps{
                    {
                    sh "terraform validate"
                }
            }
        }

        stage("Plan terraform"){
            steps{
                    {
                    sh "terraform plan"
                }
                input(message: "Do you want to continue?", ok: "Proceed")
            }
        }

        stage("Destroy/Apply EKS Cluster"){
            steps{
                    {
                    sh "terraform $action -auto-approve"
                }
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