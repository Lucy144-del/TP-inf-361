# outputs.tf
# Définition des outputs Terraform (affichés après apply)

output "vps_ip_address" {
  description = "Adresse IPv4 publique du VPS"
  value       = digitalocean_droplet.vps.ipv4_address
  # Cette output est sensible dans un environnement réel
  sensitive   = false  # Mettre à true en production
}

output "vps_ipv6_address" {
  description = "Adresse IPv6 du VPS"
  value       = digitalocean_droplet.vps.ipv6_address
}

output "vps_status" {
  description = "Statut du VPS"
  value       = digitalocean_droplet.vps.status
}

output "vps_created_at" {
  description = "Date et heure de création du VPS"
  value       = digitalocean_droplet.vps.created_at
}

output "vps_disk_size" {
  description = "Taille du disque du VPS (en Go)"
  value       = digitalocean_droplet.vps.disk
}

output "vps_price_monthly" {
  description = "Prix mensuel du VPS (en $)"
  value       = digitalocean_droplet.vps.price_monthly
}

output "ssh_connection_command" {
  description = "Commande SSH pour se connecter au VPS"
  value       = "ssh root@${digitalocean_droplet.vps.ipv4_address}"
}

output "users_creation_status" {
  description = "Message de statut de la création des utilisateurs"
  value       = "Les utilisateurs ont été créés via le script Bash. Vérifiez avec: ssh root@${digitalocean_droplet.vps.ipv4_address} 'tail -f /var/log/user_creation.log'"
}

# output "private_key" {
#   description = "Clé privée générée (si utilisation de tls_private_key)"
#   value       = tls_private_key.vps_key.private_key_pem
#   sensitive   = true
# }