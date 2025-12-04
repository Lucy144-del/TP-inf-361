# variables.tf
# Définition des variables Terraform

# 1. Variables REQUISES (sans valeur par défaut)

variable "do_token" {
  description = "Token d'API DigitalOcean"
  type        = string
  sensitive   = true  # Masque la valeur dans les outputs
}

# 2. Variables OPTIONNELLES (avec valeurs par défaut)

variable "droplet_name" {
  description = "Nom du droplet (VPS) à créer"
  type        = string
  default     = "vps-inf-361"
}

variable "region" {
  description = "Région DigitalOcean où créer le VPS"
  type        = string
  default     = "fra1"  # Francfort
}

variable "droplet_size" {
  description = "Taille du droplet (CPU, RAM)"
  type        = string
  default     = "s-1vcpu-1gb"  # 1 vCPU, 1 Go RAM
  
  # Validation : s'assurer que la taille est valide
  validation {
    condition     = can(regex("^s-.*", var.droplet_size))
    error_message = "La taille du droplet doit commencer par 's-' (standard)."
  }
}

variable "image" {
  description = "Image système à installer"
  type        = string
  default     = "ubuntu-22-04-x64"  # Ubuntu 22.04 LTS
}

variable "ssh_keys" {
  description = "Liste des noms des clés SSH à ajouter au droplet"
  type        = list(string)
  default     = []  # Liste vide par défaut
}

variable "users_file_path" {
  description = "Chemin local vers le fichier users.txt"
  type        = string
  default     = "../Partie_1-Script_Bash/users.txt"
}

variable "script_path" {
  description = "Chemin local vers le script create_users.sh"
  type        = string
  default     = "../Partie_1-Script_Bash/create_users.sh"
}

variable "group_name" {
  description = "Nom du groupe pour les utilisateurs"
  type        = string
  default     = "students-inf-361"
}

# 3. Variables LOCALES (calculées)

locals {
  # Timestamp pour rendre les noms uniques
  timestamp = formatdate("YYYYMMDD-hhmmss", timestamp())
  
  # Nom unique du droplet
  droplet_unique_name = "${var.droplet_name}-${local.timestamp}"
  
  # Chemin distant pour le script
  remote_script_path = "/tmp/create_users.sh"
  
  # Chemin distant pour le fichier users.txt
  remote_users_file = "/tmp/users.txt"
  
  # Commande d'exécution complète
  execution_command = "sudo bash ${local.remote_script_path} ${var.group_name}"
}
