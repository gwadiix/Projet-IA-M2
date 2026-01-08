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
                        echo "⚠️ Force Build : Construction de l'image en cours..."
                        
                        // 1. Initialisation
                        sh 'packer init ubuntu-ia.pkr.hcl'

                        // 2. CORRECTION : On sécurise la clé SSH (Obligatoire pour Ansible)
                        sh 'chmod 600 packer_key'

                        // 3. Construction
                        sh 'packer build -force -var "vsphere_user=$CREDS_USR" -var "vsphere_password=$CREDS_PSW" ubuntu-ia.pkr.hcl'
                    }
                }
            }
        }

        stage('🚀 Déploiement Infra (Terraform)') {
            steps {
                dir('terraform_project') {
                    script {
                        // Injection des variables pour Terraform
                        withEnv([
                            "TF_VAR_vsphere_user=${env.CREDS_USR}",
                            "TF_VAR_vsphere_password=${env.CREDS_PSW}",
                            // On vise le vCenter (.151)
                            "TF_VAR_vsphere_server=172.16.21.151" 
                        ]) {
                            sh 'terraform init'
                            sh 'terraform apply -auto-approve'
                        }
                    }
                }
            }
        }
    } // Fin des stages

// ✅ AJOUTE CE BLOC ICI :
    post {
        always {
            script {
                echo "📢 Envoi du rapport à Jira..."
                // On utilise ton code KAN-1
                jiraComment body: "🚀 Build Jenkins terminé avec succès !\n\n🌍 L'IA est disponible ici : http://172.16.21.200:8501\n🛠️ Build n°${env.BUILD_NUMBER}", issueKey: 'KAN-1'
            }
        }
    }

} // Fin pipeline