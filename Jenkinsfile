pipeline {
    agent any

    environment {
        AWS_REGION = "us-west-2"
        ECR_REPO   = "655307635386.dkr.ecr.us-west-2.amazonaws.com/lesson-7-ecr"
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Export AWS creds') {
            steps {
                withEnv([
                    "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID}",
                    "AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY}"
                ]) {
                    echo "AWS credentials loaded"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh 'docker push $ECR_REPO:$IMAGE_TAG'
            }
        }

        stage('Git Tag') {
            steps {
                sh '''
                git config user.name "Jenkins"
                git config user.email "jenkins@example.com"
                git tag $IMAGE_TAG
                git push origin $IMAGE_TAG
                '''
            }
        }
    }
}

