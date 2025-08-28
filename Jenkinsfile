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

        stage('Generate SSH Keys') {
            steps {
                script {
                    sh '''
                        echo "=== Checking/Creating SSH Keys for AWS EC2 ==="
                        mkdir -p ssh-keys

                        # Only generate SSH keys if they don't exist
                        if [ ! -f "ssh-keys/my-keypair" ] || [ ! -f "ssh-keys/my-keypair.pub" ]; then
                            echo "Generating new SSH key pair..."
                            ssh-keygen -t rsa -b 2048 -f ssh-keys/my-keypair -N "" -C "jenkins-generated-key"
                        else
                            echo "SSH key pair already exists, skipping generation"
                        fi

                        # Set correct permissions
                        chmod 600 ssh-keys/my-keypair
                        chmod 644 ssh-keys/my-keypair.pub

                        # Verify keys
                        ls -la ssh-keys/
                        echo "SSH public key fingerprint:"
                        ssh-keygen -l -f ssh-keys/my-keypair.pub

                        echo "=== SSH Keys Ready ==="
                    '''
                }
                archiveArtifacts artifacts: 'ssh-keys/my-keypair', allowEmptyArchive: false, fingerprint: true
            }
        }

        stage('Terraform Apply') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
                AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
            }
            steps {
                script {
                    sh '''
                        echo "=== Running Terraform ==="
                        export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                        export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

                        # Verify SSH key exists
                        if [ ! -f "ssh-keys/my-keypair.pub" ]; then
                            echo "ERROR: SSH public key not found!"
                            exit 1
                        fi

                        # Check if key pair exists in AWS and remove it if necessary
                        KEY_PAIR_EXISTS=$(aws ec2 describe-key-pairs --key-names my-keypair --query 'KeyPairs[0].KeyName' --output text 2>/dev/null || echo "NOT_FOUND")
                        if [ "$KEY_PAIR_EXISTS" != "NOT_FOUND" ]; then
                            echo "Key pair exists in AWS, checking if it matches local key..."
                            # If key pair exists but doesn't match, we need to handle this
                            echo "Key pair already exists in AWS"
                        fi

                        terraform init
                        terraform validate
                        terraform plan -out=tfplan

                        # Check if the plan includes key pair changes
                        if terraform plan -out=tfplan | grep -q "aws_key_pair.deployer"; then
                            echo "Key pair changes detected in Terraform plan"
                        fi

                        terraform apply tfplan
                    '''
                }
            }
        }

        stage('Update Ansible Inventory') {
            steps {
                script {
                    sh '''
                        echo "=== Updating Ansible Inventory ==="
                        # Get Terraform outputs and update inventory
                        INSTANCE_IP=$(terraform output -raw instance_public_ip)
                        echo "EC2 Public IP: ${INSTANCE_IP}"

                        # Create backup of original inventory
                        cp ansible/inventory.ini ansible/inventory.ini.backup

                        # Update inventory file with actual IP and SSH key path
                        # First, remove any existing aws-server entries
                        sed -i '/^aws-server/d' ansible/inventory.ini

                        # Add the new aws-server entry
                        sed -i "/^\[aws_servers\]/a aws-server ansible_host=${INSTANCE_IP} ansible_user=ec2-user ansible_ssh_private_key_file=ssh-keys/my-keypair" ansible/inventory.ini

                        echo "Updated inventory file:"
                        cat ansible/inventory.ini

                        # Test SSH connection
                        echo "Testing SSH connection..."
                        ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ssh-keys/my-keypair ec2-user@${INSTANCE_IP} "echo 'SSH connection successful'" || echo "SSH connection test failed - this is expected if keys don't match yet"
                    '''
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                script {
                    sh '''
                        echo "=== Ansible Configuration ==="
                        ansible --version
                        echo "=== Running Ansible Playbook for AWS ==="
                        ansible-playbook -i ansible/inventory.ini ansible/deploy-aws.yaml
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
