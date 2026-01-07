pipeline {
    agent any

    environment {
        // Jenkins va chercher les identifiants que l'on va configurer juste après
        // "vsphere-user" est l'ID que l'on donnera dans Jenkins
        VSPHERE_USER = credentials('vsphere-user')
        VSPHERE_PASSWORD = credentials('vsphere-pass')
        
        // On injecte ces variables pour Terraform
        TF_VAR_vsphere_user = "${env.VSPHERE_USER_USR}"
        TF_VAR_vsphere_password = "${env.VSPHERE_USER_PSW}"
        // SI tu as séparé user/pass dans Jenkins, adapte les lignes ci-dessus.
        // Si tu as utilisé "Username with password", Jenkins crée automatiquement _USR et _PSW
    }

    stages {
        stage('🔍 Vérification') {
            steps {
                sh 'terraform --version'
                sh 'packer --version'
                echo "Tout est prêt sur la VM Jenkins !"
            }
        }

        stage('🏗️ Construction Image (Packer)') {
            steps {
                dir('packer_project') {
                    script {
                        // On lance Packer seulement si on est sur la branche DEV (pour gagner du temps en PROD)
                        if (env.BRANCH_NAME == 'dev') {
                            echo "Construction de la nouvelle image..."
                            // On passe les credentials à Packer aussi
                            sh "packer build -var 'vsphere_user=${env.VSPHERE_USER_USR}' -var 'vsphere_password=${env.VSPHERE_USER_PSW}' ubuntu-ia.pkr.hcl"
                        } else {
                            echo "Skipping Packer build on branch ${env.BRANCH_NAME}"
                        }
                    }
                }
            }
        }

        stage('🚀 Déploiement Infra (Terraform)') {
            steps {
                dir('terraform_project') {
                    script {
                        sh 'terraform init'
                        
                        // Déploiement
                        // Note : Assure-toi que ton main.tf utilise bien var.vsphere_user
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }
    }
}