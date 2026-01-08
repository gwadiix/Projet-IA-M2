terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "2.6.1"
    }
  }
}

# --- 1. CONNEXION ---
provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

# --- 2. RÉCUPÉRATION DES INFOS ---
data "vsphere_datacenter" "dc" {
  name = "DC"
}

data "vsphere_host" "host" {
  name          = "172.16.21.102"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "TEMPLATE-UBUNTU-IA"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# --- 3. DÉPLOIEMENT OPTIMISÉ IA ---

resource "vsphere_virtual_machine" "vm_ia" {
  name             = "IA-OLLAMA-PROD-02"
  
  # Placement sur l'hôte
  resource_pool_id = data.vsphere_host.host.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id

  # ---------------------------------------------------------
  # 🚀 MODIFICATIONS DE PERFORMANCE (OVERRIDE)
  # ---------------------------------------------------------
  # Au lieu de copier le template, on force la puissance pour l'IA
  num_cpus = 4               # On force 4 vCPU (Indispensable pour Ollama)
  memory   = 8192            # On force 8 Go de RAM (8192 Mo)
  
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    # 💾 On force 60 Go pour stocker les 4 modèles IA
    size             = 60
    thin_provisioned = true # Important : Ne prend pas 60Go réels tout de suite sur ton PC
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "ia-ollama-prod"
        domain    = "lab.local"
      }

      network_interface {
        ipv4_address = "172.16.21.200"
        ipv4_netmask = 24
      }
      
      ipv4_gateway = "172.16.21.254"
    }
  }
}

output "ip_ia" {
  value = vsphere_virtual_machine.vm_ia.default_ip_address
}