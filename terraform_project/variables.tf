variable "vsphere_user" {
  type        = string
  description = "Compte utilisateur vSphere"
}

variable "vsphere_password" {
  type        = string
  description = "Mot de passe vSphere"
  sensitive   = true
}

variable "vsphere_server" {
  type        = string
  description = "Adresse IP du vCenter ou ESXi"
}