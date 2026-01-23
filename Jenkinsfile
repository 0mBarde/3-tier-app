pipeline {
    agent any

    environment {
        SSH_CRED_ID = 'deployment-key'
        // REPLACE THIS WITH YOUR EXACT GITHUB URL
        YOUR_REPO_URL = 'https://github.com/0mBarde/3-tier-app.git'
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
                // Scan the code in the Jenkins workspace (This should work now!)
                echo "Scanning Backend Code..."
                sh 'trivy fs app/ --scanners vuln --severity HIGH,CRITICAL'
                
                echo "Scanning Frontend Code..."
                sh 'trivy fs frontend/ --scanners vuln --severity HIGH,CRITICAL'
            }
        }

        stage('Deploy: Update App') {
            steps {
                script {
                    def APP_IP = readFile('app_ip.txt').trim()
                    def WEB_IP = readFile('web_ip.txt').trim()
                    
                    sshagent(credentials: [SSH_CRED_ID]) {
                        
                        // 1. Update APP Server (Backend)
                        echo "Deploying to App Server (${APP_IP})..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${APP_IP} '
                                # 1. Fix Ownership
                                sudo chown -R ec2-user:ec2-user /home/ec2-user/3-tier-app
                                git config --global --add safe.directory /home/ec2-user/3-tier-app
                                cd 3-tier-app
                                
                                # 2. CRITICAL FIX: Switch to YOUR Repository
                                git remote set-url origin ${YOUR_REPO_URL}
                                git fetch origin
                                git reset --hard origin/main
                                
                                # 3. Install & Restart
                                pip3 install -r app/requirements.txt
                                sudo systemctl restart backend
                            '
                        """
                        
                        // 2. Update WEB Server (Frontend)
                        echo "Deploying to Web Server (${WEB_IP})..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${WEB_IP} '
                                sudo chown -R ec2-user:ec2-user /home/ec2-user/3-tier-app
                                git config --global --add safe.directory /home/ec2-user/3-tier-app
                                cd 3-tier-app
                                
                                # Switch Repo here too
                                git remote set-url origin ${YOUR_REPO_URL}
                                git fetch origin
                                git reset --hard origin/main
                                
                                pip3 install -r frontend/requirements.txt
                                sudo systemctl restart frontend
                            '
                        """
                    }
                }
            }
        }
    }
}
