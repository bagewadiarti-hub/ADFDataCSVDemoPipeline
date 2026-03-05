pipeline {
    agent any

    tools { terraform 'terraform' }

    parameters {
        choice(name: 'ENV', choices: ['dev','prod'], description: 'Select environment to deploy')
    }

    stages {

        // Azure Login
        stage('Azure Login (Bootstrap)') {
            steps {
                withCredentials([
                    string(credentialsId: 'azure-client-id', variable: 'SP_CLIENT_ID'),
                    string(credentialsId: 'azure-client-secret', variable: 'SP_CLIENT_SECRET'),
                    string(credentialsId: 'azure-tenant-id', variable: 'SP_TENANT_ID')
                ]) {
                    bat 'az login --service-principal --username %SP_CLIENT_ID% --password %SP_CLIENT_SECRET% --tenant %SP_TENANT_ID%'
                }
            }
        }

        // Fetch Secrets from Key Vault
        stage('Fetch Secrets from Key Vault') {
            steps {
                script {
                    env.ARM_SUBSCRIPTION_ID = bat(script: 'az keyvault secret show --vault-name ADFDemoKeyVault177 --name azure-subscription-id --query value -o tsv', returnStdout: true).trim()
                    env.STORAGE_CONN_STRING = bat(script: 'az keyvault secret show --vault-name ADFDemoKeyVault177 --name demo-storage-conn --query value -o tsv', returnStdout: true).trim()
                }
            }
        }

        // Terraform stages
        stage('Terraform Format Check') {
            steps { dir("env/${params.ENV}") { bat 'terraform fmt -check -recursive' } }
        }

        stage('Terraform Init') {
            steps {
                dir("env/${params.ENV}") {
                    bat "terraform init -upgrade -input=false -backend-config=resource_group_name=tf-rg-${params.ENV} -backend-config=storage_account_name=tfstoragedemo177${params.ENV} -backend-config=container_name=tfstate -backend-config=key=adf-${params.ENV}.tfstate"
                }
            }
        }

        stage('Terraform Validate') {
            steps { dir("env/${params.ENV}") { bat 'terraform validate' } }
        }

        stage('Terraform Plan') {
            steps { dir("env/${params.ENV}") { bat 'terraform plan -input=false -out=tfplan' } }
        }

        stage('Manual Approval') {
            when { expression { params.ENV == 'prod' } }
            steps { input message: "Approve deployment to PROD?", ok: "Deploy" }
        }

        stage('Terraform Apply') {
            steps { dir("env/${params.ENV}") { bat 'terraform apply -auto-approve tfplan' } }
        }

        // Deploy ADF Pipeline
        stage('Deploy DemoPipeline to ADF') {
            steps {
                script {
                    def RG_NAME = "tf-rg-${params.ENV}"
                    def ADF_NAME = "adfdemo177${params.ENV}"
                    bat "az datafactory pipeline create --resource-group ${RG_NAME} --factory-name ${ADF_NAME} --name DemoPipeline --file DemoPipeline.json"
                    echo "DemoPipeline deployed to ADF: ${ADF_NAME}"
                }
            }
        }

        // Trigger ADF Pipeline
        stage('Trigger ADF Demo Pipeline') {
            steps {
                script {
                    def RG_NAME = "tf-rg-${params.ENV}"
                    def ADF_NAME = "adfdemo177${params.ENV}"
                    bat "az datafactory pipeline create-run --resource-group ${RG_NAME} --factory-name ${ADF_NAME} --name DemoPipeline --parameters inputPath=demo-source.csv outputPath=demo-output.csv"
                    echo "ADF DemoPipeline triggered successfully for ${params.ENV}!"
                }
            }
        }

        // Verify Output
        stage('Verify Output') {
            steps {
                echo "Check Azure Blob Storage 'output' container for 'demo-output.csv'. It should include uppercase NAME_UPPER column."
            }
        }

    }

    post {
        success { echo "End-to-end demo pipeline executed successfully for ${params.ENV}!" }
        failure { echo "Pipeline failed. Check Jenkins logs for details." }
    }
}
