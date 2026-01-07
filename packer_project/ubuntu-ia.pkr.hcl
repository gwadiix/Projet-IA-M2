packer {
  required_plugins {
    vsphere = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/vsphere"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# --- 1. VARIABLES D'ENTRÉE (Celles que Jenkins remplit) ---
variable "vsphere_server" {
  type    = string
  default = "172.16.21.151" 
}

# Jenkins envoie "-var vsphere_user=...", donc on doit l'appeler pareil ici
variable "vsphere_user" {
  type    = string
  default = "administrator@lab.local"
}

# Jenkins envoie "-var vsphere_password=...", donc on doit l'appeler pareil ici
variable "vsphere_password" {
  type      = string
  sensitive = true
  # Pas de default ici pour la sécurité, Jenkins DOIT le fournir
}

# --- VARIABLES ESXI ---
variable "esxi_host"      { default = "172.16.21.102" }
variable "datastore"      { default = "datastore1" }

# --- CONFIGURATION DE L'IMAGE ---
source "vsphere-iso" "ubuntu-ia" {
  # 1. ON SE CONNECTE AU VCENTER
  vcenter_server      = var.vsphere_server
  username            = var.vsphere_user      # <-- On utilise la variable de Jenkins
  password            = var.vsphere_password  # <-- On utilise la variable de Jenkins
  insecure_connection = true

  # 2. ON CIBLE L'ESXI SPECIFIQUE
  host                = var.esxi_host
  datastore           = var.datastore

  # Config VM
  vm_name              = "TEMPLATE-UBUNTU-IA"
  guest_os_type        = "ubuntu64Guest"
  CPUs                 = 4
  RAM                  = 4096
  disk_controller_type = ["pvscsi"]
  
  storage {
    disk_size             = 20480
    disk_thin_provisioned = true
  }

  network_adapters {
    network      = "VM Network"
    network_card = "vmxnet3"
  }

  # ISO (Ubuntu 22.04 LTS)
  iso_urls     = ["https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"]
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  # Méthode CD-ROM (cidata)
  cd_files = [
    "./http/user-data",
    "./http/meta-data"
  ]
  cd_label = "cidata" 

  # Commande de boot
  boot_wait = "10s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud", 
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
  ]
  
  # Connexion SSH pour Ansible
  ssh_username = "quentin"
  ssh_password = "password"
  ssh_private_key_file = "./packer_key"
  ssh_timeout  = "30m"
  
  convert_to_template = true
}

# --- L'EXÉCUTION ---
build {
  sources = ["source.vsphere-iso.ubuntu-ia"]

  # Etape 1 : Vérification
  provisioner "shell" {
    inline = ["echo 'Ubuntu installé ! Lancement de Ansible...'"]
  }

  # Etape 2 : Lancement Ansible
  provisioner "ansible" {
    playbook_file = "./ansible/deploy_ia_baremetal.yml"
    user          = "quentin"
    use_proxy     = false
    
    extra_arguments = [
      "--extra-vars", "ansible_become_pass=password"
    ]
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
  }
}