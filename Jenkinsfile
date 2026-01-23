pipeline {
    agent any

    environment {
        SSH_CRED_ID = 'deployment-key'
        // We will fetch IPs dynamically from the Terraform Output file
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Security: Infra (Checkov)') {
            steps {
                dir('infra') {
                    echo "Scanning Infrastructure Code..."
                    sh 'checkov -d . --soft-fail' 
                }
            }
        }

        stage('Provision: App Infrastructure') {
            steps {
                dir('infra') {
                    echo "Applying Terraform..."
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    
                    // SAVE THE IPs TO FILES SO WE CAN READ THEM LATER
                    sh 'terraform output -raw app_private_ip > ../app_ip.txt'
                    sh 'terraform output -raw web_private_ip > ../web_ip.txt'
                }
            }
        }

        stage('Security: App (Trivy)') {
            steps {
                echo "Scanning Application Code..."
                // Scans the Python code for vulnerabilities
                sh 'trivy fs . --scanners vuln --severity HIGH,CRITICAL'
            }
        }

        stage('Deploy: Update App') {
            steps {
                script {
                    // Read the IPs we saved in the Provision stage
                    def APP_IP = readFile('app_ip.txt').trim()
                    def WEB_IP = readFile('web_ip.txt').trim()
                    
                    sshagent(credentials: [SSH_CRED_ID]) {
                        // 1. Update APP Server
                        echo "Deploying to App Server (${APP_IP})..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${APP_IP} '
                                cd 3-tier-app &&
                                git pull origin main &&
                                pip3 install -r app/requirements.txt || true &&
                                sudo systemctl restart backend
                            '
                        """
                        
                        // 2. Update WEB Server
                        echo "Deploying to Web Server (${WEB_IP})..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${WEB_IP} '
                                cd 3-tier-app &&
                                git pull origin main &&
                                pip3 install -r frontend/requirements.txt || true &&
                                sudo systemctl restart frontend
                            '
                        """
                    }
                }
            }
        }
    }
}
