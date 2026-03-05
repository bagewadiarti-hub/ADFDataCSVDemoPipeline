pipeline {

    agent any

    tools {
        terraform 'terraform'
    }

    parameters {
        choice(name: 'ENV', choices: ['dev','prod'], description: 'Select environment')
    }

    stages {

        // 1️⃣ Azure Login
        stage('Azure Login') {
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

        // 2️⃣ Terraform Format
        stage('Terraform Format Check') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform fmt -recursive'
                }
            }
        }

        // 3️⃣ Terraform Init
        stage('Terraform Init') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform init -upgrade -input=false -backend-config=resource_group_name=tf-rg-' + params.ENV +
                        ' -backend-config=storage_account_name=tfstoragedemo177' + params.ENV +
                        ' -backend-config=container_name=tfstate -backend-config=key=adf-' + params.ENV + '.tfstate'
                }
            }
        }

        // 4️⃣ Terraform Validate
        stage('Terraform Validate') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform validate'
                }
            }
        }

        // 5️⃣ Terraform Plan
        stage('Terraform Plan') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform plan -input=false -out=tfplan'
                }
            }
        }

        // 6️⃣ Manual Approval for PROD
        stage('Manual Approval') {
            when {
                expression { params.ENV == 'prod' }
            }
            steps {
                input message: 'Approve deployment to PROD?', ok: 'Deploy'
            }
        }

        // 7️⃣ Terraform Apply
        stage('Terraform Apply') {
            steps {
                dir("env/${params.ENV}") {
                    bat 'terraform apply -auto-approve tfplan'
                }
            }
        }

        // 8️⃣ Fetch Terraform Outputs
        stage('Fetch Terraform Outputs') {
            steps {
                dir("env/${params.ENV}") {
                    script {

                        env.RG_NAME = bat(script: '@terraform output -raw resource_group', returnStdout: true).trim()
                        env.ADF_NAME = bat(script: '@terraform output -raw data_factory_name', returnStdout: true).trim()
                        env.STORAGE_ACCOUNT = bat(script: '@terraform output -raw storage_account_name', returnStdout: true).trim()
                        env.INPUT_CONTAINER = bat(script: '@terraform output -raw input_container_name', returnStdout: true).trim()
                        env.OUTPUT_CONTAINER = bat(script: '@terraform output -raw output_container_name', returnStdout: true).trim()

                        echo "Terraform outputs fetched successfully"
                        echo "Resource Group: ${env.RG_NAME}"
                        echo "ADF: ${env.ADF_NAME}"
                        echo "Storage: ${env.STORAGE_ACCOUNT}"
                    }
                }
            }
        }

        // 9️⃣ Deploy ADF Linked Service and Datasets
        stage('Deploy ADF Dependencies') {
            steps {
                dir("env/${params.ENV}") {
                    script {

                        def rg = env.RG_NAME
                        def adf = env.ADF_NAME

                        bat 'az datafactory linked-service create --resource-group ' + rg +
                            ' --factory-name ' + adf +
                            ' --name ls_blobstorage --properties @../../LinkedService.json'

                        bat 'az datafactory dataset create --resource-group ' + rg +
                            ' --factory-name ' + adf +
                            ' --name ds_inputcsv --properties @../../DatasetInput.json'

                        bat 'az datafactory dataset create --resource-group ' + rg +
                            ' --factory-name ' + adf +
                            ' --name ds_outputcsv --properties @../../DatasetOutput.json'

                        echo "ADF Linked Service and Datasets deployed successfully"
                    }
                }
            }
        }

        // 🔟 Deploy ADF Pipeline
        stage('Deploy DemoPipeline to ADF') {
            steps {
                dir("env/${params.ENV}") {
                    script {

                        def rg = env.RG_NAME
                        def adf = env.ADF_NAME

                        bat 'az datafactory pipeline create --resource-group ' + rg +
                            ' --factory-name ' + adf +
                            ' --name DemoPipeline --pipeline @../../DemoPipeline.json'

                        echo "ADF pipeline deployed successfully"
                    }
                }
            }
        }

        // 11️⃣ Trigger ADF Pipeline
        stage('Trigger ADF Demo Pipeline') {
    steps {
        script {

            def rg = env.RG_NAME
            def adf = env.ADF_NAME

            bat 'az datafactory pipeline create-run --resource-group ' + rg +
                ' --factory-name ' + adf +
                ' --name DemoPipeline --parameters inputPath=demo-source.csv outputPath=demo-output.csv'

            echo "ADF pipeline triggered successfully"
        }
    }
}

        // 12️⃣ Verify Output
        stage('Verify Output') {
            steps {
                echo "Check Blob Storage container '${env.OUTPUT_CONTAINER}' for demo-output.csv"
            }
        }

    }

    post {

        success {
            echo "Deployment successful for ${params.ENV}"
        }

        failure {
            echo "Pipeline failed. Check Jenkins logs."
        }

    }
}

