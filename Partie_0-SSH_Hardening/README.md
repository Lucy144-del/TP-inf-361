# Partie 0 : Durcissement de la configuration SSH

**Objectif** : Sécuriser le service SSH, point d'entrée principal du serveur, avant toute automatisation.

## 1. Procédure correcte de modification de la configuration SSH

Modifier la configuration du serveur SSH (`sshd`) requiert une méthodologie stricte pour éviter de se bloquer l'accès au serveur.

### Étapes à suivre :

1.  **Connexion avec privilèges** :
    Se connecter au serveur et obtenir les droits d'administration (via `sudo` ou en tant que `root`).

2.  **Sauvegarde impérative** :
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    *Cette commande crée une copie de sauvegarde du fichier de configuration actuel, datée pour plus de clarté.*

3.  **Édition du fichier de configuration** :
    sudo nano /etc/ssh/sshd_config
    
    *Modifier le fichier principal (`/etc/ssh/sshd_config`) avec l'éditeur de texte de votre choix.*

4.  **Validation de la syntaxe (CRITIQUE)** :
    sudo sshd -t

    *Cette commande teste la syntaxe du fichier de configuration. **Aucun message** signifie succès. Toute erreur affichée doit être corrigée avant de passer à l'étape suivante.*

5.  **Application des changements** :
    sudo systemctl restart ssh

    *Redémarre le service SSH pour prendre en compte les nouvelles configurations. **Conserver la session SSH actuelle ouverte.**

6.  **Test dans une nouvelle session** :
    Ouvrir un **nouveau terminal** et tenter de se reconnecter au serveur avec les nouveaux paramètres (ex: nouveau port, nouvelle méthode d'authentification).

7.  **Vérification et rollback si nécessaire** :
    - **Si la nouvelle connexion réussit** : La configuration est valide. La session de test peut être fermée.
    - **Si la nouvelle connexion échoue** : Utiliser la **session initiale restée ouverte** pour restaurer la sauvegarde et redémarrer le service :
      sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
      sudo systemctl restart ssh

## 2. Principal risque en cas de non-respect de la procédure

### Risque : **Verrouillage externe (Lock-out) du serveur**

Si la procédure n'est pas suivie — notamment en omettant la validation syntaxique (`sshd -t`) ou en fermant la session de travail avant de tester une nouvelle connexion — l'administrateur risque de **se retrouver définitivement exclu de son propre serveur**.

**Scénario catastrophe** :
1. Modification et redémarrage du service SSH avec une configuration erronée (ex: `Port` incorrect, `PasswordAuthentication no` sans avoir configuré de clé SSH).
2. Fermeture de la session SSH active.
3. Toute tentative de reconnexion échoue car le service SSH rejette la connexion selon les nouvelles règles (invalides ou trop restrictives).
4. **Impossible de se reconnecter pour corriger l'erreur**. L'accès au serveur est perdu sans intervention manuelle directe (console fournie par l'hébergeur) ou réinstallation complète.

**Conclusion** : La procédure est une **ceinture de sécurité**. La session maintenue ouverte et la sauvegarde sont vos **airbags** en cas d'accident de configuration.

## 3. Cinq paramètres de sécurité essentiels pour le serveur SSH

Voici cinq paramètres de configuration critiques pour renforcer la sécurité de SSH. Chaque modification doit être appliquée en suivant la procédure décrite ci-dessus.

### 1. **`PermitRootLogin no`**
**Justification** : Interdit la connexion SSH directe au compte superutilisateur `root`. Cette mesure oblige les utilisateurs à se connecter avec un compte standard et à utiliser `sudo` pour les opérations administratives. Elle réduit considérablement la surface d'attaque, car le compte `root` est la cible privilégiée des attaques par force brute. Elle améliore également la traçabilité, car les actions privilégiées sont journalisées avec l'identité de l'utilisateur standard.

### 2. **`PasswordAuthentication no`** (à configurer **après** `PubkeyAuthentication yes`)
**Justification** : Désactive l'authentification par mot de passe, souvent vulnérable aux attaques par force brute, à l'ingénierie sociale ou aux mots de passe faibles. Elle doit être couplée à l'activation de l'authentification par clés publiques (`PubkeyAuthentication yes`), une méthode beaucoup plus robuste. Une clé cryptographique est extrêmement difficile à deviner ou à reproduire, offrant un niveau de sécurité bien supérieur.

### 3. **`Port 2222`** (ou un autre port > 1024)
**Justification** : Change le port d'écoute par défaut de SSH (22) vers un port non standard. Cela permet d'éviter la grande majorité des scans automatisés et des attaques opportunistes qui ciblent systématiquement le port 22. **Attention** : Ce changement doit être accompagné d'une mise à jour des règles du pare-feu (ex: `ufw` ou `firewalld`) pour autoriser le trafic sur ce nouveau port.

### 4. **`AllowUsers utilisateur1 utilisateur2`** (ou `AllowGroups`)
**Justification** : Définit une **liste blanche** explicite des utilisateurs autorisés à se connecter via SSH. Même si un compte existe sur le système (compte de service, compte invité), il n'aura pas la permission d'accéder au serveur à distance. Ce principe du **moindre privilège** limite strictement l'accès aux seules personnes nécessitant une connexion SSH, réduisant ainsi les risques en cas de compromission d'un autre compte.

### 5. **`MaxAuthTries 3`**
**Justification** : Limite le nombre maximal de tentatives d'authentification autorisées par session de connexion. Une valeur basse (3 ou 4) rend les attaques par **force brute** totalement inefficaces, car l'attaquant est déconnecté après seulement quelques essais infructueux. Cela oblige à des reconnexions manuelles fréquentes, ralentissant considérablement toute tentative automatisée.