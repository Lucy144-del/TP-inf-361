# providers.tf
# Configuration des providers Terraform

# Bloc Terraform : configuration générale
terraform {
  # Version minimale de Terraform requise
  required_version = ">= 1.0.0"
  
  # Configuration des providers requis
  required_providers {
    # Provider DigitalOcean pour créer des VPS
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"  # Version 2.x
    }
    
    # Provider local pour gérer des fichiers locaux
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    
    # Provider null pour exécuter des commandes
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Configuration du provider DigitalOcean
provider "digitalocean" {
  # Le token API est lu depuis la variable DO_TOKEN
  # Cette variable doit être définie dans l'environnement :
  # export DO_TOKEN="votre_token_digitalocean"
  token = var.do_token
  
  # Région par défaut (peut être surchargée)
  # spaces_region = "fra1"  # Pour les buckets S3-like
}