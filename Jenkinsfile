pipeline {
    agent any

    // Skip default checkout - we'll do it explicitly
    options {
        skipDefaultCheckout true
    }

   tools {
       go 'go-1.21.4'
       // SonarQube Scanner tool - this should match the name you configured in Jenkins Global Tool Configuration
       'hudson.plugins.sonar.SonarRunnerInstallation' 'SonarCloud'
    }

    // parameters {
    //     string(name: 'GIT_TAG', defaultValue: 'master', description: 'Git tag or branch to build from')
    // }

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN') // Reference Jenkins credential ID
       // GIT_CREDENTIALS = credentials('github-ssh-key') // SSH key for GitHub
    }

    stages {
        stage('Checkout source code') {
            steps {
                script {
                    def targetRef = params.GIT_TAG ?: 'master'
                    echo "Checking out tag/branch: ${targetRef}"

                    // Checkout the repository first
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/master"]],
                        extensions: [
                            [$class: 'CloneOption', depth: 0, noTags: false, shallow: false]
                        ],
                        userRemoteConfigs: [[
                            url: 'https://github.com/ntttrang/hello-webapp-golang.git'
                        ]]
                    ])

                    // Now checkout the specific tag or branch
                    sh """
                        echo "Fetching all tags and branches..."
                        git fetch --all --tags
                        
                        echo "Checking if '${targetRef}' is a tag or branch..."
                        if git show-ref --tags --quiet --verify -- "refs/tags/${targetRef}"; then
                            echo "'${targetRef}' is a tag"
                            git checkout tags/${targetRef}
                        elif git show-ref --heads --quiet --verify -- "refs/heads/${targetRef}" || git show-ref --remotes --quiet --verify -- "refs/remotes/origin/${targetRef}"; then
                            echo "'${targetRef}' is a branch"
                            git checkout ${targetRef}
                        else
                            echo "Trying to checkout '${targetRef}' directly..."
                            git checkout ${targetRef}
                        fi
                    """

                    // Verify what we actually checked out
                    sh '''
                        echo "Current HEAD information:"
                        git log --oneline -1
                        git describe --tags --always
                        if git symbolic-ref -q HEAD > /dev/null 2>&1; then
                            echo "On branch: $(git branch --show-current)"
                        else
                            echo "Detached HEAD (likely on a tag)"
                        fi
                    '''
                    echo "Successfully checked out: ${targetRef}"
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
                        echo "=== Ansible Configuration ==="
                        ansible --version
                        echo "=== Running Ansible Playbook ==="
                        ansible-playbook -i localhost, -c local ansible/deploy-container.yaml
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
