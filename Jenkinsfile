pipeline {
    agent any

    environment {
        INSTANCE_ID = ''  // To store instance ID
        AMI_ID = ''       // To store AMI ID
    }

    stages {
        stage('Clone Repository') {
            steps {
                // Clone the GitHub repository
                git url: 'https://github.com/surajakdev/AWS_Jenkins_Code_Deployment.git', branch: 'main'
            }
        }

        stage('Launch EC2 Instance') {
            steps {
                script {
                    echo "Launching EC2 instance..."
                    
                    // Launch a temporary EC2 instance to install the application
                    def launchInstanceCommand = '''
                    aws ec2 run-instances \
                        --image-id ami-0522ab6e1ddcc7055  // Choose an appropriate AMI, like Ubuntu
                        --instance-type t2.micro \
                        --key-name ec2_template_keypair \
                        --security-group-ids sg-0d8963d952ca46e07 \
                        --subnet-id subnet-cff1ffa7 \
                        --associate-public-ip-address \
                        --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Jenkins-Build-Instance}]' \
                        --query 'Instances[0].InstanceId' --output text
                    '''
                    
                    // Capture instance ID
                    INSTANCE_ID = sh(script: launchInstanceCommand, returnStdout: true).trim()
                    echo "EC2 Instance launched with ID: ${INSTANCE_ID}"

                    // Wait for instance to be running
                    sh "aws ec2 wait instance-running --instance-ids ${INSTANCE_ID}"
                }
            }
        }

        stage('Install Prerequisites') {
            steps {
                script {
                    echo "Installing prerequisites on EC2 instance..."

                    // Use AWS Systems Manager (SSM) to install prerequisites
                    def installPrerequisitesCommand = """
                    aws ssm send-command --instance-ids ${INSTANCE_ID} --document-name "AWS-RunShellScript" \
                    --parameters 'commands=["sudo apt-get update -y", "sudo apt-get install fortune-mod cowsay -y"]'
                    """
                    sh script: installPrerequisitesCommand

                    // Wait for SSM command to finish
                    sh "aws ssm wait command-executed --command-id ${sh(script: 'aws ssm list-commands --query \'Commands[0].CommandId\' --output text', returnStdout: true).trim()}"

                }
            }
        }

        stage('Deploy wisecow.sh Script') {
            steps {
                script {
                    echo "Deploying wisecow.sh onto EC2 instance..."
                    
                    // Use SCP to copy the wisecow.sh script to the EC2 instance
                    def publicDns = sh(script: "aws ec2 describe-instances --instance-id ${INSTANCE_ID} --query 'Reservations[0].Instances[0].PublicDnsName' --output text", returnStdout: true).trim()
                    sh "scp -o StrictHostKeyChecking=no -i /path/to/your-key.pem wisecow.sh ubuntu@${publicDns}:/home/ubuntu/wisecow.sh"

                    // Run the script on the instance
                    sh "ssh -o StrictHostKeyChecking=no -i /path/to/your-key.pem ubuntu@${publicDns} 'chmod +x /home/ubuntu/wisecow.sh && nohup /home/ubuntu/wisecow.sh &'"
                }
            }
        }

        stage('Create AMI') {
            steps {
                script {
                    echo "Creating AMI from EC2 instance..."

                    // Create the AMI from the running instance
                    def createAmiCommand = "aws ec2 create-image --instance-id ${INSTANCE_ID} --name 'wisecow-ami-${env.BUILD_NUMBER}' --no-reboot --output text --query 'ImageId'"
                    AMI_ID = sh(script: createAmiCommand, returnStdout: true).trim()
                    echo "Created AMI with ID: ${AMI_ID}"

                    // Tag the AMI
                    sh "aws ec2 create-tags --resources ${AMI_ID} --tags Key=Name,Value='Wisecow-Build-${env.BUILD_NUMBER}'"
                }
            }
        }

        stage('Terminate EC2 Instance') {
            steps {
                script {
                    echo "Terminating EC2 instance..."
                    sh "aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}"
                    sh "aws ec2 wait instance-terminated --instance-ids ${INSTANCE_ID}"
                }
            }
        }

        stage('Update Auto Scaling Group') {
            steps {
                script {
                    echo "Updating Auto Scaling Group with new AMI..."

                    // Update launch template with the new AMI ID
                    def updateLaunchTemplateCommand = """
                    aws ec2 create-launch-template-version --launch-template-id lt-0abcd1234efgh5678 \
                    --source-version 1 --launch-template-data '{"ImageId":"${AMI_ID}"}' \
                    --version-description "Build ${env.BUILD_NUMBER}"
                    """
                    sh script: updateLaunchTemplateCommand

                    // Set the newly created version as the default version
                    def modifyLaunchTemplateCommand = """
                    aws ec2 modify-launch-template --launch-template-id lt-0abcd1234efgh5678 --default-version 2
                    """
                    sh script: modifyLaunchTemplateCommand

                    // Optionally, trigger an instance refresh in ASG
                    def asgName = 'my-auto-scaling-group'
                    sh "aws autoscaling start-instance-refresh --auto-scaling-group-name ${asgName} --preferences MinHealthyPercentage=90"
                }
            }
        }
    }
}
