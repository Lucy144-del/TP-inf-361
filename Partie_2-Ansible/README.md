# Partie 2 : Automatisation avec Ansible

**Objectif** : Reproduire les fonctionnalités du script Bash à l'aide d'un playbook Ansible professionnel, avec ajout de l'envoi automatique d'emails.

## Table des matières
1. [Structure des fichiers](#structure-des-fichiers)
2. [Prérequis et installation](#prérequis-et-installation)
3. [Configuration](#configuration)
4. [Exécution](#exécution)
5. [Fonctionnalités détaillées](#fonctionnalités-détaillées)
6. [Tests et validation](#tests-et-validation)
7. [Dépannage](#dépannage)
8. [Sécurité](#sécurité)
9. [FAQ](#faq)

## Structure des fichiers

Partie_2-Ansible/
├── README.md # Ce fichier
├── create_users.yml # Playbook principal
├── send_email.yml # Playbook d'envoi d'emails
├── inventory.ini # Inventaire des serveurs
├── users_data.yaml # Données des utilisateurs
├── templates/ # Templates Jinja2
│ └── welcome.j2 # Template du message de bienvenue
├── requirements.txt # Dépendances Python (optionnel)
└── group_vars/ # Variables par groupe (optionnel)
└── all.yml # Variables globales
text


## Prérequis et installation

### 1. Installation d'Ansible

**Sur Ubuntu/Debian :**
```bash
sudo apt update
sudo apt install ansible -y

Sur CentOS/RHEL :
bash

sudo yum install epel-release -y
sudo yum install ansible -y

Via pip (toutes distributions) :
bash

pip3 install ansible

2. Vérification de l'installation
bash

ansible --version
# Doit afficher : ansible [core 2.14.x]

ansible all -i inventory.ini -m ping
# Doit retourner "pong" pour chaque serveur

3. Configuration SSH
bash

# Générer une paire de clés SSH (si pas déjà fait)
ssh-keygen -t rsa -b 4096

# Copier la clé publique sur le serveur
ssh-copy-id root@vps.monserveur.com

. Configuration
1. Modifier l'inventaire (inventory.ini)
ini

[linux_servers]
vps.monserveur.com ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

[linux_servers:vars]
ansible_python_interpreter=/usr/bin/python3

Options disponibles :

    ansible_user : Utilisateur SSH (root ou sudo)

    ansible_ssh_private_key_file : Chemin de la clé privée

    ansible_port : Port SSH (si différent de 22)

    ansible_become : true pour utiliser sudo automatiquement

2. Configurer les utilisateurs (users_data.yaml)
yaml

users:
  - username: "alice"
    password: "Pass123!"
    full_name: "Alice Dupont"
    phone: "+33612345678"
    email: "alice@email.com"
    preferred_shell: "/bin/bash"

group_name: "students-inf-361"
disk_quota_gb: 15
memory_percent_limit: 20
ssh_port: 22

3. Configurer l'envoi d'emails (send_email.yml)

Modifiez les variables SMTP :
yaml

smtp_host: "smtp.gmail.com"
smtp_port: 587
smtp_username: "votre.email@gmail.com"
smtp_password: "votre_mot_de_passe_app"  # Mot de passe d'application

Pour Gmail : Activez l'authentification à 2 facteurs et créez un mot de passe d'application.
Exécution
1. Test de connexion
bash

ansible all -i inventory.ini -m ping

2. Exécution complète
bash

# Exécuter le playbook principal
ansible-playbook -i inventory.ini create_users.yml

# Activer l'envoi d'emails
ansible-playbook -i inventory.ini create_users.yml -e "email_notifications=true"

3. Exécution avec tags
bash

# Créer seulement les utilisateurs
ansible-playbook -i inventory.ini create_users.yml --tags "users"

# Configuration sécurité seulement
ansible-playbook -i inventory.ini create_users.yml --tags "security,pam"

# Tout sauf les emails
ansible-playbook -i inventory.ini create_users.yml --skip-tags "email"

# Voir tous les tags disponibles
ansible-playbook -i inventory.ini create_users.yml --list-tags

4. Options d'exécution avancées
bash

# Mode verbose (débogage)
ansible-playbook -i inventory.ini create_users.yml -v
ansible-playbook -i inventory.ini create_users.yml -vvv  # Très détaillé

# Mode check (simulation)
ansible-playbook -i inventory.ini create_users.yml --check

# Limiter à un hôte spécifique
ansible-playbook -i inventory.ini create_users.yml --limit vps.monserveur.com

# Définir des variables en ligne de commande
ansible-playbook -i inventory.ini create_users.yml -e "group_name=students-test"

.  Fonctionnalités détaillées
1. Gestion des utilisateurs

    Création : Utilise le module ansible.builtin.user

    Modification : Idempotent (peut être réexécuté)

    Shells : Installation automatique si manquant

    Groupes : Ajout à students-inf-361 et sudo

2. Sécurité

    Mots de passe : Hashés en SHA-512 avec openssl passwd -6

    Changement forcé : chage -d 0 pour première connexion

    Restriction su : Configuration PAM pour interdire su au groupe

    Quotas : Limite de 15 Go via setquota

    Mémoire : Limite à 20% RAM via systemd slices

3. Personnalisation

    Message de bienvenue : Template Jinja2 personnalisable

    .bashrc : Configuration automatique à chaque connexion

    Informations GECOS : Téléphone et email stockés via chfn

4. Journalisation

    Fichier log : /var/log/ansible_user_creation.log

    Timestamps : Date/heure pour chaque action

    Suivi : Une ligne par utilisateur créé/modifié

5. Envoi d'emails (nouveau)

    Contenu : Instructions de connexion détaillées

    Multi-OS : Commandes pour Linux, Mac et Windows

    HTML : Email formaté professionnellement

    Sécurité : Utilisation de STARTTLS

.  Tests et validation
1. Tests unitaires
bash

# Vérification syntaxique YAML
yamllint create_users.yml users_data.yaml

# Vérification du playbook
ansible-playbook -i inventory.ini create_users.yml --syntax-check

# Linting Ansible
ansible-lint create_users.yml

2. Tests d'intégration
bash

# Vérifier la création des utilisateurs
ansible all -i inventory.ini -m shell -a "id {{ item }}" --loop "['alice', 'bob']"

# Vérifier les groupes
ansible all -i inventory.ini -m shell -a "groups alice"

# Vérifier les quotas
ansible all -i inventory.ini -m shell -a "quota -u alice"

# Vérifier les logs
ansible all -i inventory.ini -m shell -a "tail -20 /var/log/ansible_user_creation.log"

3. Tests manuels
bash

# Se connecter en tant qu'utilisateur
ssh alice@vps.monserveur.com
# Doit :
# 1. Afficher le message de bienvenue
# 2. Demander le changement de mot de passe
# 3. Refuser la commande 'su'

# Tester sudo
sudo whoami  # Doit retourner "root"

# Tester su
su bob  # Doit échouer avec message d'authentification

.  Dépannage
Problèmes courants
1. "Authentication failed"
bash

# Solution 1 : Vérifier la clé SSH
ssh -i ~/.ssh/id_rsa root@vps.monserveur.com

# Solution 2 : Utiliser mot de passe
ansible all -i inventory.ini -m ping -k

# Solution 3 : Vérifier les permissions de la clé
chmod 600 ~/.ssh/id_rsa

2. "Python not found"
ini

# Dans inventory.ini, ajouter :
ansible_python_interpreter=/usr/bin/python3

3. "Module 'apt' not found"
yaml

# Remplacer dans create_users.yml :
# De :
- ansible.builtin.apt:
# À (pour RHEL/CentOS) :
- ansible.builtin.yum:

4. Échec d'envoi d'emails
bash

# 1. Vérifier les paramètres SMTP
# 2. Tester avec debug :
ansible-playbook -i inventory.ini send_email.yml -vvv

# 3. Tester manuellement :
python3 -c "
import smtplib
server = smtplib.SMTP('smtp.gmail.com', 587)
server.starttls()
server.login('votre.email@gmail.com', 'mot_de_passe')
print('Connexion SMTP réussie')
server.quit()
"

5. Quotas non appliqués
bash

# Vérifier que les quotas sont activés
ansible all -i inventory.ini -m shell -a "mount | grep quota"

# Activer les quotas si nécessaire
ansible all -i inventory.ini -m shell -a "quotacheck -cug /home && quotaon /home"

.  Sécurité
Bonnes pratiques implémentées

    Mots de passe :

        Hashés avec SHA-512

        Changement forcé à première connexion

        Masqués dans les logs (no_log: true)

    Accès :

        Pas de connexion root directe (si SSH configuré)

        Restriction de la commande su

        Quotas pour éviter l'abus de ressources

    Emails :

        Pas de mots de passe en clair dans la configuration

        Utilisation de STARTTLS

        Mot de passe d'application pour Gmail

Améliorations possibles

    Ansible Vault pour chiffrer les mots de passe :
    bash

ansible-vault encrypt_string 'Pass123!' --name 'password'

    Roles Ansible pour une meilleure modularité

    Tests automatisés avec Molecule

.  FAQ
Q1 : Puis-je utiliser ce playbook sur plusieurs serveurs ?

R : Oui, ajoutez simplement les serveurs dans inventory.ini :
ini

[linux_servers]
server1.example.com
server2.example.com
server3.example.com

Q2 : Comment ajouter un nouvel utilisateur après la création initiale ?

R : Ajoutez-le dans users_data.yaml et réexécutez le playbook. Il est idempotent.
Q3 : Puis-je désactiver certaines fonctionnalités ?

R : Oui, avec les tags :
bash

# Sans quotas
ansible-playbook -i inventory.ini create_users.yml --skip-tags "quota"

# Sans limites mémoire
ansible-playbook -i inventory.ini create_users.yml --skip-tags "memory"

Q4 : Comment sauvegarder la configuration actuelle ?

R : Utilisez les facts Ansible :
bash

ansible all -i inventory.ini -m setup --tree /tmp/ansible-facts

Q5 : Puis-je migrer depuis le script Bash ?

R : Oui, exportez les utilisateurs existants :
bash

# Générer un users_data.yaml depuis /etc/passwd
awk -F: '{print $1 ": " $5}' /etc/passwd > users_export.yaml
