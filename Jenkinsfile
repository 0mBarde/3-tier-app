pipeline {
    agent any

    environment {
        SSH_CRED_ID = 'deployment-key'
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
                    sh 'checkov -d . --soft-fail' 
                }
            }
        }

        stage('Provision: App Infrastructure') {
            steps {
                dir('infra') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                    sh 'terraform output -raw app_private_ip > ../app_ip.txt'
                    sh 'terraform output -raw web_private_ip > ../web_ip.txt'
                }
            }
        }

        stage('Security: App (Trivy)') {
            steps {
                echo "Scanning Backend Code..."
                // Pointing directly to the app folder
                sh 'trivy fs app/ --scanners vuln --severity HIGH,CRITICAL'
                
                echo "Scanning Frontend Code..."
                // Pointing directly to the frontend folder
                sh 'trivy fs frontend/ --scanners vuln --severity HIGH,CRITICAL'
            }
        }

        stage('Deploy: Update App') {
            steps {
                script {
                    def APP_IP = readFile('app_ip.txt').trim()
                    def WEB_IP = readFile('web_ip.txt').trim()
                    
                    sshagent(credentials: [SSH_CRED_ID]) {
                        // FIX: Added 'git config safe.directory' to fix ownership error
                        
                        // 1. Update APP Server
                        echo "Deploying to App Server (${APP_IP})..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${APP_IP} '
                                git config --global --add safe.directory /home/ec2-user/3-tier-app &&
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
                                git config --global --add safe.directory /home/ec2-user/3-tier-app &&
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
