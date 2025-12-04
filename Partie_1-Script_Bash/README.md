# Partie 1 : Automatisation avec Script Bash

**Objectif** : Créer un script Bash (`create_users.sh`) qui automatise la création, configuration et sécurisation des comptes utilisateurs à partir d'un fichier texte.

## Structure des fichiers

Partie_1-Script_Bash/
├── README.md # Ce fichier
├── create_users.sh # Script principal d'automatisation
├── users.txt # Fichier d'entrée (exemple)
└── creation_journal_*.log # Fichiers de logs générés automatiquement
text


## Fonctionnalités implémentées

Le script `create_users.sh` réalise les opérations suivantes pour chaque utilisateur listé dans `users.txt` :

| N° | Fonctionnalité                                                   | Commande/Technique utilisée        |
|----|------------------------------------------------------------------|------------------------------------|
| 1  | **Création du groupe** `students-inf-361`                        | `groupadd`, passage en paramètre   |
| 2  | **Création de l'utilisateur** avec nom complet, téléphone, email | `useradd`, `chfn`                  |
| 3  | **Vérification/installation du shell** préféré                   | `command -v`, `apt-get install`    |
| 4  | **Ajout au groupe** `students-inf-361`                           | `usermod -aG`                      |
| 5  | **Configuration du mot de passe** (hashé SHA-512)                | `openssl passwd -6`, `chpasswd -e` |
| 6  | **Forcer le changement de mot de passe** à la première connexion | `chage -d 0`                       |
| 7  | **Ajout au groupe `sudo`** avec restriction de la commande `su`  | `usermod -aG`, configuration PAM   |
| 8  | **Message de bienvenue** personnalisé à chaque connexion         | `WELCOME.txt` + `.bashrc`          |
| 9  | **Quota disque** (limite à 15 Go)                                | `setquota`                         |
| 10 | **Limite mémoire** (20% de la RAM max)                           | Slice systemd                      |
| 11 | **Journalisation complète** des opérations                       | Fonction `log_message`, `tee`      |

## Format du fichier `users.txt`

Le fichier d'entrée doit suivre ce format, avec un point-virgule (`;`) comme séparateur :

username;password;full_name;phone;email;preferred_shell
text


**Exemple :**
```txt
alice;Pass123!;Alice Dupont;+33612345678;alice@email.com;/bin/bash
bob;Secure456@;Bob Martin;+33787654321;bob@mail.fr;/bin/zsh
# Les lignes commentées (avec #) sont ignorées
charlie;Test789!;Charlie Brown;+33611223344;charlie@domain.com;/bin/fish

Installation et exécution
Prérequis

    Système Linux

    Privilèges root (ou sudo)

    Connexion Internet pour installer les shells manquants

    Paquets recommandés : quota, openssl

Étapes

    Télécharger les fichiers :
    bash

git clone [url-du-repo]
cd Partie_1-Script_Bash

Rendre le script exécutable :
bash

chmod +x create_users.sh

Créer/éditer le fichier users.txt avec vos utilisateurs.

Exécuter le script (en root) :
bash

sudo ./create_users.sh students-inf-361

Remarque : students-inf-361 est le nom du groupe passé en paramètre.

Vérifier l'exécution :
bash

# Voir les logs
tail -f creation_journal_*.log

# Vérifier la création des utilisateurs
grep -E "alice|bob" /etc/passwd

# Vérifier l'appartenance aux groupes
groups alice

Détails techniques des fonctionnalités avancées
1. Restriction de la commande su

Le script configure PAM (/etc/pam.d/su) pour refuser l'usage de su aux membres du groupe students-inf-361 :
bash

auth required pam_deny.so group=students-inf-361

2. Quotas disque

    Utilise setquota pour limiter à 15 Go (15728640 blocs de 1K)

    Important : Le système de fichiers doit être monté avec l'option usrquota

    Vérifiez avec mount | grep quota et installez le paquet quota si nécessaire

3. Limites mémoire via systemd

    Crée une slice systemd personnalisée (user-<username>.slice.d/limits.conf)

    Limite la mémoire à 20% de la RAM totale

    Visualisable avec : systemctl status user-<username>.slice

4. Journalisation

Chaque action est enregistrée avec timestamp dans creation_journal_AAAAAMMJJ_HHMMSS.log :
text

[2025-01-16 14:30:45] Traitement de l'utilisateur : alice
[2025-01-16 14:30:46] Shell '/bin/zsh' non trouvé. Tentative d'installation...
[2025-01-16 14:30:48] Shell installé avec succès.

Tests recommandés
Test de base
bash

# Créer un fichier users.txt minimal
echo "testuser;Test123!;Test User;+33000000000;test@test.com;/bin/bash" > users.txt

# Exécuter le script
sudo ./create_users.sh students-inf-361

# Vérifier la création
su - testuser  # Mot de passe: Test123!
# Doit afficher le message de bienvenue et demander un changement de mot de passe

Test des fonctionnalités avancées
bash

# Vérifier les quotas
sudo quota testuser

# Vérifier les limites mémoire
sudo systemctl cat user-testuser.slice

# Tester la restriction 'su'
sudo su - testuser  # Doit fonctionner (sudo)
su testuser         # Doit échouer (su restreint)

Test de robustesse
bash

# Lancer le script deux fois (utilisateurs existants)
sudo ./create_users.sh students-inf-361
# Doit afficher "L'utilisateur ... existe déjà. Modification..."

Limitations et prérequis système
Fonctionnalité	Prérequis	Notes
Quotas disque	Partition montée avec usrquota, paquet quota installé	Sinon, un avertissement est journalisé
Limites mémoire	Systemd actif	Alternative : cgroups manuels
Installation shells	Connexion Internet, dépôts configurés	Échoue silencieusement vers /bin/bash
Restriction su	PAM configuré standard	Testé sur Ubuntu/Debian
Dépannage
Problème : "setquota: command not found"
bash

sudo apt-get install quota

Problème : "Failed to create slice"

Vérifiez que systemd est actif :
bash

systemctl --version

Problème : Les quotas ne s'appliquent pas

Vérifiez le montage avec quotas :
bash

# Ajouter usrquota à /etc/fstab pour /home
sudo mount -o remount,usrquota /home

Problème : Script échoue silencieusement

Consultez les logs :
bash

cat creation_journal_*.log | tail -50

Références

    Manuel useradd

    Configuration PAM

    Quotas disque Linux

    Systemd Resource Control
