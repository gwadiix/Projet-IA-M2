pipeline {
    agent any

    environment {
        // CORRECTION ICI : On charge le couple User/Pass dans une variable 'CREDS'
        // Jenkins va créer automatiquement deux variables : 
        // 1. CREDS_USR (le nom d'utilisateur)
        // 2. CREDS_PSW (le mot de passe)
        CREDS = credentials('vsphere-user')
    }

    stages {
        stage('🔍 Vérification') {
            steps {
                sh 'terraform --version'
                sh 'packer --version'
                echo "Connexion Jenkins OK."
            }
        }

        stage('🏗️ Construction Image (Packer)') {
            steps {
                dir('packer_project') {
                    script {
                        if (env.BRANCH_NAME == 'dev') {
                            echo "Construction de l'image..."
                            // On injecte les variables _USR et _PSW
                            sh "packer build -var 'vsphere_user=${env.CREDS_USR}' -var 'vsphere_password=${env.CREDS_PSW}' ubuntu-ia.pkr.hcl"
                        } else {
                            echo "Pas de construction Packer sur la branche principale."
                        }
                    }
                }
            }
        }

        stage('🚀 Déploiement Infra (Terraform)') {
            steps {
                dir('terraform_project') {
                    script {
                        // On injecte les variables d'environnement pour Terraform
                        // Terraform cherche automatiquement les variables qui commencent par TF_VAR_
                        withEnv(["TF_VAR_vsphere_user=${env.CREDS_USR}", "TF_VAR_vsphere_password=${env.CREDS_PSW}"]) {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }
    }
}