# Partie 3 : Infrastructure as Code avec Terraform

Objectif du TP : Automatiser la création d'un VPS Linux dans le Cloud et l'exécution du script de création d'utilisateurs (create_users.sh) en une seule commande.

## Conformité au TP INF 3611
- Creation automatisée d'un VPS Linux (DigitalOcean)
- Execution automatique du script create_users.sh sur le VPS
- Transmission des fichiers users.txt et create_users.sh
- Provisioning via SSH avec vérifications
- Intégration complète avec la Partie 1 (Script Bash)

## Prérequis
1. Compte DigitalOcean avec token API (accès en écriture)
2. Clé SSH générée et uploadée sur DigitalOcean
3. Terraform installé localement (terraform version)

## Démarrage rapide

```bash
# 1. Copiez le fichier de configuration
cp terraform.tfvars.example terraform.tfvars

# 2. Éditez terraform.tfvars avec votre token DigitalOcean
nano terraform.tfvars  # Remplacer: do_token = "votre_token_ici"

# 3. Initialisez Terraform
terraform init

# 4. Vérifiez le plan d'exécution
terraform plan

# 5. Déployez l'infrastructure (VPS + exécution du script)
terraform apply  # Tapez 'yes' pour confirmer

Structure des fichiers
text

Partie_3-Terraform/
├── main.tf           # Configuration principale : VPS + provisioning
├── variables.tf      # Définition des 10 variables
├── outputs.tf        # 7 sorties informatives après création
├── providers.tf      # Configuration des providers Terraform
├── terraform.tfvars  # Vos variables sensibles (NE PAS COMMITTER)
├── terraform.tfvars.example  # Modèle de configuration
└── README.md         # Ce fichier

Configuration minimale

Dans terraform.tfvars :
hcl

do_token = "dop_v1_votre_token_digitalocean"  # SECRET - jamais dans Git
droplet_name = "vps-inf-361"
region = "fra1"  # Francfort (faible latence)

Vérification après déploiement
bash

# 1. Connectez-vous au VPS créé
ssh root@$(terraform output -raw vps_ip_address)

# 2. Vérifiez la création des utilisateurs
tail -f /var/log/user_creation.log
getent group students-inf-361

# 3. Testez les fonctionnalités du TP
# - Quotas disque (15 Go max) : quota -s
# - Message de bienvenue : reconnectez-vous via SSH
# - Changement de mot de passe forcé : su - alice

Nettoyage (IMPORTANT)

Pour éviter les frais sur DigitalOcean :
bash

terraform destroy  # Détruit complètement le VPS
# Confirmez avec 'yes'

Commandes Terraform utiles
Commande	Description
terraform init	Initialise le projet, télécharge les providers
terraform plan	Affiche les changements à appliquer (simulation)
terraform apply	Crée le VPS et exécute le script
terraform destroy	Détruit toutes les ressources
terraform output	Affiche l'IP du VPS et autres informations
terraform fmt	Formate les fichiers .tf
terraform validate	Valide la syntaxe
Notes importantes

    Sécurité : Ne committez jamais terraform.tfvars dans Git (il contient votre token)

    Coûts : Le VPS coûte ~5$/mois. Détruisez-le avec terraform destroy après le TP

    Dépendances : Assurez-vous que ../Partie_1-Script_Bash/create_users.sh existe et fonctionne

Dépannage rapide

    Token invalide : Regénérez-le dans DigitalOcean -> API -> Tokens

    Échec SSH : Vérifiez que votre clé SSH est uploadée sur DigitalOcean

    Script introuvable : Vérifiez les chemins dans variables.tf
