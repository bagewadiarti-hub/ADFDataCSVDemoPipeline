pipeline {
    agent any

    tools { terraform 'terraform' }

    parameters {
        choice(name: 'ENV', choices: ['dev','prod'], description: 'Select environment to deploy')
    }

    stages {

        stage('Azure Login') {
            steps {
                withCredentials([
                    string(credentialsId: 'azure-client-id', variable: 'SP_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'SP_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'SP_TENANT_ID')
                ]) {
                    // Use raw command, no quotes
                    bat 'az login --service-principal --username %SP_CLIENT_ID% --password %SP_CLIENT_SECRET% --tenant %SP_TENANT_ID%'
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform fmt -recursive'
                }
            }
        }

stage('Terraform Init') {
    steps {
        dir("env/${params.ENV}") {
            // Single bat command, use + for variable interpolation
            bat 'terraform init -upgrade -input=false -backend-config=resource_group_name=tf-rg-' + params.ENV +
                ' -backend-config=storage_account_name=tfstoragedemo177' + params.ENV +
                ' -backend-config=container_name=tfstate' +
                ' -backend-config=key=adf-' + params.ENV + '.tfstate'
        }
    }
}
        
        stage('Terraform Validate') {
            steps {
                dir("env/${params.ENV}") { bat 'terraform validate' }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("env/${params.ENV}") { bat 'terraform plan -input=false -out=tfplan' }
            }
        }

        stage('Manual Approval') {
            when { expression { params.ENV == 'prod' } }
            steps { input message: "Approve deployment to PROD?", ok: "Deploy" }
        }

        stage('Terraform Apply') {
            steps { dir("env/${params.ENV}") { bat 'terraform apply -auto-approve tfplan' } }
        }

        stage('Fetch Terraform Outputs') {
            steps {
                dir("env/${params.ENV}") {
                    script {
                        env.RG_NAME = bat(script: 'terraform output -raw resource_group', returnStdout: true).trim()
                        env.ADF_NAME = bat(script: 'terraform output -raw data_factory_name', returnStdout: true).trim()
                        env.STORAGE_ACCOUNT = bat(script: 'terraform output -raw storage_account_name', returnStdout: true).trim()
                        env.INPUT_CONTAINER = bat(script: 'terraform output -raw input_container_name', returnStdout: true).trim()
                        env.OUTPUT_CONTAINER = bat(script: 'terraform output -raw output_container_name', returnStdout: true).trim()
                        env.STORAGE_CONN_STRING = bat(script: 'terraform output -raw storage_connection_string', returnStdout: true).trim()
                        echo "Terraform outputs fetched successfully!"
                    }
                }
            }
        }

        stage('Deploy DemoPipeline to ADF') {
            steps {
                script {
                    // Construct full path with forward slashes to avoid Windows quoting issues
                    def pipelinePath = "${env.WORKSPACE}\\DemoPipeline.json"
                    // Use raw bat without extra quotes
                    bat 'az datafactory pipeline create --resource-group ' + env.RG_NAME +
                        ' --factory-name ' + env.ADF_NAME +
                        ' --name DemoPipeline --pipeline @' + pipelinePath
                    echo "DemoPipeline deployed to ADF: ${env.ADF_NAME}"
                }
            }
        }

        stage('Trigger ADF Demo Pipeline') {
            steps {
                script {
                    bat 'az datafactory pipeline run create --resource-group ' + env.RG_NAME +
                        ' --factory-name ' + env.ADF_NAME +
                        ' --pipeline-name DemoPipeline --parameters inputPath=demo-source.csv outputPath=demo-output.csv'
                    echo "ADF DemoPipeline triggered successfully for ${params.ENV}!"
                }
            }
        }

        stage('Verify Output') {
            steps {
                echo "Check Azure Blob Storage '${env.OUTPUT_CONTAINER}' for 'demo-output.csv'."
            }
        }
    }

    post {
        success { echo "Pipeline executed successfully for ${params.ENV}!" }
        failure { echo "Pipeline failed. Check logs." }
    }
}
