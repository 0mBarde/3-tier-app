pipeline {
    agent any

    environment {
        // This is the ID you created manually in Jenkins
        SSH_CRED_ID = 'deployment-key'
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout the code from the repository
                checkout scm
            }
        }

        stage('Security: Infra (Checkov)') {
            steps {
                dir('infra') {
                    echo "Scanning Infrastructure Code..."
                    // Fails the build if high-severity issues are found (Soft fail for demo)
                    sh 'checkov -d . --soft-fail' 
                }
            }
        }

        stage('Provision: App Infrastructure') {
            steps {
                dir('infra') {
                    echo "Initializing Terraform..."
                    sh 'terraform init'

                    echo "Planning Deployment..."
                    sh 'terraform plan -out=tfplan'

                    echo "Applying Deployment..."
                    // This creates the Web, App, and DB servers!
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        // --- NOTE: We will add the App Deployment stage here later ---
        // For now, let's just confirm the servers can be created.
    }
}
