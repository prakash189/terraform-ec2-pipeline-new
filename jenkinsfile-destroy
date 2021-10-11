#!groovy
pipeline {
  agent any
  environment {
    AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_KEY')

  }
  stages {
    stage('checkout') {
     steps {

       git branch: 'main', url: 'https://github.com/prakash189/terraform-ec2-pipeline.git'

         }
       }
           stage('Terraform Destroy') {
              steps {
                  sh 'terraform destroy --auto-approve -input=false'
                }
            }
  }
}

