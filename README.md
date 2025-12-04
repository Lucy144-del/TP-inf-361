# TP INF 3611 - Administration Systèmes et Réseaux

**Université de Yaoundé I - Faculté des Sciences - Département d'Informatique** 
**Licence 3 Informatique - Décembre 2025**

## Description
Automatisation complète de la création d'utilisateurs Linux sur un VPS Cloud via trois technologies : Bash, Ansible et Terraform.

## Structure du projet

TP-INF-361/
├── Partie_0-SSH_Hardening/ # Documentation durcissement SSH
├── Partie_1-Script_Bash/ # Script Bash d'automatisation
├── Partie_2-Ansible/ # Playbook avec envoi d'emails
├── Partie_3-Terraform/ # Infrastructure as Code
└── README.md # Ce fichier


## Objectifs atteints
- Automatisation création utilisateurs avec quotas et restrictions
- Durcissement de la sécurité SSH
- Industrialisation avec Ansible et envoi d'emails
- Déploiement automatisé avec Terraform sur DigitalOcean
- Documentation complète et code commenté

## Démarrage rapide

```bash
# 1. Clonez le dépôt
git clone https://github.com/votre-username/TP-INF-361.git
cd TP-INF-361

# 2. Testez chaque partie
cd Partie_1-Script_Bash && bash create_users.sh --test
cd Partie_2-Ansible && ansible-playbook create_users.yml --syntax-check
cd Partie_3-Terraform && terraform init && terraform plan

. Livrables

Chaque partie contient :

    Code source commenté

    Fichiers de configuration

    README.md avec instructions spécifiques

    Exemples de fichiers de données

. Sécurité

    Tokens API et mots de passe exclus via .gitignore

    Authentification par clés SSH recommandée

    Configuration SSH durcie selon bonnes pratiques
