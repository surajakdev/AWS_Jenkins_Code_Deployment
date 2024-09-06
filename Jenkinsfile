pipeline {
    agent any

    stages {
        stage('Clone Code') {
            steps {
                echo "Cloning the Code"
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'githubtoken', url: 'https://github.com/surajakdev/AWS_Jenkins_Code_Deployment.git']])
            }
        }
        
        stage("Build"){
            steps{
               echo "Building the image"
               sh "docker build -t sh_web_app ."
             
            }
        }
        stage("Push to Docker Hub"){
            steps{
               echo "Pushing the image to docker hub"
               withCredentials([usernamePassword(credentialsId:"dockerHub_ID", passwordVariable:"dockerHubPass", usernameVariable: "dockerHubUser")]){
                sh "docker tag sh_web_app ${env.dockerHubUser}/my-web-app:latest"   
               sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPass}"
               sh "docker push ${env.dockerHubUser}/my-web-app:latest"
               }
             
            }
        }
    }
}
