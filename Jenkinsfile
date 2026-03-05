pipeline {
    agent any

    tools { terraform 'terraform' }

    parameters {
        choice(name: 'ENV', choices: ['dev','prod'], description: 'Select environment to deploy')
    }

    stages {

        // 1️⃣ Azure Login
        stage('Azure Login (Bootstrap)') {
            steps {
                withCredentials([
                    string(credentialsId: 'azure-client-id', variable: 'SP_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'SP_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'SP_TENANT_ID')
                ]) {
                    bat "az login --service-principal --username %SP_CLIENT_ID% --password %SP_CLIENT_SECRET% --tenant %SP_TENANT_ID%"
                }
            }
        }

        // 2️⃣ Terraform Format Check
        stage('Terraform Format Check') {
            steps { dir("env/${params.ENV}") { bat 'terraform fmt -check -recursive' } }
        }

        // 3️⃣ Terraform Init
        stage('Terraform Init') {
            steps {
                dir("env/${params.ENV}") {
                    bat "terraform init -upgrade -input=false -backend-config=resource_group_name=tf-rg-${params.ENV} -backend-config=storage_account_name=tfstoragedemo177${params.ENV} -backend-config=container_name=tfstate -backend-config=key=adf-${params.ENV}.tfstate"
                }
            }
        }

        // 4️⃣ Terraform Validate
        stage('Terraform Validate') {
            steps { dir("env/${params.ENV}") { bat 'terraform validate' } }
        }

        // 5️⃣ Terraform Plan
        stage('Terraform Plan') {
            steps { dir("env/${params.ENV}") { bat 'terraform plan -input=false -out=tfplan' } }
        }

        // 6️⃣ Manual Approval (for PROD)
        stage('Manual Approval') {
            when { expression { params.ENV == 'prod' } }
            steps { input message: "Approve deployment to PROD?", ok: "Deploy" }
        }

        // 7️⃣ Terraform Apply
        stage('Terraform Apply') {
            steps { dir("env/${params.ENV}") { bat 'terraform apply -auto-approve tfplan' } }
        }

        // 8️⃣ Fetch Terraform Outputs (fully dynamic)
        stage('Fetch Terraform Outputs') {
            steps {
                dir("env/${params.ENV}") {
                    script {
                        env.RG_NAME            = bat(script: 'terraform output -raw resource_group', returnStdout: true).trim()
                        env.ADF_NAME           = bat(script: 'terraform output -raw data_factory_name', returnStdout: true).trim()
                        env.STORAGE_ACCOUNT    = bat(script: 'terraform output -raw storage_account_name', returnStdout: true).trim()
                        env.INPUT_CONTAINER    = bat(script: 'terraform output -raw input_container_name', returnStdout: true).trim()
                        env.OUTPUT_CONTAINER   = bat(script: 'terraform output -raw output_container_name', returnStdout: true).trim()
                        env.STORAGE_CONN_STRING = bat(script: 'terraform output -raw storage_connection_string', returnStdout: true).trim()
                        echo "Terraform outputs fetched successfully!"
                        echo "RG=${env.RG_NAME}, ADF=${env.ADF_NAME}, Storage=${env.STORAGE_ACCOUNT}"
                    }
                }
            }
        }

        // 9️⃣ Deploy DemoPipeline to ADF
        stage('Deploy DemoPipeline to ADF') {
            steps {
                script {
                    bat "az datafactory pipeline create --resource-group ${env.RG_NAME} --factory-name ${env.ADF_NAME} --name DemoPipeline --file DemoPipeline.json"
                    echo "DemoPipeline deployed to ADF: ${env.ADF_NAME}"
                }
            }
        }

        // 🔟 Trigger ADF Demo Pipeline
        stage('Trigger ADF Demo Pipeline') {
            steps {
                script {
                    bat "az datafactory pipeline create-run --resource-group ${env.RG_NAME} --factory-name ${env.ADF_NAME} --name DemoPipeline --parameters inputPath=demo-source.csv outputPath=demo-output.csv"
                    echo "ADF DemoPipeline triggered successfully for ${params.ENV}!"
                }
            }
        }

        // 11️⃣ Verify Output
        stage('Verify Output') {
            steps {
                echo "Check Azure Blob Storage '${env.OUTPUT_CONTAINER}' container for 'demo-output.csv'. It should include uppercase NAME_UPPER column."
            }
        }

    }

    post {
        success { echo "End-to-end demo pipeline executed successfully for ${params.ENV}!" }
        failure { echo "Pipeline failed. Check Jenkins logs for details." }
    }
}
