pipeline {
    agent any

   tools {
       go 'go-1.21.4'
       // SonarQube Scanner tool - this should match the name you configured in Jenkins Global Tool Configuration
       'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarCloud'
    }

    // parameters {
    //     string(name: 'GIT_TAG', defaultValue: 'latest', description: 'Git tag or branch to build from')
    // }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN') // Reference Jenkins credential ID
        GIT_TAG = "${params.GIT_TAG}"
    }

    stages {
        stage('Checkout source code') {
            steps {
                script {
                    if (env.GIT_TAG == 'latest' || env.GIT_TAG == '') {
                        // Use default branch when 'latest' is specified
                        git branch: "master",
                            url: 'git@github.com:ntttrang/hello-webapp-golang.git'
                    } else {
                        // Use specific tag or branch
                        git branch: "${env.GIT_TAG}",
                            url: 'git@github.com:ntttrang/hello-webapp-golang.git'
                    }
                }
            }
        }
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
                    try {
                        // Method 1: Using withSonarQubeEnv with configured SonarQube Scanner tool
                        withSonarQubeEnv('SonarCloud') {
                            // Use the configured sonar-scanner from tools section
                            sh '''
                                sonar-scanner \
                                    -Dsonar.organization=wm-demo-hello-webapp-golang \
                                    -Dsonar.projectKey=ntttrang_hello-webapp-golang \
                                    -Dsonar.sources=. \
                                    -Dsonar.host.url=https://sonarcloud.io \
                                    -Dsonar.token=${SONAR_TOKEN}
                            '''
                        }
                    } catch (Exception e) {
                        echo "Method 1 failed: ${e.getMessage()}"
                        echo "Trying Method 2: Docker-based SonarQube Scanner"
                        
                        try {
                            // Method 2: Use official SonarQube Scanner Docker image (most reliable)
                            sh '''
                                echo "Using Docker-based SonarQube Scanner..."
                                docker run --rm \
                                    -v "${PWD}:/usr/src" \
                                    -w /usr/src \
                                    sonarsource/sonar-scanner-cli:latest \
                                    sonar-scanner \
                                        -Dsonar.organization=wm-demo-hello-webapp-golang \
                                        -Dsonar.projectKey=ntttrang_hello-webapp-golang \
                                        -Dsonar.sources=. \
                                        -Dsonar.host.url=https://sonarcloud.io \
                                        -Dsonar.token=${SONAR_TOKEN}
                            '''
                        } catch (Exception e2) {
                            echo "Method 2 failed: ${e2.getMessage()}"
                            echo "Falling back to Method 3: Direct download with multiple fallbacks"
                            
                            // Method 3: Download and use sonar-scanner directly with multiple fallback options
                            sh '''
                                # Download and use sonar-scanner directly
                                if [ ! -f "sonar-scanner/bin/sonar-scanner" ]; then
                                    echo "Downloading SonarQube Scanner..."
                                    
                                    SCANNER_VERSION="4.8.0.2856"
                                    SCANNER_ZIP="sonar-scanner-cli-${SCANNER_VERSION}-linux.zip"
                                    DOWNLOAD_URL="https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/${SCANNER_ZIP}"
                                    
                                    # Try multiple download methods
                                    if command -v curl >/dev/null 2>&1; then
                                        echo "Using curl to download..."
                                        curl -sL "${DOWNLOAD_URL}" -o "${SCANNER_ZIP}"
                                    elif command -v wget >/dev/null 2>&1; then
                                        echo "Using wget to download..."
                                        wget -q "${DOWNLOAD_URL}"
                                    else
                                        echo "Neither curl nor wget available. Trying with Jenkins built-in tools..."
                                        # Use Java to download if available
                                        java -version
                                        cat > download.java << 'EOF'
import java.io.*;
import java.net.*;
import java.nio.channels.*;

public class download {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        String filename = args[1];
        ReadableByteChannel rbc = Channels.newChannel(new URL(url).openStream());
        FileOutputStream fos = new FileOutputStream(filename);
        fos.getChannel().transferFrom(rbc, 0, Long.MAX_VALUE);
        fos.close();
        rbc.close();
    }
}
EOF
                                        javac download.java
                                        java download "${DOWNLOAD_URL}" "${SCANNER_ZIP}"
                                        rm download.java download.class
                                    fi
                                    
                                    # Check if download was successful
                                    if [ ! -f "${SCANNER_ZIP}" ]; then
                                        echo "Error: Failed to download SonarQube Scanner"
                                        exit 1
                                    fi
                                    
                                    echo "Extracting SonarQube Scanner..."
                                    unzip -q "${SCANNER_ZIP}"
                                    mv "sonar-scanner-${SCANNER_VERSION}-linux" sonar-scanner
                                    chmod +x sonar-scanner/bin/sonar-scanner
                                    rm "${SCANNER_ZIP}"
                                    
                                    echo "SonarQube Scanner installed successfully!"
                                else
                                    echo "SonarQube Scanner already available"
                                fi
                                
                                echo "Running SonarQube analysis..."
                                ./sonar-scanner/bin/sonar-scanner \
                                    -Dsonar.organization=wm-demo-hello-webapp-golang \
                                    -Dsonar.projectKey=ntttrang_hello-webapp-golang \
                                    -Dsonar.sources=. \
                                    -Dsonar.host.url=https://sonarcloud.io \
                                    -Dsonar.token=${SONAR_TOKEN}
                            '''
                        }
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
