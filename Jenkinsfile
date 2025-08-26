pipeline {
    agent any

   tools {
       go 'go-1.21.4'
       // Uncomment the line below if you have SonarQube Scanner tool configured in Jenkins
       // If not configured, we'll use the withSonarQubeEnv step instead
       // 'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarQubeScanner'
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

        stage('Run SonarQube Analysis') {
            steps {
                script {
                    // Method 1: Using withSonarQubeEnv (recommended for SonarCloud)
                    withSonarQubeEnv('SonarCloud') {
                        sh 'sonar-scanner -Dsonar.organization=wm-demo-hello-webapp-golang -Dsonar.projectKey=ntttrang_hello-webapp-golang -Dsonar.sources=. -Dsonar.host.url=https://sonarcloud.io -Dsonar.login=${SONAR_TOKEN}'
                    }
                    
                    // Alternative Method 2: Direct command if withSonarQubeEnv is not configured
                    // Uncomment the lines below if Method 1 doesn't work
                    /*
                    sh '''
                        # Download and use sonar-scanner directly
                        if [ ! -f "sonar-scanner/bin/sonar-scanner" ]; then
                            wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-linux.zip
                            unzip -q sonar-scanner-cli-4.8.0.2856-linux.zip
                            mv sonar-scanner-4.8.0.2856-linux sonar-scanner
                        fi
                        
                        ./sonar-scanner/bin/sonar-scanner \
                            -Dsonar.organization=wm-demo-hello-webapp-golang \
                            -Dsonar.projectKey=ntttrang_hello-webapp-golang \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=https://sonarcloud.io \
                            -Dsonar.login=${SONAR_TOKEN}
                    '''
                    */
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
