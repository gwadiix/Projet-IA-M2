pipeline {
    agent any

    environment {
        // Charge le couple User/Pass dans une variable 'CREDS'
        // Jenkins crée automatiquement CREDS_USR et CREDS_PSW
        CREDS = credentials('vsphere-user')
    }

    stages {
        stage('🔍 Vérification') {
            steps {
                sh 'terraform --version'
                sh 'packer --version'
                echo "Outils présents. Connexion Jenkins OK."
            }
        }

       stage('🏗️ Construction Image (Packer)') {
            steps {
                dir('packer_project') {
                    script {
                        // MODIFICATION ICI : On ajoute 'main' pour que ça marche aujourd'hui
                        if (env.BRANCH_NAME == 'dev' || env.BRANCH_NAME == 'main') {
                            echo "Construction de l'image en cours..."
                            sh "packer build -var 'vsphere_user=${env.CREDS_USR}' -var 'vsphere_password=${env.CREDS_PSW}' ubuntu-ia.pkr.hcl"
                        } else {
                            echo "Pas de construction Packer."
                        }
                    }
                }
            }
        }

        stage('🚀 Déploiement Infra (Terraform)') {
            steps {
                dir('terraform_project') {
                    script {
                        // Injection des variables pour Terraform (User, Pass, et IP Serveur)
                        withEnv([
                            "TF_VAR_vsphere_user=${env.CREDS_USR}",
                            "TF_VAR_vsphere_password=${env.CREDS_PSW}",
                            "TF_VAR_vsphere_server=172.16.21.102" 
                        ]) {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }
    } // Fin stages
} // Fin pipeline