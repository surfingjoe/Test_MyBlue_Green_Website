import hudson.tasks.test.AbstractTestResultAction

pipeline{
    agent {label 'build_slave1'}
    tools {
        terraform 'Terraform'
    }

    parameters {
        // string(name: 'environment', defaultValue: 'terraform', description: 'Workspace/environment file to use for deployment')
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')

    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    }


    stages{
        stage('Git Checkout'){
           steps{
               git branch: 'master', credentialsId: 'Github', url: 'https://github.com/surfingjoe/Test_MyBlue_Green_Website'
           }
        }
        stage('Terraform Init'){
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
            steps{
                sh label: '', script: 'terraform init -reconfigure'
                // sh 'terraform workspace select ${environment} || terraform workspace new ${environment}'

                sh "terraform plan -input=false -out tfplan "
                sh 'terraform show -no-color tfplan > tfplan.txt'
            }
        }
        stage('Approval') {
           when {
               not {
                   equals expected: true, actual: params.autoApprove
               }
               not {
                    equals expected: true, actual: params.destroy
                }
           }

            steps {
               script {
                    def plan = readFile 'tfplan.txt'
                    input message: "Do you want to apply the plan?",
                    parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
               }
           }
        }
         stage('Apply') {
            when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }

            steps {
                sh "terraform apply  -input=false tfplan"
                slackSend color: 'good', message: 'Test Environment - Blue/Green Website successfully deployed'
            }
        }

        stage('Destroy') {
            when {
                equals expected: true, actual: params.destroy
            }

        steps {
            sh 'terraform init -input=false'
            sh "terraform destroy  --auto-approve"
            slackSend color: 'good', message: 'Test Environment = ßBlue/Green Website successfully destroyed'
        }
    }

  }
  post{
    failure {
        slackSend color: 'danger', message: "*Build failed*  - Job ${env.JOB_NAME} Build # ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
        }
    aborted {
        slackSend color: "#FFC300", message: "*ABORTED:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} by ${env.USER}\n More info at: (<${env.BUILD_URL}|Open>)"
        }
    }
}
