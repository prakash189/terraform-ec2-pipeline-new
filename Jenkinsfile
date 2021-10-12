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

       git branch: 'main', url: 'https://github.com/prakash189/terraform-ec2-pipeline-new.git'

         }
       }

          stage('Terraform Init') {
            steps {
              sh "terraform init"
            }
          }
          stage('Terraform Plan') {
             steps {
               sh "terraform plan -out=tfplan -input=false"
             }
           }
          stage('Approval') {
            steps {
              script {
                def userInput = input(id: 'confirm', message: 'Apply Terraform?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terraform', name: 'confirm'] ])
        }
      }
    }

          //  stage('Terraform Apply') {
          //    steps {
          //        sh 'terraform apply --auto-approve -input=false tfplan'
          //      }
          //  }
          stage('Terraform Destroy') {
             steps {
                 sh 'terraform destroy --auto-approve -input=false'
               }
           }
  }
}

