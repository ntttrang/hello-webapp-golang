pipeline {
    agent any

   tools {
       go 'go-1.21.4'
       nodejs 'nodejs-24.6.0'
    }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN') // Reference Jenkins credential ID
    }

    stages {
        stage('Unit Test') {
            steps {
                script {
                    sh 'go mod init hello'
                    sh 'go test'
                }
            }
        }

        stage('Coverage Report') {
            steps {
                script {
                    sh 'go test -coverprofile=coverage.out'
                    sh 'go tool cover -html=coverage.out -o coverage.html'
                }
                archiveArtifacts 'coverage.html'
            }
        }

        stage('Install SonarScanner') {
            steps {
                script {
                    sh '''
                        # Check if required tools are available
                        if ! command -v curl >/dev/null 2>&1; then
                            echo "Error: curl is not available. Please install curl or use a different Jenkins agent."
                            exit 1
                        fi

                        if ! command -v unzip >/dev/null 2>&1; then
                            echo "Error: unzip is not available. Please install unzip or use a different Jenkins agent."
                            exit 1
                        fi

                        # Download and install SonarScanner
                        echo "Installing SonarScanner..."
                        if curl -s -L -o sonar-scanner-cli-4.8.0.2856-linux.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip; then
                            echo "Download successful"
                        else
                            echo "Error: Failed to download SonarScanner"
                            exit 1
                        fi

                        if unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip; then
                            echo "Extraction successful"
                        else
                            echo "Error: Failed to extract SonarScanner"
                            exit 1
                        fi

                        export PATH=$PATH:$PWD/sonar-scanner-4.8.0.2856-linux/bin
                        echo "export PATH=\$PATH:\$PWD/sonar-scanner-4.8.0.2856-linux/bin" >> ~/.bashrc

                        # Verify installation
                        if ./sonar-scanner-4.8.0.2856-linux/bin/sonar-scanner --version; then
                            echo "SonarScanner installation verified"
                        else
                            echo "Error: SonarScanner installation failed"
                            exit 1
                        fi
                    '''
                }
            }
        }

        // stage('Run SonarQube Analysis - Alternative') {
        //     steps {
        //         script {
        //                 sh './sonar-scanner-4.8.0.2856-linux/bin/sonar-scanner -Dsonar.login=${SONAR_TOKEN} -Dsonar.organization=wm-demo -Dsonar.projectKey=wm-demo-hello-webapp-golang -Dsonar.sources=. -Dsonar.host.url=https://sonarcloud.io'
        //         }
        //     }
        // }
        stage('Run SonarQube Analysis') {
            steps {
                script {
                    // Verify SONAR_TOKEN is available
                    if (!env.SONAR_TOKEN) {
                        error("SONAR_TOKEN credential is not available. Please configure it in Jenkins credentials.")
                    }

                    // Verify coverage file exists
                    if (!fileExists('coverage.out')) {
                        echo "Warning: coverage.out file not found. Proceeding without coverage report."
                    }

                    // Use direct sonar-scanner command with SonarCloud authentication
                    sh """
                        echo "Starting SonarCloud analysis..."
                        ./sonar-scanner-4.8.0.2856-linux/bin/sonar-scanner \
                            -Dsonar.login=\${SONAR_TOKEN} \
                            -Dsonar.organization=wm-demo \
                            -Dsonar.projectKey=wm-demo-hello-webapp-golang \
                            -Dsonar.sources=. \
                            -Dsonar.go.coverage.reportPaths=coverage.out \
                            -Dsonar.exclusions=**/vendor/**,**/ansible/**,**/Jenkinsfile*,**/Dockerfile,**/*.md \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.verbose=true
                    """
                }
            }
        }


        stage('Build') {
            steps {
                script {
                    // Adjust these commands based on how you build and upload your Go application to Nexus
                    sh 'go build -o main .'
                    // sh 'curl -u username:password -X PUT --upload-file your-app https://nexus.example.com/repository/your-repo/your-app/1.0.0/your-app-1.0.0'
                }
                archiveArtifacts 'main'
            }
        }

        stage('Build Docker Image') {
           steps {
               script {
                   sh 'docker build -t minhtrang2106/hellogo .'
               }
           }
       }

        stage('Push Docker Image') {
           steps {
               script {
                   withCredentials([usernamePassword(credentialsId: 'DOCKER_REGISTRY_CREDENTIALS_ID', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                       sh """
                           echo $DOCKER_PASSWORD | docker login --username $DOCKER_USERNAME --password-stdin
                           docker push minhtrang2106/hellogo
                       """
                   }
               }
           }
       }

       // stage('Terraform Apply') {
       //      environment {
       //          AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
       //          AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
       //      }
       //      steps {
       //          script {
       //              sh '''
       //                  export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
       //                  export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
       //                  cd ./terraform
       //                  terraform init
       //                  terraform apply -auto-approve
       //              '''
       //          }
       //      }
       //  }

        stage('Run Ansible Playbook') {
            steps {
                script {
                    sh '''
                        ansible-playbook ansible/deploy-container.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
