pipeline {
    agent { label 'azure' }

    parameters {
        string(name: 'RESOURCE_PREFIX', defaultValue: 'devops-e2e', description: 'Terraform resource name prefix')
        string(name: 'RESOURCE_SUFFIX', defaultValue: 'run04', description: 'Terraform resource suffix')
        string(name: 'VM_USER', defaultValue: 'azureuser', description: 'SSH username for the Azure VM')
    }

    environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        AZURE_SP_CREDENTIALS_ID = 'azure-sp'
        AZURE_SUBSCRIPTION_ID_CREDENTIALS_ID = 'azure-subscription-id'
        AZURE_TENANT_ID_CREDENTIALS_ID = 'azure-tenant-id'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'candidate/Arun',
                    url: 'https://github.com/Arun106/Devops_Project_E2E.git'
            }
        }

        stage('Install Prerequisites') {
            steps {
                sh 'chmod +x scripts/install_prereqs.sh'
                sh './scripts/install_prereqs.sh'
                sh 'az --version | head -n 1'
                sh 'ansible --version'
            }
        }

        stage('Discover Azure VM') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: env.AZURE_SP_CREDENTIALS_ID, usernameVariable: 'AZURE_CLIENT_ID', passwordVariable: 'AZURE_CLIENT_SECRET'),
                    string(credentialsId: env.AZURE_SUBSCRIPTION_ID_CREDENTIALS_ID, variable: 'AZURE_SUBSCRIPTION_ID'),
                    string(credentialsId: env.AZURE_TENANT_ID_CREDENTIALS_ID, variable: 'AZURE_TENANT_ID')
                ]) {
                    script {
                        env.RESOURCE_GROUP = "${params.RESOURCE_PREFIX}-${params.RESOURCE_SUFFIX}-rg"
                        env.VM_NAME = "${params.RESOURCE_PREFIX}-${params.RESOURCE_SUFFIX}-vm"

                        sh '''
                            set +x
                            az login --service-principal \
                              --username "$AZURE_CLIENT_ID" \
                              --password "$AZURE_CLIENT_SECRET" \
                              --tenant "$AZURE_TENANT_ID" >/dev/null
                            set -x
                            az account set --subscription "$AZURE_SUBSCRIPTION_ID"
                        '''

                        env.VM_HOST = sh(
                            script: '''
                                az vm show \
                                  --resource-group "$RESOURCE_GROUP" \
                                  --name "$VM_NAME" \
                                  --show-details \
                                  --query publicIps \
                                  -o tsv
                            ''',
                            returnStdout: true
                        ).trim()

                        if (!env.VM_HOST) {
                            error "Could not discover public IP for ${env.RESOURCE_GROUP}/${env.VM_NAME}"
                        }

                        echo "Discovered VM ${env.VM_NAME} in ${env.RESOURCE_GROUP}: ${env.VM_HOST}"
                    }
                }
            }
        }

        stage('Build') {
            steps {
                sh 'scripts/build.sh'
            }
        }

        stage('Test') {
            steps {
                dir('app') {
                    sh 'mvn test'
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'app/target/devops-e2e-app.war', fingerprint: true
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                    cat > ansible/inventory.generated.ini <<EOF
[tomcat]
localhost ansible_connection=local ansible_user=${VM_USER} ansible_python_interpreter=/usr/bin/python3
EOF
                    ansible -i ansible/inventory.generated.ini tomcat -m ping
                    ansible-playbook -i ansible/inventory.generated.ini ansible/site.yml
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh 'scripts/health_check.sh "$VM_HOST"'
            }
        }
    }
}
