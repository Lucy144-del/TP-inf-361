# main.tf
# Configuration principale des ressources Terraform

# 1. Création d'une clé SSH (optionnelle - si on veux que Terraform la génère)
# resource "tls_private_key" "vps_key" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
# 
# resource "local_file" "private_key" {
#   content  = tls_private_key.vps_key.private_key_pem
#   filename = "${path.module}/ssh_keys/vps_key.pem"
#   file_permission = "0600"
# }

# 2. Récupération des clés SSH existantes sur DigitalOcean
data "digitalocean_ssh_keys" "existing_keys" {
  # Récupère toutes les clés SSH déjà uploadées sur ton compte DigitalOcean
  # Cette data source est en lecture seule
}

# 3. Création du droplet (VPS)
resource "digitalocean_droplet" "vps" {
  # Identification
  name     = local.droplet_unique_name  # Nom unique avec timestamp
  region   = var.region                 # Région (ex: fra1, nyc3)
  size     = var.droplet_size           # Taille (ex: s-1vcpu-1gb)
  image    = var.image                  # OS (ex: ubuntu-22-04-x64)
  
  # Clés SSH : utilise les clés spécifiées OU toutes les clés existantes
  ssh_keys = length(var.ssh_keys) > 0 ? var.ssh_keys : data.digitalocean_ssh_keys.existing_keys.ssh_keys[*].id
  
  # Configuration réseau
  ipv6     = true       # Activer IPv6
  monitoring = true     # Activer le monitoring
  
  # Tags pour l'organisation
  tags = ["inf-361", "university", "vps"]
  
  # 4. CONNEXION SSH pour le provisionning
  connection {
    type        = "ssh"           # Type de connexion
    host        = self.ipv4_address  # IP publique du droplet
    user        = "root"          # Utilisateur root
    private_key = file("~/.ssh/id_rsa")  # Clé privée locale
    timeout     = "2m"            # Timeout de connexion
  }
  
  # 5. PROVISIONER 1 : Copier le fichier users.txt
  provisioner "file" {
    source      = var.users_file_path  # Local
    destination = local.remote_users_file  # Remote
    
    # Cette connexion hérite de la connexion principale
  }
  
  # 6. PROVISIONER 2 : Copier le script Bash
  provisioner "file" {
    source      = var.script_path      # Script local
    destination = local.remote_script_path  # Sur le VPS
    
    # S'assurer que le script est exécutable
    connection {
      type        = "ssh"
      host        = self.ipv4_address
      user        = "root"
      private_key = file("~/.ssh/id_rsa")
    }
  }
  
  # 7. PROVISIONER 3 : Exécuter le script
  provisioner "remote-exec" {
    # Commande à exécuter sur le VPS
    inline = [
      # Étape 1 : Rendre le script exécutable
      "chmod +x ${local.remote_script_path}",
      
      # Étape 2 : Vérifier que le fichier users.txt existe
      "if [ ! -f ${local.remote_users_file} ]; then",
      "  echo 'ERREUR: Fichier users.txt non trouvé'",
      "  exit 1",
      "fi",
      
      # Étape 3 : Exécuter le script
      local.execution_command,
      
      # Étape 4 : Nettoyer les fichiers temporaires (optionnel)
      "rm -f ${local.remote_script_path} ${local.remote_users_file}",
      
      # Étape 5 : Message de succès
      "echo 'Script exécuté avec succès. Les utilisateurs ont été créés.'"
    ]
    
    # En cas d'erreur, continuer quand même (ne pas détruire le VPS)
    on_failure = continue
  }
  
  # 8. Lifecycle : contrôle du cycle de vie de la ressource
  lifecycle {
    # Empêche la destruction accidentelle du VPS
    prevent_destroy = false  # Mettre à true en production
    
    # Ignorer les changements d'IP (peut changer au redémarrage)
    ignore_changes = [tags]
  }
}

# 9. Pare-feu (optionnel - sécurisation avancée)
resource "digitalocean_firewall" "vps_firewall" {
  name = "${digitalocean_droplet.vps.name}-firewall"
  
  # Liste des droplets à protéger
  droplet_ids = [digitalocean_droplet.vps.id]
  
  # Règles entrantes (inbound)
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"      # SSH
    source_addresses = ["0.0.0.0/0", "::/0"]  # À restreindre en production!
  }
  
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"      # HTTP
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"     # HTTPS
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Règles sortantes (outbound - tout autoriser)
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  
  # Dépend du droplet (créer le firewall après le droplet)
  depends_on = [digitalocean_droplet.vps]
}
