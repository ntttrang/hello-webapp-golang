pipeline {
    agent any

   tools {
       go 'go-1.21.4'
       // Add SonarQube Scanner tool - make sure this matches your Jenkins tool configuration
       // You can configure this in Jenkins Global Tool Configuration
       'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarQubeScanner'
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
                    // Use withSonarQubeEnv for proper integration with SonarCloud
                    withSonarQubeEnv('SonarCloud') {
                        // Get the SonarQube Scanner tool and add it to PATH
                        def scannerHome = tool 'SonarQubeScanner'
                        sh """
                            export PATH=\${PATH}:${scannerHome}/bin
                            sonar-scanner \
                                -Dsonar.organization=wm-demo-hello-webapp-golang \
                                -Dsonar.projectKey=ntttrang_hello-webapp-golang
                                -Dsonar.sources=. \
                                -Dsonar.go.coverage.reportPaths=coverage.out \
                                -Dsonar.exclusions=**/vendor/**,**/ansible/**,**/Jenkinsfile*,**/Dockerfile,**/*.md
                        """
                    }
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
                   sh 'docker build -t dab8106/hellogo .'
               }
           }
       }

        stage('Push Docker Image') {
           steps {
               script {
                   withCredentials([usernamePassword(credentialsId: 'DOCKER_REGISTRY_CREDENTIALS_ID', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                       sh """
                           echo $DOCKER_PASSWORD | docker login --username $DOCKER_USERNAME --password-stdin
                           docker push dab8106/hellogo
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
