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

# --- VARIABLES VCENTER (LE CHEF) ---
variable "vcenter_server" { default = "172.16.21.151" }
variable "vcenter_user"   { default = "administrator@lab.local" }
variable "vcenter_pass"   { default = "Vmware@2025!" }

# --- VARIABLES ESXI (L'OUVRIER) ---
variable "esxi_host"      { default = "172.16.21.102" }
variable "datastore"      { default = "datastore1" }

# --- CONFIGURATION DE L'IMAGE ---
source "vsphere-iso" "ubuntu-ia" {
  # 1. ON SE CONNECTE AU VCENTER
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_user
  password            = var.vcenter_pass
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

  # ISO (Ubuntu 22.04 LTS - Lien Stable)
  iso_urls     = ["https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso"]
  iso_checksum = "sha256:9bc6028870aef3f74f4e16b900008179e78b130e6b0b9a140635434a46aa98b0"

  # --- 🔴 CHANGEMENT MAJEUR ICI 🔴 ---
  
  # 1. On supprime "http_directory"
  # 2. On ajoute la méthode CD-ROM (cidata)
  cd_files = [
    "./http/user-data",
    "./http/meta-data"
  ]
  cd_label = "cidata" 

  # 3. Nouvelle commande de boot (Plus de HTTP IP !)
  boot_wait = "10s"
  boot_command = [
    "c",
    "linux /casper/vmlinuz --- autoinstall ds=nocloud", # On lui dit de chercher le CD 'nocloud'
    "<enter><wait>",
    "initrd /casper/initrd",
    "<enter><wait>",
    "boot<enter>"
  ]
  # Connexion SSH pour Ansible (Doit correspondre au fichier user-data)
  ssh_username = "quentin"
  ssh_password = "password"
  # On pointe vers le fichier de clé PRIVE (celui sans extension)
  ssh_private_key_file = "./packer_key"
  ssh_timeout  = "30m"
  
  # Conversion en Template à la fin
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
    
    # On force le mot de passe sudo
    extra_arguments = [
      "--extra-vars", "ansible_become_pass=password"
    ]
    # On désactive la vérification de clé SSH pour éviter les blocages
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False"
    ]
  }
}